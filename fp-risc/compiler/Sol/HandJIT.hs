-- Sol/HandJIT.hs — the hand-rolled JIT tier (SOL_JIT=hand).
--
-- The LLVM tier is a GENERAL typed compiler; this is not that, and is
-- not trying to be.  The Vec schemes only ever need one shape of code:
--
--     loop over a single unboxed column, tiny pure arithmetic kernel
--
-- so handJIT emits exactly that — a few hundred bytes of x86-64
-- (SSE2 scalar for f64, plain integer ops for i64) into an mmap'd
-- page, honoring the SAME generated-function ABI as the LLVM tier:
--
--     i64 f(i64* pfuel, i64* extras, i64** cols, i64 n, i64 out/acc0)
--     rdi        rsi         rdx        rcx        r8
--
-- which means runVecMapFilter / runVecFold and everything above them
-- are reused untouched: handJIT is another DISCHARGE of the
-- compileVecScheme contract, not another dispatch path.  No LLVM
-- linkage, no ORC startup price — the whole tier is this file plus a
-- 15-line mmap shim.
--
-- Deliberately narrow (declines fall to the interpreter):
--   * vecmap / vecfold only, single scalar column, no captured extras
--   * kernel fragment: params, int literals, + - * /, comparisons
--     inside `if` conditions, Num.sqrt (f64), let (inlined by
--     substitution — the fragment is pure, duplication is safe)
--   * kernel type = column type throughout; int `/` is quot (idiv),
--     f64 `/` is IEEE divsd — the same split the interpreter's arith
--     makes, so results stay bit-identical
--   * fuel charged in bulk at entry (sub [pfuel], n): the reified
--     per-element decrement collapses to one subtraction because the
--     kernel has no calls to meter
module Sol.HandJIT (HandCtx, newHandCtx, handCompileVec) where

import Data.Bits (shiftL, (.|.), (.&.))
import GHC.Float (castWord32ToFloat, castWord64ToDouble)
import Data.Bits (shiftR, (.&.))
import Data.IORef
import Data.Int (Int64)
import qualified Data.Map.Strict as M
import Data.Word (Word8)
import Foreign.Marshal.Array (withArray)
import Foreign.Ptr (Ptr, ptrToIntPtr)
import GHC.Float (castDoubleToWord64)
import Control.Monad (when)
import Sol.Lang (Core (..), Prog, Name)
import Sol.Bytecode (cmpNames)
import System.Info (arch)
import System.Environment (lookupEnv)

foreign import ccall unsafe "hj_alloc" c_hjAlloc :: Ptr Word8 -> Int -> IO (Ptr Word8)

newtype HandCtx = HandCtx (IORef (M.Map (String, Name, Char) Int64))

newHandCtx :: IO HandCtx
newHandCtx = HandCtx <$> newIORef M.empty

-- entry: compile scheme+fn for elem kind 'i'/'d'.  Returns the callable
-- address (cached) or Nothing when the kernel leaves the fragment.
handCompileVec :: HandCtx -> Prog -> String -> Name -> Char -> IO (Maybe Int64)
handCompileVec (HandCtx ref) prog scheme g ek
  -- the emitter produces x86-64 SysV bytes; on any other host the tier
  -- DECLINES (interp takes it) rather than executing wrong-arch code
  | arch /= "x86_64" = pure Nothing
handCompileVec (HandCtx ref) prog scheme g ek = do
  cache <- readIORef ref
  case M.lookup (scheme, g, ek) cache of
    Just a -> pure (Just a)
    Nothing -> case emitKernel prog scheme g ek of
      Nothing -> do
        dbg <- lookupEnv "SOL_HJIT_DEBUG"
        when (dbg == Just "1") $
          putStrLn ("[hjit] declined " ++ scheme ++ "<" ++ g ++ ">: " ++ maybe "no such fn" (show . snd) (M.lookup g prog))
        pure Nothing
      Just bytes -> do
        p <- withArray bytes $ \pb -> c_hjAlloc pb (length bytes)
        let a = fromIntegral (ptrToIntPtr p)
        if a == 0
          then pure Nothing
          else do
            modifyIORef' ref (M.insert (scheme, g, ek) a)
            putStrLn ("[hjit] compiled " ++ scheme ++ "<" ++ g ++ "> elem=" ++ [ek] ++ " (" ++ show (length bytes) ++ " bytes hand-rolled x86-64, no llvm)")
            pure (Just a)

-- ---------------------------------------------------------------------
-- assembler: flat [Word8] with two-pass label patching kept trivial by
-- emitting only forward jumps whose targets we compute inline
-- ---------------------------------------------------------------------

type Asm = [Word8]

imm32 :: Int -> Asm
imm32 v = [fromIntegral (v `shiftR` s .&. 0xFF) | s <- [0, 8, 16, 24]]

imm64 :: Int64 -> Asm
imm64 v = [fromIntegral (fromIntegral v `shiftR` s .&. (0xFF :: Integer)) | s <- [0, 8, 16, 24, 32, 40, 48, 56]]

-- fixed encodings (see ABI in the header comment)
pPushR12, pPushR13, pPopR13, pPopR12 :: Asm
pPushR12 = [0x41, 0x54]
pPushR13 = [0x41, 0x55]
pPopR13 = [0x41, 0x5D]
pPopR12 = [0x41, 0x5C]

movR9ColBase :: Asm
movR9ColBase = [0x4C, 0x8B, 0x0A] -- mov r9, [rdx]   (cols[0])

subFuelN :: Asm
subFuelN = [0x48, 0x29, 0x0F] -- sub [rdi], rcx  (bulk fuel charge)

zeroR10 :: Asm
zeroR10 = [0x4D, 0x31, 0xD2] -- xor r10, r10

cmpR10N :: Asm
cmpR10N = [0x49, 0x39, 0xCA] -- cmp r10, rcx

incR10 :: Asm
incR10 = [0x49, 0xFF, 0xC2]

loadElemD, loadElemI :: Asm
loadElemD = [0xF2, 0x43, 0x0F, 0x10, 0x14, 0xD1] -- movsd xmm2, [r9+r10*8]
loadElemI = [0x4F, 0x8B, 0x2C, 0xD1] -- mov r13, [r9+r10*8]

storeOutD, storeOutI :: Asm
storeOutD = [0xF2, 0x43, 0x0F, 0x11, 0x04, 0xD0] -- movsd [r8+r10*8], xmm0
storeOutI = [0x4B, 0x89, 0x04, 0xD0] -- mov [r8+r10*8], rax

-- expr-eval scratch: result in xmm0 (d) / rax (i); operand stack = CPU stack
pushD, popD1 :: Asm
pushD = [0x48, 0x83, 0xEC, 0x08, 0xF2, 0x0F, 0x11, 0x04, 0x24] -- sub rsp,8; movsd [rsp],xmm0
popD1 = [0xF2, 0x0F, 0x10, 0x0C, 0x24, 0x48, 0x83, 0xC4, 0x08] -- movsd xmm1,[rsp]; add rsp,8

pushI, popI11 :: Asm
pushI = [0x50] -- push rax
popI11 = [0x49, 0x89, 0xC3, 0x58] -- mov r11, rax; pop rax   (L->rax, R->r11)

opD :: String -> Asm -- xmm1 = L, xmm0 = R; result -> xmm0
opD o =
  let k = case o of "+" -> 0x58; "-" -> 0x5C; "*" -> 0x59; _ -> 0x5E
   in [0xF2, 0x0F, k, 0xC8, 0x66, 0x0F, 0x28, 0xC1] -- opsd xmm1,xmm0; movapd xmm0,xmm1

opI :: String -> Asm -- rax = L, r11 = R; result -> rax
opI "+" = [0x4C, 0x01, 0xD8]
opI "-" = [0x4C, 0x29, 0xD8]
opI "*" = [0x49, 0x0F, 0xAF, 0xC3]
opI _ = [0x48, 0x99, 0x49, 0xF7, 0xFB] -- cqo; idiv r11   (quot: sol's int /)

litD :: Double -> Asm
litD d = [0x48, 0xB8] ++ imm64 (fromIntegral (castDoubleToWord64 d)) ++ [0x66, 0x48, 0x0F, 0x6E, 0xC0] -- mov rax,bits; movq xmm0,rax

litI :: Int64 -> Asm
litI v = [0x48, 0xB8] ++ imm64 v -- mov rax, imm

varD :: Int -> Asm -- 0: elem/x (xmm2), 1: acc (xmm3)
varD 0 = [0x66, 0x0F, 0x28, 0xC2] -- movapd xmm0, xmm2
varD _ = [0x66, 0x0F, 0x28, 0xC3]

varI :: Int -> Asm
varI 0 = [0x4C, 0x89, 0xE8] -- mov rax, r13
varI _ = [0x4C, 0x89, 0xE0] -- mov rax, r12

sqrtD :: Asm
sqrtD = [0xF2, 0x0F, 0x51, 0xC0] -- sqrtsd xmm0, xmm0

-- comparisons: bool result in rax (0/1)
cmpD, cmpI :: String -> Asm
cmpD o = [0x66, 0x0F, 0x2E, 0xC8] ++ setcc (fcc o) -- ucomisd xmm1, xmm0
  where
    fcc c = case c of "<" -> 0x92; "<=" -> 0x96; ">" -> 0x97; ">=" -> 0x93; "==" -> 0x94; _ -> 0x95
cmpI o = [0x4C, 0x39, 0xD8] ++ setcc (icc o) -- cmp rax, r11
  where
    icc c = case c of "<" -> 0x9C; "<=" -> 0x9E; ">" -> 0x9F; ">=" -> 0x9D; "==" -> 0x94; _ -> 0x95

setcc :: Word8 -> Asm
setcc cc = [0x0F, cc, 0xC0, 0x48, 0x0F, 0xB6, 0xC0] -- setcc al; movzx rax, al

testJz :: Int -> Asm
testJz rel = [0x48, 0x85, 0xC0, 0x0F, 0x84] ++ imm32 rel -- test rax,rax; jz rel32

jmpRel :: Int -> Asm
jmpRel rel = [0xE9] ++ imm32 rel

-- ---------------------------------------------------------------------
-- kernel emission
-- ---------------------------------------------------------------------

callsSelf :: Name -> Core -> Bool
callsSelf h = go
  where
    go c = case c of
      CVar v -> v == h
      CApp a b -> go a || go b
      CIf a b d -> go a || go b || go d
      CLet _ a b -> go a || go b
      _ -> False

cmpOps :: [String]
cmpOps = cmpNames -- the ONE vocabulary (Bytecode.arithOps); the setcc
                  -- tables' catch-all is setne, so != lands right

spine :: Core -> (Core, [Core])
spine = go []
  where
    go acc (CApp f a) = go (a : acc) f
    go acc h = (h, acc)

-- inline lets by substitution (pure fragment: safe)
substC :: Name -> Core -> Core -> Core
substC x v = go
  where
    go c = case c of
      CVar y | y == x -> v
      CApp a b -> CApp (go a) (go b)
      CIf a b d -> CIf (go a) (go b) (go d)
      CLet y a b | y /= x -> CLet y (go a) (go b)
      CLet y a b -> CLet y (go a) b
      other -> other

-- expression codegen; env maps param name -> var slot (0 = elem, 1 = acc).
-- Calls to other one-param functions (guard clauses lift into these)
-- are inlined by substitution when the callee is non-recursive — the
-- fragment stays closed, the tier stays narrow.
exprAsm :: Prog -> Char -> M.Map Name Int -> Core -> Maybe Asm
exprAsm prog ek env = goV
  where
    goV c = case c of
      -- inline saturated calls to non-recursive prog functions (guard
      -- clauses and join points lift into these); spine-collected so
      -- join-point partial applications inline too
      _ | (CVar h, args@(_ : _)) <- spine c,
          Nothing <- M.lookup h env,
          h `notElem` ["Num.sqrt", "+", "-", "*", "/"] ++ cmpOps,
          Just (hps, hb) <- M.lookup h prog,
          length hps == length args,
          not (callsSelf h hb) ->
            goV (foldr (\(p, a) acc -> substC p a acc) hb (zip hps args))
      CVar v | Just slot <- M.lookup v env -> Just (if ek == 'd' then varD slot else varI slot)
      CInt k -> Just (if ek == 'd' then litD (fromIntegral k) else litI (fromIntegral k))
      CLet x v b -> goV (substC x v b)
      -- float-literal splices (parser shape only): a double immediate.
      -- Guarded on ek == 'd' -- the hand tier is mono-kind, so a float
      -- literal in an int-kind body declines to the llvm tier (sound).
      CApp (CApp (CVar "f64frombits") (CInt hi)) (CInt lo)
        | ek == 'd' ->
            Just (litD (castWord64ToDouble
                          ((fromIntegral hi `shiftL` 32)
                             .|. (fromIntegral lo .&. 0xFFFFFFFF))))
      CApp (CVar "f32frombits") (CInt bb)
        | ek == 'd' -> Just (litD (realToFrac (castWord32ToFloat (fromIntegral bb))))
      CApp (CVar "Num.sqrt") a | ek == 'd' -> (++ sqrtD) <$> goV a
      CApp (CApp (CVar o) a) b
        | o `elem` ["+", "-", "*", "/"] -> do
            la <- goV a
            lb <- goV b
            pure $
              if ek == 'd'
                then la ++ pushD ++ lb ++ popD1 ++ opD o
                else la ++ pushI ++ lb ++ popI11 ++ opI o
      CIf (CApp (CApp (CVar o) a) b) t f
        | o `elem` cmpOps -> do
            la <- goV a
            lb <- goV b
            lt <- goV t
            lf <- goV f
            let cnd = if ek == 'd' then la ++ pushD ++ lb ++ popD1 ++ cmpD o else la ++ pushI ++ lb ++ popI11 ++ cmpI o
                thenB = lt ++ jmpRel (length lf)
            pure (cnd ++ testJz (length thenB) ++ thenB ++ lf)
      _ -> Nothing

emitKernel :: Prog -> String -> Name -> Char -> Maybe Asm
emitKernel prog scheme g ek = do
  (ps, body0) <- M.lookup g prog
  case (scheme, ps) of
    ("vecmap", [x]) -> do
      e <- exprAsm prog ek (M.fromList [(x, 0)]) body0
      let loadE = if ek == 'd' then loadElemD else loadElemI
          store = if ek == 'd' then storeOutD else storeOutI
          body = loadE ++ e ++ store ++ incR10
          -- loop: cmp; jge +body+jmp; body; jmp back
          jgeF = [0x0F, 0x8D] ++ imm32 (length body + 5)
          back = negate (length cmpR10N + length jgeF + length body + 5)
      pure $
        pPushR12 ++ pPushR13 ++ subFuelN ++ movR9ColBase ++ zeroR10
          ++ cmpR10N ++ jgeF ++ body ++ jmpRel back
          ++ [0x48, 0x89, 0xC8] -- mov rax, rcx (k = n)
          ++ pPopR13 ++ pPopR12 ++ [0xC3]
    ("vecfold", [a, x]) -> do
      e <- exprAsm prog ek (M.fromList [(x, 0), (a, 1)]) body0
      let accInit = if ek == 'd' then [0x66, 0x49, 0x0F, 0x6E, 0xD8] else [0x4D, 0x89, 0xC4] -- movq xmm3,r8 / mov r12,r8
          loadE = if ek == 'd' then loadElemD else loadElemI
          accSet = if ek == 'd' then [0x66, 0x0F, 0x28, 0xD8] else [0x49, 0x89, 0xC4] -- movapd xmm3,xmm0 / mov r12,rax
          accOut = if ek == 'd' then [0x66, 0x48, 0x0F, 0x7E, 0xD8] else [0x4C, 0x89, 0xE0] -- movq rax,xmm3 / mov rax,r12
          body = loadE ++ e ++ accSet ++ incR10
          jgeF = [0x0F, 0x8D] ++ imm32 (length body + 5)
          back = negate (length cmpR10N + length jgeF + length body + 5)
      pure $
        pPushR12 ++ pPushR13 ++ subFuelN ++ movR9ColBase ++ accInit ++ zeroR10
          ++ cmpR10N ++ jgeF ++ body ++ jmpRel back
          ++ accOut ++ pPopR13 ++ pPopR12 ++ [0xC3]
    _ -> Nothing
