# RF102 — DE ZIMZ GRADO 10 (SPOJ)
<https://www.spoj.com/problems/RF102/>

## Problem

A game needs square tiles that fit several houses exactly.
Each input line lists house dimensions separated by commas.
Print the largest tile side that divides every dimension on that line.
A line containing only zero ends the input and produces no output.

| Item | Bound |
|---|---|
| Lines | not stated |
| House dimensions | not stated |
| Time limit | 1000 ms |
| Memory | not stated |

One Euclidean gcd per line gives the answer, so the work stays small.

The sample from the statement:

```
2,3,4
20,10
1,2,3
2,4,8,10
0
```

```
1
10
1
2
```

## Idea

Finding the tile side is like cutting several ribbons into equal pieces with none left over.
The longest piece that fits every ribbon is the greatest common divisor of the dimensions.
The program reads the whole input once and visits it line by line.
It scans each number with a hand scanner and folds them with Euclid's gcd algorithm.
The comma separators are skipped as plain bytes, so no split strings are created.
A line containing only zero stops the loop.

One gcd fold over each line decides the answer.

## Why It Works

1. A tile side divides a dimension exactly when the side is a divisor of that number.
2. A side that fits every house must divide every number on the line.
3. The greatest common divisor is the largest such side.
4. Euclid's remainders preserve the gcd while shrinking the pair.
5. Folding the gcd across all numbers extends the result to the whole line.

The main terms follow.

| Term | Meaning |
|---|---|
| `gcdValue` | gcd of the numbers seen so far on the line |
| `valueCursor` | index of the next byte to inspect |
| `currentValue` | number parsed from the line |
| `onlyZero` | flag marking the end-of-input line |
| `flushIfReady` | writes the buffer once it reaches 131072 bytes |

The fold keeps one integer, so memory stays flat per line.

A trace from `gen.py --trace` for the sample:

```
2,3,4 -> gcd 1
20,10 -> gcd 10
1,2,3 -> gcd 1
2,4,8,10 -> gcd 2
```

The trace matches every sample answer.

## Code

**Bulk input and line scanner.** This block reads stdin once and finds lines by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)
```

The read loop ends at end of input.
Both carriage returns and line feeds end a line.
Empty lines are skipped by the leading scan.

**Number scanner and gcd.** This block parses digits by index and folds with Euclid.

```nim
proc nextNumberInLine(data: string, pos: var int, lineEnd: int): int =
  var value = 0
  while pos < lineEnd and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    inc pos
  return value

proc gcdValues(leftValue: int, rightValue: int): int =
  var leftSide = leftValue
  var rightSide = rightValue
  while rightSide != 0:
    let remainder = leftSide mod rightSide
    leftSide = rightSide
    rightSide = remainder
  return leftSide
```

The scanner stops at the first byte that is not a digit.
Each gcd step replaces the larger pair with its remainder.
The loop ends when the remainder becomes zero.

**Output buffer.** This block buffers answer text and flushes it in blocks.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

The buffer leaves after reaching 131072 bytes.
`appendOutput` adds text and then checks the size.
The last partial block is written after the loop.

**Answer loop.** This block detects the terminator and folds every line.

```nim
while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  if lineStart == lineEnd:
    continue
  var onlyZero = true
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ' and inputData[position] != '0':
      onlyZero = false
      break
  if onlyZero:
    break
  var valueCursor = lineStart
  var haveValue = false
  var gcdValue = 0
  while valueCursor < lineEnd:
    while valueCursor < lineEnd and (inputData[valueCursor] < '0' or
                                     inputData[valueCursor] > '9'):
      inc valueCursor
    if valueCursor >= lineEnd:
      break
    let currentValue = nextNumberInLine(inputData, valueCursor, lineEnd)
    if not haveValue:
      gcdValue = currentValue
      haveValue = true
    else:
      gcdValue = gcdValues(gcdValue, currentValue)
  if haveValue:
    appendOutput($(gcdValue))
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A line with no digits other than zero ends the run.
Separators are skipped one byte at a time.
The final write flushes the last partial block.

## Complexity

Cost follows the number of digits in the input.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| gcd fold | a few steps per number | one integer |
| Output | one write per 128 KiB block | block buffer |

Euclid needs only a handful of steps for ordinary dimensions.

| Measure | Big O |
|---|---|
| Time | O(I + k log v) for I input bytes, k numbers, value v |
| Space | O(I + B) |

Testing every candidate side would be far slower.
A gcd fold gives the largest side directly.
