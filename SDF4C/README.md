# SDF4C — Robot Spiral Path (SPOJ)

<https://www.spoj.com/problems/SDF4C/>

## Problem

Cells are numbered along a square spiral of growing runs: one north, one east, two south, two west, three north, and so on. From cell P, list the direction runs that take the robot to cell Q.

The first line is T. Each of the next T lines holds P and Q with P < Q. Print one line per case: step count followed by U, T, S or B, joined by ` -> ` with no trailing separator.

| item | bound |
|---|---|
| test cases T | not bounded by the statement |
| start cell P | 0 to 9999999 |
| target cell Q | P + 1 to 10000000 |
| judge limit | 30 ms, 1536 MB |

Large cell numbers rule out walking the whole spiral for every case.

The sample input:

```
2
8 14
3 5
```

It holds two separate movement requests.

The sample output:

```
1U -> 3T -> 2S
1S -> 1B
```

Each line describes one trip through consecutive cells.

## Idea

Picture the number track as a staircase spiral, like a path that grows one step longer every two turns. A binary search on n times n plus n finds the run containing P. The offset inside that run gives the first direction. Walk the remaining distance through U, T, S and B, lengthening the run after T and B. Takeaway: jump to the right run, then step through the turns.

## Why It Works

1. Pattern n starts at cell n times n plus n and has two runs of n plus one steps.
2. The largest n whose pattern start is at or before P gives the current run.
3. `patternStart` and `startOffset` locate P inside that run.
4. Directions cycle as U, T, S and B, and run length grows after T and B.
5. When the remaining distance fits inside the current run, the robot keeps that direction to the target.

| term | meaning |
|---|---|
| `patternNumber` | index of the spiral pattern holding P |
| `patternStart` | first cell of that pattern |
| `startOffset` | distance from the pattern start to P |
| `segmentLength` | number of steps in the current run |
| `stepOffset` | steps already used in the current run |
| `remainingSteps` | distance still to travel |
| `directionIndex` | 0 for U, 1 for T, 2 for S, 3 for B |

The table follows one trip from the start cell to its printed instructions.

The first sample starts at cell 8, where n is 2, the pattern start is 6 and the offset is 2. That leaves one north step, then three east, then two south. The second sample starts at cell 3, where n is 1, the pattern start is 2 and the offset is 1. It takes one south step and one west step.

```
8 -> 14 : n=2 start=6 offset=2 -> 1U -> 3T -> 2S
3 -> 5  : n=1 start=2 offset=1 -> 1S -> 1B
```

The trace matches both sample lines.

The binary search replaces a square root, so no floating-point guard is needed.

## Code

**Input and pattern lookup.** The reader loads all cases, and a binary search finds the pattern index.

```nim
const flushBlockBytes = 1 shl 17
const directionCount = 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc findPatternNumber(cellNumber: int): int =
  var lowValue = 0
  var highValue = 1000000
  while lowValue < highValue:
    let middleValue = (lowValue + highValue + 1) div 2
    if middleValue * middleValue + middleValue <= cellNumber:
      lowValue = middleValue
    else:
      highValue = middleValue - 1
  return lowValue
```

The search bound exceeds the largest possible pattern index.
Products stay small enough for a signed 64-bit integer.
The scanner ignores spaces and newlines between P and Q.

**Direction walk and output.** The loop emits one run at a time until the target is reached.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let startCell = nextInt(inputData, scanPos)
  let targetCell = nextInt(inputData, scanPos)
  let patternNumber = findPatternNumber(startCell)
  let patternStart = patternNumber * patternNumber + patternNumber
  let startOffset = startCell - patternStart
  let segmentLength = patternNumber + 1
  let travelSteps = targetCell - startCell
  var stepOffset = 0
  var currentLength = segmentLength
  var directionIndex = 0
  if patternNumber mod 2 == 0:
    if startOffset >= segmentLength:
      stepOffset = startOffset - segmentLength
      directionIndex = 1
    else:
      stepOffset = startOffset
  elif startOffset >= segmentLength:
    stepOffset = startOffset - segmentLength
    directionIndex = 3
  else:
    stepOffset = startOffset
    directionIndex = 2
  var remainingSteps = travelSteps
  var firstInstruction = true
  while remainingSteps > 0:
    var stepCount = 0
    var nextRemaining = 0
    if currentLength <= remainingSteps:
      nextRemaining = remainingSteps - currentLength + stepOffset
      stepCount = currentLength - stepOffset
    else:
      stepCount = remainingSteps
    if not firstInstruction:
      appendOutput(" -> ")
    firstInstruction = false
    appendOutput($stepCount)
    case directionIndex:
      of 0: appendOutput("U")
      of 1: appendOutput("T")
      of 2: appendOutput("S")
      else: appendOutput("B")
    stepOffset = 0
    remainingSteps = nextRemaining
    if remainingSteps == 0:
      break
    if directionIndex == 1 or directionIndex == 3:
      currentLength += 1
    directionIndex = (directionIndex + 1) mod directionCount
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Even patterns start with U or T, odd patterns with S or B.
The offset shortens only the first emitted run.
The separator is written before every instruction except the first.

## Complexity

Lookup cost is small, and the walk emits only as many runs as the trip crosses.

| phase | time | space |
|---|---|---|
| input read | one pass over T cases | one input string |
| pattern lookup | binary search per case | constant |
| direction walk | one step per emitted run | constant |
| output | one line per case | block buffer |

A trip crosses at most a few thousand runs at the given bound.

| measure | Big O |
|---|---|
| time per case | O(log Q + number of runs) |
| space | O(1) besides input and output buffers |

Walking every cell from zero to Q would cost O(Q) per case.

Takeaway: the pattern lookup keeps each case short even for large cell numbers.
