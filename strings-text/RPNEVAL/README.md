# RPNEVAL — Evaluate simple RPN expression (SPOJ)

<https://www.spoj.com/problems/RPNEVAL/>

## Problem

Evaluate each reverse-polish expression and print its value to four decimal places, or `ERROR` when the expression cannot be evaluated.

Input holds one expression per line, with tokens separated by spaces. Output holds one line per input line: either the value in `%.4f` form or the word `ERROR`.

| Item | Bound |
|---|---|
| Expressions | one per input line |
| Tokens | numbers or one of `+`, `-`, `*`, `/`; separated by spaces |
| Number format | floating point, written as a decimal or exponent token |
| Output form | four digits after the decimal point, or `ERROR` |
| Error cases | bad token, too few operands, extra values, division by zero |
| Judge limit | 1000 ms, 1536 MB |

Sample:

```
1 2 3 /
2 3 /
3 4 * /
1 2 4 + - 5 * 7 /
```

```
ERROR
0.6667
ERROR
-3.5714
```

## Idea

Think of a pile of plates: a number adds a plate, and an operator removes the top two plates and puts one result back.

The program reads every line into one buffer, walks each line token by token, and keeps a stack of floating values. A number token is pushed. An operator pops the right operand and the left operand, applies the operation, and pushes the result. After the last token, exactly one value must remain, and every token must have parsed.

Each token costs one scan and a constant amount of stack work. Building a separate token list first would allocate strings that the stack walk never needs again.

## Why It Works

1. In postfix order, the two newest stack values are the operands of the next operator.
2. An operator removes two values and adds one, so a valid expression leaves exactly one value.
3. A token that is not an operator must parse as a number, with exponent signs in the right place.
4. A zero right operand is rejected before dividing, which covers an expression that does not evaluate correctly.
5. Line boundaries are preserved, so tokens from two expressions never meet on one stack.
6. Formatting with `ffDecimal` and precision four produces the same digits as the required `%.4f` form.

| Term | Meaning |
|---|---|
| `inputData` | all input lines joined into one string |
| `lineCount` | number of lines read, so blank lines still produce answers |
| `expressionText` | one line, scanned independently |
| `valueStack` | floating values waiting for an operator |
| `leftOperand` | second value from the top, used first in `-` and `/` |
| `rightOperand` | top value, removed before the operation |
| `hasToken` | true once the line has produced a token |
| `expressionValid` | false after a bad token, underflow, or zero divisor |

The stack state after the final token decides whether a value can be printed.

A traced run of the fourth sample expression, produced by the generator:

```
tokens: 1 2 4 + - 5 * 7 /
push 1          -> [1]
push 2          -> [1, 2]
push 4          -> [1, 2, 4]
+ : 2 + 4 = 6   -> [1, 6]
- : 1 - 6 = -5  -> [-5]
push 5          -> [-5, 5]
* : -5 * 5 = -25 -> [-25]
push 7          -> [-25, 7]
/ : -25 / 7     -> [-3.571428...]
one value left, format to four places -> "-3.5714"
```

The trace matches the fourth sample output line.

## Code

**Imports and constants.** Float parsing and formatting come from `strutils`.

```nim
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
```

`firstDigitValue` is the byte of `0`. The block size is 128 KiB of output before a write.

**Input read.** Lines are appended to one string, and their count is kept.

```nim
var inputData = ""
var inputLine = ""
var lineCount = 0
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
  lineCount += 1
```

`readLine` works on the judge compiler. Counting lines here keeps blank lines as separate expressions.

**Digit scanner.** The integer fast path walks a token by index.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The `var` parameter keeps the position between calls. A short signed integer becomes one `int`, then a `float`.

**Line scanner.** One call returns one expression line.

```nim
proc nextLine(data: string, pos: var int): string =
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  result = data[pos ..< lineEnd]
  pos = lineEnd + 1
```

The scan stops at the first newline, so tokens cannot cross lines. The returned slice holds exactly one expression.

**Token scanner.** Whitespace separates numbers from operators.

```nim
proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

Runs of spaces and tabs are skipped without allocating. An empty token marks the end of the line.

**Operator test.** A one-character token selects an operation.

```nim
proc isOperatorToken(token: string): bool =
  return token == "+" or token == "-" or token == "*" or token == "/"
```

The four comparisons cover the operators from the statement. Any other token goes to the number parser.

**Number parser.** A strict scan decides whether a token is a valid number.

```nim
proc parseNumber(token: string, value: var float): bool =
  if token.len == 0:
    return false
  var charIndex = 0
  if token[0] == '+' or token[0] == '-':
    charIndex = 1
  var digitsBeforeDot = 0
  var digitsAfterDot = 0
  var exponentDigits = 0
  var dotSeen = false
  var exponentSeen = false
  var exponentSignSeen = false
  while charIndex < token.len:
    let currentChar = token[charIndex]
    if currentChar >= '0' and currentChar <= '9':
      if exponentSeen:
        exponentDigits += 1
      elif dotSeen:
        digitsAfterDot += 1
      else:
        digitsBeforeDot += 1
    elif currentChar == '.' and not dotSeen and not exponentSeen:
      dotSeen = true
    elif (currentChar == 'e' or currentChar == 'E') and not exponentSeen and
         digitsBeforeDot + digitsAfterDot > 0:
      exponentSeen = true
    elif (currentChar == '+' or currentChar == '-') and exponentSeen and
         not exponentSignSeen and exponentDigits == 0:
      exponentSignSeen = true
    else:
      return false
    charIndex += 1
  if digitsBeforeDot + digitsAfterDot == 0:
    return false
  if exponentSeen and exponentDigits == 0:
    return false
  if not dotSeen and not exponentSeen and token.len <= 16:
    var tokenPos = 0
    let integerValue = nextInt(token, tokenPos)
    value = float(integerValue)
    if token[0] == '-':
      value = -value
    return true
  try:
    value = parseFloat(token)
  except ValueError:
    return false
  return true
```

The counters reject `1e`, `--1`, and stray signs before `parseFloat` sees them. The sign branch keeps `-5` negative and `-0` as `-0.0000`.

**Output buffer.** Appends collect bytes and flush a full block.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the buffer after a flush. The guard keeps the write count near the byte count divided by 128 KiB.

**Driver.** One stack walk per line, then one answer line.

```nim
var valueStack: seq[float]
var linePos = 0
var lineIndex = 0
while lineIndex < lineCount:
  let expressionText = nextLine(inputData, linePos)
  valueStack.setLen 0
  var expressionValid = true
  scanPos = 0
  var hasToken = false
  while true:
    let currentToken = nextToken(expressionText, scanPos)
    if currentToken.len == 0:
      break
    hasToken = true
    if isOperatorToken(currentToken):
      if valueStack.len < 2:
        expressionValid = false
        break
      let rightOperand = valueStack[valueStack.len - 1]
      let leftOperand = valueStack[valueStack.len - 2]
      valueStack.setLen(valueStack.len - 1)
      if currentToken == "+":
        valueStack[valueStack.len - 1] = leftOperand + rightOperand
      elif currentToken == "-":
        valueStack[valueStack.len - 1] = leftOperand - rightOperand
      elif currentToken == "*":
        valueStack[valueStack.len - 1] = leftOperand * rightOperand
      else:
        if rightOperand == 0.0:
          expressionValid = false
          break
        valueStack[valueStack.len - 1] = leftOperand / rightOperand
    else:
      var parsedValue = 0.0
      if not parseNumber(currentToken, parsedValue):
        expressionValid = false
        break
      valueStack.add parsedValue
  if expressionValid and hasToken and valueStack.len == 1:
    appendOutput(formatFloat(valueStack[0], ffDecimal, 4))
  else:
    appendOutput("ERROR")
  outputBuffer.add '\n'
  lineIndex += 1
stdout.write outputBuffer
```

`setLen 0` clears the stack for the next line without a new allocation. `scanPos` is reset per line, so token walks never cross expressions. The final condition requires one value, at least one token, and no failed step.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input lines | input bytes |
| Line and token scan | one pass over each line's characters | one line slice |
| Number parse | one pass over each number token | constant |
| Stack work | one push or one pop pair per token | one value per pending operand |
| Output | one write per 128 KiB block | one output buffer |

The token count of each line bounds its work.

| Measure | Big O |
|---|---|
| Time | O(N) for N input bytes plus O(T) stack operations for T tokens |
| Space | O(N) for the input buffer plus O(D) for a stack of depth D |

A recursive descent parser would rebuild operator precedence that postfix notation already encodes. A one-pass stack walk avoids that extra grammar step.
