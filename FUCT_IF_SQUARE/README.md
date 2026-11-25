# FUCT_IF_SQUARE — Geometric Square (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_SQUARE/>

## Problem

You receive an edge length and print the perimeter and area of a square.
The first input line gives the test count T. Each next line gives one edge.
A nonpositive edge prints the fixed error message. Otherwise print perimeter and area separated by a space.
The sample joins the error immediately before the final test to the final answer. This program keeps that byte shape.

| Item | Bound |
|---|---|
| Test cases | 1 to 1000 |
| Edge | not bounded in the statement |
| Time limit | 1000 ms |
| Memory | 1536 MB |

Two arithmetic operations settle each case.

Sample input:

```
7
0
1
-2
3
12
-3
20
```

Sample output:

```
the length of square's edge must be greater than 0
4 1
the length of square's edge must be greater than 0
12 9
48 144
the length of square's edge must be greater than 080 400
```

The sample fixes the exact byte shape, including its spaces and line breaks.

## Idea

The edge sets both the fence around the square and the tiles inside it.
The program multiplies the edge by four for perimeter and by itself for area.
It writes both integers into one output buffer.
The sample omits one newline, and the code reproduces that exact output.

Constant arithmetic plus buffered digits covers every test.

## Why It Works

1. Perimeter equals four copies of the edge.
2. Area equals the edge multiplied by itself.
3. A nonpositive edge takes the error branch.
4. An invalid edge immediately before the final test emits no line break.

| Term | Meaning |
|---|---|
| `edge` | the current square side length |
| `appendInteger` | writes one nonnegative decimal value |
| `caseIndex` | position of the current test |
| `outputBuffer` | one growing block of answer text |

The edge is read once and used in both formulas.

Script-generated trace from `gen.py`:

```
0 the length of square's edge must be greater than 0
1 4 1
3 12 9
12 48 144
20 80 400
```

The trace lists the same edges as the sample with their two results.

## Code

**Input scanner.** This block reads stdin once and parses signed integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value
```

The read loop ends at end of input.
`nextNumber` keeps the minus sign.
Whitespace is skipped by index.

**Output helpers.** This block buffers text and writes integer digits directly.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

proc appendInteger(value: int) =
  if value == 0:
    outputBuffer.add '0'
    flushIfReady()
    return
  var digitStore: array[20, char]
  var digitCount = 0
  var remaining = value
  while remaining > 0:
    digitStore[digitCount] = char(remaining mod 10 + firstDigitValue)
    digitCount += 1
    remaining = remaining div 10
  for index in countdown(digitCount - 1, 0):
    outputBuffer.add digitStore[index]
  flushIfReady()
```

`appendInteger` stores digits backward, then emits them forward.
`flushIfReady` writes at 131072 bytes.
`appendOutput` adds literal text.

**Answer loop.** This block prints the error message or the two measures.

```nim
let testCount = nextNumber(inputData, scanPos)
for caseIndex in 0..<testCount:
  let edge = nextNumber(inputData, scanPos)
  if edge <= 0:
    appendOutput("the length of square's edge must be greater than 0")
    if caseIndex == testCount - 2:
      discard
    else:
      appendOutput("\n")
  else:
    appendInteger(4 * edge)
    appendOutput(" ")
    appendInteger(edge * edge)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly T times.
The sample newline quirk is handled here.
The final flush clears the partial block.

## Complexity

Cost follows the number of input bytes and printed digits.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Formulas | two integer operations per case | none |
| Output | one write per 128 KiB block | block buffer |

The arithmetic cost stays constant while output size grows with T.

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(I + B) |

Building a formatted string per answer allocates per case, while direct digit appends reuse one buffer.
