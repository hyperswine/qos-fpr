# interactive_script.sol -- a small line-oriented calculator.
#
# readLineNow is deliberately realtime: an interactive session cannot be
# replayed as one whole-script transaction. Enter a blank line, `quit`, or
# `exit` to leave.

isDigit : Int -> Bool .
isDigit c = and (c >= 48) (c <= 57).

skipSpace : unsafe String -> Int -> Int .
skipSpace s i = case i > Str.len s of
  True -> i
  | False -> case Str.isSpace (Str.at s i) of
      True -> skipSpace s (i + 1)
      | False -> i.

scanNumber : unsafe String -> Int -> Int -> Int .
scanNumber s i dots = case i > Str.len s of
  True -> i
  | False ->
      c = Str.at s i;
      case isDigit c of
        True -> scanNumber s (i + 1) dots
        | False -> case and (c == 46) (dots == 0) of
            True -> scanNumber s (i + 1) 1
            | False -> i.

decimalText : String -> String .
decimalText raw =
  front = case Str.at raw 1 == 46 of True -> "0{raw}" | False -> raw;
  case Str.at front (Str.len front) == 46 of
    True -> "{front}0"
    | False -> front.

parseNumber : unsafe String -> Int -> Result (Int, Int) String .
parseNumber s i =
  j = scanNumber s i 0;
  case j == i of
    True -> Err "expected a number at column {i}"
    | False -> case Try.parseNum (decimalText (Str.sub s i (j - i))) of
        Ok n -> Ok (n, j)
        | Err e -> Err e.

parsePrimary : unsafe String -> Int -> Result (Int, Int) String .
parsePrimary s at =
  i = skipSpace s at;
  case i > Str.len s of
    True -> Err "expected a number or '(' at end of input"
    | False ->
      c = Str.at s i;
      case c == 40 of
        True -> (case parseExpr s (i + 1) of
          Err e -> Err e
          | Ok (value, afterExpr) ->
            close = skipSpace s afterExpr;
            case close > Str.len s of
              True -> Err "expected ')' at end of input"
              | False -> case Str.at s close == 41 of
                  True -> Ok (value, close + 1)
                  | False -> Err "expected ')' at column {close}")
        | False -> parseNumber s i.

parseFactor : unsafe String -> Int -> Result (Int, Int) String .
parseFactor s at =
  i = skipSpace s at;
  case i > Str.len s of
    True -> Err "expected a number or '(' at end of input"
    | False ->
      c = Str.at s i;
      case c == 45 of
        True -> (case parseFactor s (i + 1) of
          Ok (value, next) -> Ok (0 - value, next)
          | Err e -> Err e)
        | False -> case c == 43 of
            True -> parseFactor s (i + 1)
            | False -> parsePrimary s i.

parseTermRest : unsafe String -> Int -> Int -> Result (Int, Int) String .
parseTermRest s left at =
  i = skipSpace s at;
  case i > Str.len s of
    True -> Ok (left, i)
    | False ->
      op = Str.at s i;
      case or (op == 42) (op == 47) of
        False -> Ok (left, i)
        | True -> (case parseFactor s (i + 1) of
            Err e -> Err e
            | Ok (right, next) -> case op == 42 of
                True -> parseTermRest s (left * right) next
                | False -> case right == 0 of
                    True -> Err "division by zero"
              | False -> parseTermRest s (Numeric.div left right) next).

parseTerm : unsafe String -> Int -> Result (Int, Int) String .
parseTerm s i = case parseFactor s i of
  Err e -> Err e
  | Ok (left, next) -> parseTermRest s left next.

parseExprRest : unsafe String -> Int -> Int -> Result (Int, Int) String .
parseExprRest s left at =
  i = skipSpace s at;
  case i > Str.len s of
    True -> Ok (left, i)
    | False ->
      op = Str.at s i;
      case or (op == 43) (op == 45) of
        False -> Ok (left, i)
        | True -> (case parseTerm s (i + 1) of
            Err e -> Err e
            | Ok (right, next) -> case op == 43 of
                True -> parseExprRest s (left + right) next
                | False -> parseExprRest s (left - right) next).

parseExpr : unsafe String -> Int -> Result (Int, Int) String .
parseExpr s i = case parseTerm s i of
  Err e -> Err e
  | Ok (left, next) -> parseExprRest s left next.

evaluate : unsafe String -> Result Int String .
evaluate source = case parseExpr source 1 of
  Err e -> Err e
  | Ok (value, at) ->
    rest = skipSpace source at;
    case rest > Str.len source of
      True -> Ok value
      | False -> Err "unexpected character '{Str.fromCode (Str.at source rest)}' at column {rest}".

repl : unsafe Unit -> Unit .
repl u =
  p = print "> expr";
  line = Str.trim (readLineNow Unit);
  case or (line == "") (or (line == "quit") (line == "exit")) of
    True -> print "bye"
    | False ->
      shown = case evaluate line of
        Ok value -> "= {value}"
        | Err e -> "error: {e}";
      out = print shown;
      repl Unit.

> repl Unit.
