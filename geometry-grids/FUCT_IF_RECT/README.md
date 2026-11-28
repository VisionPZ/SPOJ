# FUCT_IF_RECT — Geometric Rectangular (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_RECT/>

## Problem

You receive two edges and print the perimeter and area of a rectangle.
The first input line gives the test count T. Each next line holds two edges separated by a space.
Either nonpositive edge prints the fixed error message. Otherwise print perimeter and area separated by a space.
Perimeter uses both edges twice, and area multiplies them.

| Item | Bound |
|---|---|
| Test cases | 1 to 1000 |
| Edges | not bounded in the statement |
| Time limit | 1000 ms |
| Memory | 1536 MB |

Two arithmetic operations settle each case.

Sample input:

```
7
0 9
2 5
1 -5
10 7
9 4
-9 4
12 20
```

Sample output:

```
the length of rectangular's edges must be greater than 0
14 10
the length of rectangular's edges must be greater than 0
34 70
26 36
the length of rectangular's edges must be greater than 0
64 240
```

The sample fixes the exact byte shape, including its spaces and line breaks.

## Idea

Walk the border for perimeter and count floor tiles for area.
The program adds two copies of each edge, then multiplies the two edges.
Both values go into one output buffer as raw digits.
The error branch uses a fixed message when either edge fails the test.

One pair of formulas and one buffer handle every case.

## Why It Works

1. Perimeter equals twice the sum of the two edges.
2. Area equals the first edge multiplied by the second edge.
3. Either nonpositive edge sends the case to the error branch.
4. The scanner keeps minus signs so that check stays exact.

| Term | Meaning |
|---|---|
| `firstEdge` | the first side length |
| `secondEdge` | the second side length |
| `appendInteger` | writes one nonnegative decimal value |
| `outputBuffer` | one growing block of answer text |

Both edges are read once before either formula runs.

Script-generated trace from `gen.py`:

```
0 9 the length of rectangular's edges must be greater than 0
2 5 14 10
10 7 34 70
12 20 64 240
```

The trace lists the sample pairs with their perimeter and area.

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
`nextNumber` keeps each minus sign.
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
  let firstEdge = nextNumber(inputData, scanPos)
  let secondEdge = nextNumber(inputData, scanPos)
  if firstEdge <= 0 or secondEdge <= 0:
    appendOutput("the length of rectangular's edges must be greater than 0")
  else:
    appendInteger(2 * (firstEdge + secondEdge))
    appendOutput(" ")
    appendInteger(firstEdge * secondEdge)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly T times.
The error branch checks both edges.
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

Writing each result line directly calls the stream once per case, while block flushing batches those calls.
