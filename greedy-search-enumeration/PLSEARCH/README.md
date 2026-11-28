# PLSEARCH — Polygonal Line Search (SPOJ)

<https://www.spoj.com/problems/PLSEARCH/>

## Problem

Find which polygonal lines match a template after rotation and translation. Reversing the vertex order is allowed, but mirroring and scaling are not.

Each dataset starts with the number of candidate lines, then the template, then the candidates. Every line starts with its vertex count, followed by one x-y pair per vertex. A zero ends the dataset list. Print matching candidate numbers in ascending order, one per line, then a line of five plus signs.

| item | bound |
|---|---|
| candidates per dataset | 1 to 50 |
| vertices per line | 3 to 10 |
| coordinate values | -9999 to 9999 |
| judge limit | 0.747 s, 1536 MB |

Every segment runs along an axis, and every vertex turns by a right angle.

Sample input:

```
5
5
0 0
2 0
2 1
4 1
4 0
5
0 0
0 2
-1 2
-1 4
0 4
5
0 0
0 1
-2 1
-2 2
0 2
5
0 0
0 -1
2 -1
2 0
4 0
5
0 0
2 0
2 -1
4 -1
4 0
5
0 0
2 0
2 1
4 1
4 0
4
4
-60 -75
-60 -78
-42 -78
-42 -6
4
10 3
10 7
-4 7
-4 40
4
-74 66
-74 63
-92 63
-92 135
4
-12 22
-12 25
-30 25
-30 -47
4
12 -22
12 -25
30 -25
30 47
3
5
-8 5
-8 2
0 2
0 4
8 4
5
-3 -1
0 -1
0 7
-2 7
-2 16
5
-1 6
-1 3
7 3
7 5
16 5
5
0 1
0 -2
8 -2
8 0
17 0
0
```

Sample output:

```
1
3
5
+++++
3
4
+++++
+++++
```

## Idea

Compare lines as a dance routine of turns and step lengths. Translation drops out when steps replace coordinates, rotation adds one fixed offset to every turn, and reversing swaps each direction by two quarter turns. Encode each line as direction-and-length steps, then compare its four rotations with the template and repeat after reversal. Testing every translated copy on the grid would be far slower.

## Why It Works

1. A step has one of four directions and a positive length.
2. Rotation by a quarter turn adds one to each direction code, leaving lengths unchanged.
3. Reversal walks the step list backwards and adds two to each direction code.
4. Two lines match when some rotation of one step list equals the other step list.
5. A mirrored line changes turn handedness, so no rotation of its step list matches.

| term | meaning |
|---|---|
| `directionCode` | quarter-turn code for one segment |
| `appendFixedLength` | writes a segment length as five fixed digits |
| `rotateSequence` | adds the same turn offset to every segment |
| `reverseSequence` | walks segments backwards and flips each direction |
| `sameShape` | tests eight variants against the template |

A script check of the first sample template reads steps east 2, north 1, east 2, south 1. Candidate one repeats those steps after translation, so it matches. Candidate two reads north 1, west 2, north 1, south 2, so its lengths differ and it fails.

Fixed-width length fields keep every encoded step at six characters. No rounding or floating-point test enters the comparison.

## Code

**Input and scanning.** The hand reader accepts signed coordinates and buffers all output.

```nim
const flushBlockBytes = 1 shl 17
const turnCount = 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner handles the minus sign before a coordinate.
Every result line goes through the single output buffer.

**Step encoding.** Consecutive vertices become direction codes plus fixed-width lengths.

```nim
proc directionCode(fromX: int, fromY: int, toX: int, toY: int): int =
  if toX > fromX:
    return 0
  if toY > fromY:
    return 1
  if toX < fromX:
    return 2
  return 3

proc appendFixedLength(sequence: var string, length: int) =
  var divisor = 10000
  while divisor > 0:
    sequence.add chr(48 + (length div divisor) mod 10)
    divisor = divisor div 10

proc encodeLine(vertexCount: int): string =
  var previousX = nextInt(inputData, scanPos)
  var previousY = nextInt(inputData, scanPos)
  var sequence = ""
  for vertexIndex in 1 .. vertexCount - 1:
    let currentX = nextInt(inputData, scanPos)
    let currentY = nextInt(inputData, scanPos)
    let stepLength = abs(currentX - previousX) + abs(currentY - previousY)
    sequence.add chr(48 + directionCode(previousX, previousY, currentX, currentY))
    appendFixedLength(sequence, stepLength)
    previousX = currentX
    previousY = currentY
  return sequence
```

Direction codes run east, north, west, south.
Five digits hold any step length allowed by the coordinate bounds.

**Eight variants.** Rotation and reversal generate every allowed comparison form.

```nim
proc rotateSequence(sequence: string, shift: int): string =
  var rotated = ""
  var index = 0
  while index < sequence.len:
    rotated.add chr(48 + ((int(sequence[index]) - 48 + shift) mod turnCount))
    for offset in 1 .. 5:
      rotated.add sequence[index + offset]
    index += 6
  return rotated

proc reverseSequence(sequence: string): string =
  var reversed = ""
  var index = sequence.len - 6
  while index >= 0:
    var code = int(sequence[index]) - 48
    code = (code + 2) mod turnCount
    reversed.add chr(48 + code)
    for offset in 1 .. 5:
      reversed.add sequence[index + offset]
    index -= 6
  return reversed

proc sameShape(reference: string, candidate: string): bool =
  if candidate.len != reference.len:
    return false
  for shift in 0 .. turnCount - 1:
    if rotateSequence(candidate, shift) == reference:
      return true
  let reversedCandidate = reverseSequence(candidate)
  for shift in 0 .. turnCount - 1:
    if rotateSequence(reversedCandidate, shift) == reference:
      return true
  return false
```

Reversal adds two quarter turns to each direction code.
A length mismatch rules out a match before any rotation is built.

**Driver.** Each dataset reports its matches before the plus-sign separator.

```nim
while true:
  let lineCount = nextInt(inputData, scanPos)
  if lineCount == 0:
    break
  let templateSequence = encodeLine(nextInt(inputData, scanPos))
  for lineIndex in 1 .. lineCount:
    let candidateSequence = encodeLine(nextInt(inputData, scanPos))
    if sameShape(templateSequence, candidateSequence):
      appendOutput($lineIndex)
      outputBuffer.add '\n'
  appendOutput("+++++\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Candidate numbers follow input order, so results are already sorted.
The final flush writes any buffered tail.

## Complexity

| phase | time | space |
|---|---|---|
| encoding | one pass over each vertex list | one step string per line |
| variant test | eight rotations of a short string | one variant string |
| output | one line per match and separator | block buffer |

| measure | Big O |
|---|---|
| time per candidate | O(m) with at most ten vertices |
| space | O(size of input) |

Trying translations over the coordinate grid would test millions of positions instead of eight variants.

Each candidate takes only a few dozen character operations, so datasets finish quickly.
