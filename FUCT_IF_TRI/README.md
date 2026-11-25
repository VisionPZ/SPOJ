# FUCT_IF_TRI — Geometric triangular (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_TRI/>

## Problem

Three edge lengths arrive together, and a bad measurement must be rejected first.
The first line holds the test count. Each later line holds three integers.
The integers name the edges a, b, and c, separated by spaces.
For each case, print the perimeter and area separated by one space.
Print one exact message instead when the edges are invalid.
A zero or negative edge yields `the length of triangular's edge must be greater than 0`.
Edges that fail the triangle inequality yield `three numbers a and b and c cannot make a triangular`.

| Item | Bound |
|---|---|
| Test cases | 0 < t ≤ 1000 |
| Edges | integers, checked before shape |
| Area | three digits after the decimal point |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
7
0 5 -2
2 3 4
9 1 10
3 6 5
-9 2 4
8 4 1
15 27 20
```

```
the length of triangular's edge must be greater than 0
9 2.905
three numbers a and b and c cannot make a triangular
14 7.483
the length of triangular's edge must be greater than 0
three numbers a and b and c cannot make a triangular
62 147.729
```

## Idea

Treat each test as a gate with two checks before the formula.
Like a baker weighing flour before mixing, the program rejects bad measures first.
Heron's formula then turns three valid edges into an area.
The half-perimeter is the sum of edges divided by two.
Each case costs constant time, with one square root and one formatting call.
A naive search over candidate triangles would add work without changing the answer.

## Why It Works

1. The scanner skips spaces and reads a minus sign before digits.
2. Negative and zero edges reach the edge check before any arithmetic.
3. Positive edges alone do not form a triangle; each pair must beat the third edge.
4. Heron's formula multiplies the half-perimeter with three positive gaps.
5. The square root stays real because the shape check passed.
6. `formatFloat` rounds the area to three fixed decimals for every valid case.

| Term | Meaning |
|---|---|
| `firstEdge` | first integer edge of the current case |
| `halfPerimeter` | half of the integer perimeter |
| `areaValue` | square root of the Heron product |
| `rendered` | one complete output line before buffering |

For `2 3 4`, the half-perimeter is 4.5.
The Heron product is 8.4375, so the area prints as 2.905.

## Code

**Input and hand scanner.** This block loads input and reads signed integers.

```nim
import math
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSigned(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value
```

The read loop stores every input line in one string.
The scanner handles a minus sign before the digits.
One pass over the buffer feeds all cases.

**Buffered output helper.** This block collects finished lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer writes to stdout once every 128 KiB.
A final write flushes any remaining bytes.

**Validation and formulas.** This block checks shape and renders each answer.

```nim
let caseCount = nextSigned(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let firstEdge = nextSigned(inputData, scanPos)
  let secondEdge = nextSigned(inputData, scanPos)
  let thirdEdge = nextSigned(inputData, scanPos)
  var rendered = ""
  if firstEdge <= 0 or secondEdge <= 0 or thirdEdge <= 0:
    rendered.add "the length of triangular's edge must be greater than 0"
  elif firstEdge + secondEdge <= thirdEdge or firstEdge + thirdEdge <= secondEdge or secondEdge + thirdEdge <= firstEdge:
    rendered.add "three numbers a and b and c cannot make a triangular"
  else:
    let perimeter = firstEdge + secondEdge + thirdEdge
    let halfPerimeter = float(perimeter) / 2.0
    let areaValue = sqrt(halfPerimeter * (halfPerimeter - float(firstEdge)) * (halfPerimeter - float(secondEdge)) * (halfPerimeter - float(thirdEdge)))
    rendered.add $(perimeter)
    rendered.add ' '
    rendered.add formatFloat(areaValue, ffDecimal, 3)
  rendered.add '\n'
  appendOutput rendered

stdout.write outputBuffer
outputBuffer.setLen 0
```

Edge checks run before the triangle inequality.
Heron's formula supplies the area for valid edges.
Each line is complete before it enters the buffer.

## Complexity

Each phase handles one pass over its own data.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Scanning | one pass over digits | constant |
| Case work | constant per case | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(t) |
| Space | O(n) for n input bytes |

A naive enumeration of candidate triangles would waste time per case.
Direct checks and one formula keep each case constant.
