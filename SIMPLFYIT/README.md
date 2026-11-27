# SIMPLFYIT — Simplify IT (SPOJ)

<https://www.spoj.com/problems/SIMPLFYIT/>

## Problem

Keep a running algebraic expression in two variables `a` and `b`. Add or subtract one monomial per command, and print the current expression on request.

Input: test count `T`; each case has command count `N`, then `N` commands. A command is `1 <expr>` to add, `2 <expr>` to subtract, or `3` to print. An expression has the form `CaPbQ`, with constant `C` and powers `P` and `Q`. Output: one printed expression per command `3`.

| Item | Bound |
|---|---|
| Test count `T` | at most 101 |
| Command count `N` | at most 101 |
| Absolute value of `C`, `P`, `Q` | at most 10 |
| Judge limit | 1 s, 1536 MB |

Terms print in ascending power of `a`, then ascending power of `b`.

Sample input:

```
1
11
3
1 2a1b1
3
1 1a2b0
3
2 1a0b2
3
2 1a5b1
3
1 1a2b0
3
```

Sample output:

```
0
2ab
2ab+a2
-b2+2ab+a2
-b2+2ab+a2-a5b
-b2+2ab+2a2-a5b
```

## Idea

Think of the expression as a labeled shelf with one slot per pair of powers.
Adding a monomial puts its coefficient into the matching slot; subtracting removes some.
Printing walks the shelf from the lowest power of `a` upward, skipping empty slots.
A text-based expression tree would need constant reformatting; a slot table keeps only numbers.

## Why It Works

1. Two monomials combine if and only if their `(P, Q)` pairs match, so a two-dimensional slot table captures the whole state.
2. Powers lie in `[-10, 10]`, so a fixed 21 by 21 table holds every possible slot with no resizing.
3. Walking `P` first and `Q` second produces exactly the required print order.
4. A coefficient of magnitude one omits the digit `1` only when variables are present; a bare constant still prints its value.

| Term | Meaning |
|---|---|
| `coeffs` | table of running coefficients, indexed by power plus ten |
| `monomial` | parsed triple of coefficient, power of `a`, power of `b` |
| `delta` | signed amount added to one slot |
| `firstTerm` | flag that controls the leading plus sign |

The trace below comes from `gen.py` on the sample case:

```
trace: 2ab + a2 - b2 - a5b + a2 -> -b2+2ab+2a2-a5b
```

The final `2a2` appears because two `1a2b0` commands were added.

## Code

**Scanners.** Reads integers, tokens, and signed component values by byte index.

```nim
const powerOffset = 10
const powerSpan = 21
const flushBlockBytes = 1 shl 17

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]

proc readSigned(data: string, pos: var int): int =
  var sign = 1
  if pos < data.len and (data[pos] == '-' or data[pos] == '+'):
    if data[pos] == '-':
      sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

`readSigned` handles a negative coefficient or power without a parse call. `powerOffset` maps powers from `[-10, 10]` into table indexes.

**Monomial parser.** Splits one `CaPbQ` token into three signed numbers.

```nim
proc parseMonomial(token: string): tuple[coefficient, powerA, powerB: int] =
  var pos = 0
  let coefficient = readSigned(token, pos)
  if pos < token.len and token[pos] == 'a':
    pos += 1
  let powerA = readSigned(token, pos)
  if pos < token.len and token[pos] == 'b':
    pos += 1
  let powerB = readSigned(token, pos)
  return (coefficient, powerA, powerB)
```

The letters are skipped, not stored. Missing powers become zero, which matches `b0` and `a0` terms. Cost is one pass over a token of at most a few bytes.

**Expression writer.** Emits nonzero slots in the required order.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendExpression(coeffs: array[powerSpan, array[powerSpan, int]]) =
  var firstTerm = true
  for powerIndexA in 0..<powerSpan:
    for powerIndexB in 0..<powerSpan:
      let coefficient = coeffs[powerIndexA][powerIndexB]
      if coefficient == 0:
        continue
      if coefficient < 0:
        appendOutput("-")
      elif not firstTerm:
        appendOutput("+")
      let magnitude = abs(coefficient)
      let powerA = powerIndexA - powerOffset
      let powerB = powerIndexB - powerOffset
      if magnitude != 1 or (powerA == 0 and powerB == 0):
        appendOutput($magnitude)
      if powerA > 0:
        appendOutput("a")
        if powerA != 1:
          appendOutput($powerA)
      elif powerA < 0:
        appendOutput("a" & $powerA)
      if powerB > 0:
        appendOutput("b")
        if powerB != 1:
          appendOutput($powerB)
      elif powerB < 0:
        appendOutput("b" & $powerB)
      firstTerm = false
  if firstTerm:
    appendOutput("0")
  appendOutput("\n")
```

`firstTerm` suppresses the leading plus sign and still allows a leading minus. Every empty table prints `0`, the stated initial expression.

**Driver.** One input buffer, one output buffer, one slot table per case.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let testCount = nextInt(inputData, scanPos)
for _ in 0..<testCount:
  var coeffs: array[powerSpan, array[powerSpan, int]]
  let commandCount = nextInt(inputData, scanPos)
  for _ in 0..<commandCount:
    let commandType = nextInt(inputData, scanPos)
    if commandType == 3:
      appendExpression(coeffs)
    else:
      let monomial = parseMonomial(nextToken(inputData, scanPos))
      let powerA = monomial.powerA
      let powerB = monomial.powerB
      if powerA >= -powerOffset and powerA <= powerOffset and
         powerB >= -powerOffset and powerB <= powerOffset:
        let indexA = powerA + powerOffset
        let indexB = powerB + powerOffset
        var delta = monomial.coefficient
        if commandType == 2:
          delta = -delta
        coeffs[indexA][indexB] += delta

stdout.write outputBuffer
outputBuffer.setLen 0
```

The table is declared inside the case loop, so each case starts at zero. The range guard keeps an out-of-bound power from corrupting memory. Cost is O(441) per print.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Command apply | one parse and one slot update | table of 441 integers |
| Print | one walk of 441 slots per command `3` | none |
| Output | one write per 128 KiB block | block buffer |

The table is fixed size, so command handling is constant cost.

| Measure | Big O |
|---|---|
| Time | O(input bytes + 441 * number of prints) |
| Space | O(input bytes + 441) |

A string-based expression that rewrites and re-sorts terms on every command would cost far more per print. The slot table turns each command into one integer update.
