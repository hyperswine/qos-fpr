{-# LANGUAGE LambdaCase #-}

-- A64: rv64 emission -> AArch64 (ELF/gas syntax).
--
-- The PoC of the "shared low-level RISC IR" idea: Codegen.hs's rv64
-- output IS the IR.  It only ever uses a ~20-mnemonic, 8-register,
-- flags-free, direct-control-flow subset of RISC-V (no jalr, no CSRs
-- outside --rvv, frames always 16-aligned), and that subset maps 1:1
-- onto AArch64 under a register assignment that happens to agree with
-- AAPCS64 exactly where the RISC-V ABI agrees with it:
--
--   a0..a7 -> x0..x7      (args/results: identical in both ABIs)
--   t0 t1 t2 t6 -> x9 x10 x11 x12   (caller-saved temps)
--   s0 -> x29 (fp)        s1..s9 -> x19..x27 (callee-saved)
--   ra -> x30  sp -> sp  zero -> xzr
--   tp -> (no free per-thread register on hosted AArch64: tpidr_el0
--          belongs to libc TLS)  `mv RD, tp` therefore lowers to a
--          local-exec TLS load of fpr_posix_hart (__thread: one per
--          hart pthread), which runtime/posix maintains where bare
--          metal maintains tp.  This is the one
--          place the translation knows it is targeting the posix HAL.
--
-- Because both ABIs agree on x0..x7/caller-saved/callee-saved for the
-- registers we use, translated FPRISC code calls the C runtime (and is
-- called back through fpr_apply's casts) with no shims at all.
--
-- Flags: RISC-V has none, so nothing in the IR is live across a `cmp`;
-- lowering branches/slt/seqz/snez through NZCV is always safe.
-- x16/x17 (IP0/IP1) are scratch strictly within one lowered
-- instruction, which is exactly their AAPCS role.
--
-- macOS/Mach-O IS the promised syntax layer over this same pass
-- (lowerA64 True): same instructions, four differences --
--
--   * adrp/:lo12: becomes adrp _sym@PAGE / add _sym@PAGEOFF, and every
--     C-visible symbol (definitions, .globl, call/la/.quad references)
--     grows the leading underscore; .L local labels become L (the
--     Mach-O assembler-private prefix)
--   * .section .rodata becomes __TEXT,__const
--   * big immediates are movz/movk chains on BOTH syntaxes now (the
--     ldr =imm literal pool + .ltorg pseudo was ELF-gas-only; the chain
--     is portable and the ELF suite regression-tests the encoding)
--   * `mv rd, tp` cannot be a local-exec :tprel: load -- Darwin TLS is
--     TLV descriptors.  The lowering emits the standard Darwin
--     sequence (adrp/ldr the descriptor, blr through its thunk), which
--     the dyld contract makes safe mid-function: _tlv_get_addr
--     preserves every register except x0, x16, x17.  x0 (arg0, live at
--     the function-entry fuel tick) and x30 (ra, live everywhere) are
--     saved around it; x17 stashes the loaded hart pointer across the
--     restore.  The C side's __thread cell uses the same TLV machinery,
--     so both sides agree by construction.
module A64 (lowerA64, a64Rev) where


import Data.Bits (shiftR, (.&.))
import Data.Char (isDigit, isSpace)
import Data.List (isPrefixOf, stripPrefix)
import Data.Word (Word64)

-- bump when the lowering changes (unit-cache tag component; see X64.hs)
a64Rev :: Int
a64Rev = 4

lowerA64 :: Bool -> String -> String
lowerA64 mach =
  post . unlines . concatMap (lowerLine mach) . map banner . lines
  where
    banner "# target: rv64"
      | mach = "# target: a64mac (lowered from the rv64 emission; Mach-O syntax)"
      | otherwise = "# target: a64 (lowered from the rv64 emission -- the shared RISC IR)"
    banner l = l
    -- .L -> L: Mach-O's assembler-private label prefix.  Safe as a text
    -- pass: the emission holds no quoted strings (string data is .byte
    -- lists), so ".L" occurs only as a label prefix (and in comments,
    -- where the rename is harmless).
    post = if mach then replaceAll ".L" "L" else id

replaceAll :: String -> String -> String -> String
replaceAll from to = go
  where
    go s = case breakOn s of
      Nothing -> s
      Just (pre, rest) -> pre ++ to ++ go rest
    breakOn s = bo "" s
    bo _ [] = Nothing
    bo acc r@(c : cs)
      | from `isPrefixOf` r = Just (reverse acc, drop (length from) r)
      | otherwise = bo (c : acc) cs

-- ---- registers -------------------------------------------------------

xreg :: String -> String
xreg = \case
  "zero" -> "xzr"
  "ra" -> "x30"
  "sp" -> "sp"
  "s0" -> "x29"
  "t0" -> "x9"; "t1" -> "x10"; "t2" -> "x11"; "t6" -> "x12"
  'a' : d | [c] <- d, isDigit c -> 'x' : d
  's' : d | Just n <- num d, n >= 1, n <= 9 -> "x" ++ show (18 + n)
  r -> error ("A64: unmapped register " ++ r)
  where num d = if all isDigit d && not (null d) then Just (read d :: Int) else Nothing

wreg :: String -> String
wreg r = case xreg r of
  "xzr" -> "wzr"
  'x' : n -> 'w' : n
  other -> error ("A64: no w-form for " ++ other)

-- ---- line dispatch ---------------------------------------------------

lowerLine :: Bool -> String -> [String]
lowerLine mach l
  | null (dropWhile isSpace l) = [l]
  | "#" `isPrefixOf` dropWhile isSpace l = [l] -- comments pass through
  | Just body <- stripPrefix "    " l, not (isDirective body) = map ind (instr mach body)
  | mach = [macLine l] -- labels, directives, .quad data: Mach-O spellings
  | otherwise = [l] -- labels, directives, .byte data: identical on a64
  where
    ind s = "    " ++ s
    isDirective ('.' : _) = True
    isDirective _ = False

-- the underscore a C-visible symbol grows on Mach-O (.L locals exempt;
-- the post pass renames those to the L private prefix)
gsym :: Bool -> String -> String
gsym mach s
  | mach, not (".L" `isPrefixOf` s) = '_' : s
  | otherwise = s

-- non-instruction lines under Mach-O: label definitions and the three
-- symbol-bearing directives; everything else passes through
macLine :: String -> String
macLine l
  | Just rest <- stripPrefix "    .globl " l =
      "    .globl " ++ mapSyms rest
  | Just rest <- stripPrefix "    .quad " l,
    (c : _) <- dropWhile isSpace rest,
    not (isDigit c),
    c /= '-' =
      "    .quad " ++ gsym True (trim rest)
  | "    .section .rodata" `isPrefixOf` l = "    .section __TEXT,__const"
  | (name, ':' : rest) <- break (== ':') l,
    not (null name),
    all (not . isSpace) name,
    not ("." `isPrefixOf` name) || ".L" `isPrefixOf` name =
      gsym True name ++ ":" ++ rest
  | otherwise = l
  where
    trim = dropWhile isSpace . reverse . dropWhile isSpace . reverse
    mapSyms = intercalate1 ", " . map (gsym True . trim) . splitC
    splitC t = case break (== ',') t of
      (x, []) -> [x]
      (x, _ : r) -> x : splitC r
    intercalate1 sep = foldr1 (\x acc -> x ++ sep ++ acc)

-- split "op a, b, c" -> (op, [a,b,c]); memory operands "N(reg)" kept whole
parts :: String -> (String, [String])
parts s = case words s of
  (op : rest) -> (op, splitOps (unwords rest))
  [] -> ("", [])
  where
    splitOps "" = []
    splitOps t = map trim (splitOn ',' t)
    splitOn c t = case break (== c) t of
      (a, []) -> [a]
      (a, _ : b) -> a : splitOn c b
    trim = dropWhile isSpace . reverse . dropWhile isSpace . reverse

mem :: String -> (Integer, String) -- "N(reg)" -> (offset, base)
mem s = case break (== '(') s of
  (o, '(' : r) -> (readInt (if null o then "0" else o), xreg (takeWhile (/= ')') r))
  _ -> error ("A64: bad mem operand " ++ s)

readInt :: String -> Integer
readInt ('-' : d) = negate (read d)
readInt d = read d

-- ---- loads/stores ----------------------------------------------------
-- 64-bit: ldr/str (scaled, off in [0,32760] step 8) or ldur/stur
-- ([-256,255]); otherwise materialize base+off in x16.
-- 32-bit: lw sign-extends on RISC-V, so ldrsw; sw -> str wN.

ldst64 :: String -> String -> String -> String -> [String]
ldst64 opU opS rm rd = withOff rm 8 opS opU rd

ld32 :: String -> String -> [String] -- lw rd, off(rb): sign-extending
ld32 rd rm =
  let (off, rb) = mem rm; xd = xreg rd
   in if off >= -256 && off <= 255
        then ["ldursw " ++ xd ++ ", [" ++ rb ++ ", #" ++ show off ++ "]"]
        else if off >= 0 && off `mod` 4 == 0 && off <= 16380
          then ["ldrsw " ++ xd ++ ", [" ++ rb ++ ", #" ++ show off ++ "]"]
          else farBase rb off ++ ["ldrsw " ++ xd ++ ", [x16]"]

st32 :: String -> String -> [String]
st32 rs rm =
  let (off, rb) = mem rm; ws = wreg rs
   in if off >= -256 && off <= 255
        then ["stur " ++ ws ++ ", [" ++ rb ++ ", #" ++ show off ++ "]"]
        else if off >= 0 && off `mod` 4 == 0 && off <= 16380
          then ["str " ++ ws ++ ", [" ++ rb ++ ", #" ++ show off ++ "]"]
          else farBase rb off ++ ["str " ++ ws ++ ", [x16]"]

withOff :: String -> Integer -> String -> String -> (String -> [String])
withOff rm step opScaled opUnscaled = \rd ->
  let (off, rb) = mem rm; xd = xreg rd
   in if off >= -256 && off <= 255
        then [opUnscaled ++ " " ++ xd ++ ", [" ++ rb ++ ", #" ++ show off ++ "]"]
        else if off >= 0 && off `mod` step == 0 && off <= 4095 * step
          then [opScaled ++ " " ++ xd ++ ", [" ++ rb ++ ", #" ++ show off ++ "]"]
          else farBase rb off ++ [opScaled ++ " " ++ xd ++ ", [x16]"]

farBase :: String -> Integer -> [String]
farBase rb off = movImm "x16" off ++ ["add x16, " ++ rb ++ ", x16"]

-- ---- immediates ------------------------------------------------------

movImm :: String -> Integer -> [String]
movImm xd n
  | n >= -65535 && n <= 65535 = ["mov " ++ xd ++ ", #" ++ show n] -- movz/movn territory
  | otherwise = -- movz/movk chain: portable across gas-ELF and Mach-O
      let w = fromIntegral n :: Word64
          hws = [(w `shiftR` s) .&. 0xffff | s <- [0, 16, 32, 48]]
       in ("movz " ++ xd ++ ", #" ++ show (head hws))
            : [ "movk " ++ xd ++ ", #" ++ show h ++ ", lsl #" ++ show s
                | (h, s) <- zip (tail hws) [16 :: Int, 32, 48],
                  h /= 0
              ]

addImm :: String -> String -> Integer -> [String]
addImm xd xs n
  | n >= 0 && n < 4096 = ["add " ++ xd ++ ", " ++ xs ++ ", #" ++ show n]
  | n < 0 && (-n) < 4096 = ["sub " ++ xd ++ ", " ++ xs ++ ", #" ++ show (-n)]
  | otherwise = movImm "x16" n ++ ["add " ++ xd ++ ", " ++ xs ++ ", x16"]

-- ---- instruction lowering -------------------------------------------

instr :: Bool -> String -> [String]
instr mach body = case parts body of
  -- loads/stores (rv64 words)
  ("ld", [rd, rm]) -> ldst64 "ldur" "ldr" rm rd
  ("sd", [rs, rm]) -> ldst64 "stur" "str" rm rs
  ("lw", [rd, rm]) -> ld32 rd rm
  ("sw", [rs, rm]) -> st32 rs rm
  -- moves / constants / addresses
  ("mv", [rd, "tp"])
    | mach ->
        let xd = xreg rd
         in [ -- Darwin TLV: dyld's _tlv_get_addr preserves all registers
              -- except x0/x16/x17 (the contract that lets compilers drop
              -- this sequence mid-function).  x0 = arg0 and x30 = ra are
              -- live at the entry fuel tick, so both are saved; x17
              -- carries the loaded hart pointer across the restore.
              "sub sp, sp, #16",
              "stp x0, x30, [sp]",
              "adrp x0, _fpr_posix_hart@TLVPPAGE",
              "ldr x0, [x0, _fpr_posix_hart@TLVPPAGEOFF]",
              "ldr x16, [x0]",
              "blr x16",
              "ldr x17, [x0]",
              "ldp x0, x30, [sp]",
              "add sp, sp, #16",
              "mov " ++ xd ++ ", x17" ]
    | otherwise ->
        let xd = xreg rd
         in [ -- local-exec TLS: fpr_posix_hart is __thread (one per hart
              -- pthread), matching X64.hs's %fs load; static-link only,
              -- which is the whole posix philosophy anyway
              "mrs " ++ xd ++ ", tpidr_el0",
              "add " ++ xd ++ ", " ++ xd ++ ", :tprel_hi12:fpr_posix_hart",
              "add " ++ xd ++ ", " ++ xd ++ ", :tprel_lo12_nc:fpr_posix_hart",
              "ldr " ++ xd ++ ", [" ++ xd ++ "]" ]
  ("mv", [rd, rs]) -> ["mov " ++ xreg rd ++ ", " ++ xreg rs]
  ("li", [rd, n]) -> movImm (xreg rd) (readInt n)
  ("la", [rd, sym])
    | mach ->
        let xd = xreg rd
            s = gsym True sym
         in ["adrp " ++ xd ++ ", " ++ s ++ "@PAGE", "add " ++ xd ++ ", " ++ xd ++ ", " ++ s ++ "@PAGEOFF"]
    | otherwise ->
        let xd = xreg rd
         in ["adrp " ++ xd ++ ", " ++ sym, "add " ++ xd ++ ", " ++ xd ++ ", :lo12:" ++ sym]
  -- arithmetic / logic
  ("addi", [rd, rs, n]) -> addImm (xreg rd) (xreg rs) (readInt n)
  ("add", [rd, r1, r2]) -> [rrr "add" rd r1 r2]
  ("sub", [rd, r1, r2]) -> [rrr "sub" rd r1 r2]
  ("mul", [rd, r1, r2]) -> [rrr "mul" rd r1 r2]
  ("div", [rd, r1, r2]) -> [rrr "sdiv" rd r1 r2]
  ("and", [rd, r1, r2]) -> [rrr "and" rd r1 r2]
  ("xor", [rd, r1, r2]) -> [rrr "eor" rd r1 r2]
  ("andi", [rd, rs, n]) -> logImm "and" rd rs n
  ("ori", [rd, rs, n]) -> logImm "orr" rd rs n
  ("xori", [rd, rs, n]) -> logImm "eor" rd rs n
  ("slli", [rd, rs, n]) -> ["lsl " ++ xreg rd ++ ", " ++ xreg rs ++ ", #" ++ n]
  ("srai", [rd, rs, n]) -> ["asr " ++ xreg rd ++ ", " ++ xreg rs ++ ", #" ++ n]
  ("sll", [rd, r1, r2]) -> [rrr "lsl" rd r1 r2]
  -- comparisons materialized to a register (flags dead outside each)
  ("slt", [rd, r1, r2]) -> cmpSet rd r1 r2 "lt"
  ("seqz", [rd, rs]) -> ["cmp " ++ xreg rs ++ ", #0", "cset " ++ xreg rd ++ ", eq"]
  ("snez", [rd, rs]) -> ["cmp " ++ xreg rs ++ ", #0", "cset " ++ xreg rd ++ ", ne"]
  -- branches
  ("beqz", [r, l]) -> ["cbz " ++ xreg r ++ ", " ++ l]
  ("bnez", [r, l]) -> ["cbnz " ++ xreg r ++ ", " ++ l]
  ("bgtz", [r, l]) -> ["cmp " ++ xreg r ++ ", #0", "b.gt " ++ l]
  ("beq", [r1, r2, l]) -> cmpBr r1 r2 "b.eq" l
  ("bne", [r1, r2, l]) -> cmpBr r1 r2 "b.ne" l
  ("bgeu", [r1, r2, l]) -> cmpBr r1 r2 "b.hs" l
  ("bltu", [r1, r2, l]) -> cmpBr r1 r2 "b.lo" l
  -- control transfer
  ("call", [sym]) -> ["bl " ++ gsym mach sym]
  ("j", [l]) -> ["b " ++ l]
  ("ret", []) -> ["ret"] -- no literal pools since the movz/movk change
  (op, _) -> error ("A64: cannot lower `" ++ body ++ "` (op " ++ op ++ ")")
  where
    rrr op rd r1 r2 = op ++ " " ++ xreg rd ++ ", " ++ xreg r1 ++ ", " ++ xreg r2
    cmpBr r1 r2 b l = ["cmp " ++ xreg r1 ++ ", " ++ xreg r2, b ++ " " ++ l]
    cmpSet rd r1 r2 cond =
      ["cmp " ++ xreg r1 ++ ", " ++ xreg r2, "cset " ++ xreg rd ++ ", " ++ cond]
    -- a64 logical immediates are bitmask-encoded; sidestep the encoder
    -- entirely by materializing (the IR only uses small masks anyway)
    logImm op rd rs n =
      movImm "x16" (readInt n) ++ [op ++ " " ++ xreg rd ++ ", " ++ xreg rs ++ ", x16"]
