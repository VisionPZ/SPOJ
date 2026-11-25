# SWTHIN — Swamp Things (SPOJ)
<https://www.spoj.com/problems/SWTHIN/>

## Problem

A photograph holds distinct bright spots. Find the largest set of spots on one straight line, and report its size only when at least four spots share that line. Otherwise report zero.

| item | bound |
|---|---|
| spots per photo | positive, at most 1000 |
| coordinates | 0 to 10000 |
| termination | photo size 0 |
| judge limit | 3707 ms, 1536 MB |

Ties for the largest line produce the same count, so the random choice in the story does not affect the answer.

Sample input:

```
6
0 1
0 2
1 2
2 2
4 5
5 6
4
3 5
4 4
6 5
7 4
0
```

Sample output:

```
Photo 1: 4 points eliminated
Photo 2: 0 points eliminated
```

## Idea

Treating each spot as a pivot resembles fanning a ruler around a pin: every other spot lands on one direction. Spots with the same reduced direction from the pivot lie on one line. Counting directions for every pivot finds the largest line. Checking all quadruples would be far slower.

## Why It Works

1. Two spots define a direction, reduced by their greatest common divisor.
2. Spots on one line through a pivot share the same reduced direction.
3. The table counts how many spots share each direction from a pivot.
4. Adding the pivot itself gives the full size of that line.
5. The largest such size over all pivots is the largest line in the photo.

| term | meaning |
|---|---|
| `directionKey` | packed reduced pair of coordinate steps |
| `directionCounts` | spots per direction for one pivot |
| `greatestCommonDivisor` | factor that reduces a step pair |
| `bestLineCount` | largest line size found so far |

In photo 1, the pivot `(0,1)` sees steps `(0,1)`, `(1,1)`, `(2,1)`, `(4,4)`, and `(5,5)`. Reduction maps `(1,1)`, `(4,4)`, and `(5,5)` to the same key `(1,1)`. That group plus the pivot has four spots, so the photo reports 4.

The `minimumTrainLength` guard turns any count below four into zero.

## Code

**Input and helpers.** The reader takes all text once, and the gcd reduces every direction.

```nim
import tables

const flushBlockBytes = 1 shl 17
const coordinateOffset = 10000
const directionSpan = 20001
const minimumTrainLength = 4

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

proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var left = firstValue
  var right = secondValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The offset keeps both reduced steps nonnegative inside the key.
The span makes the packed key unique for each step pair.
One final write empties the output buffer.

**Pivot sweep.** Each pivot groups all other spots by reduced direction.

```nim
var photoNumber = 0
while true:
  let pointCount = nextInt(inputData, scanPos)
  if pointCount == 0:
    break
  photoNumber += 1
  var xCoordinates = newSeq[int](pointCount)
  var yCoordinates = newSeq[int](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    xCoordinates[pointIndex] = nextInt(inputData, scanPos)
    yCoordinates[pointIndex] = nextInt(inputData, scanPos)
  var bestLineCount = 0
  for anchorIndex in 0 .. pointCount - 1:
    var directionCounts = initTable[int, int]()
    for otherIndex in 0 .. pointCount - 1:
      if otherIndex == anchorIndex:
        continue
      let horizontalStep = xCoordinates[otherIndex] - xCoordinates[anchorIndex]
      let verticalStep = yCoordinates[otherIndex] - yCoordinates[anchorIndex]
      let divisor = greatestCommonDivisor(abs(horizontalStep), abs(verticalStep))
      if divisor == 0:
        continue
      let directionKey = (horizontalStep div divisor + coordinateOffset) * directionSpan + (verticalStep div divisor + coordinateOffset)
      directionCounts[directionKey] = directionCounts.getOrDefault(directionKey) + 1
    for directionKey in directionCounts.keys:
      let lineCount = directionCounts[directionKey] + 1
      if lineCount > bestLineCount:
        bestLineCount = lineCount
  if bestLineCount < minimumTrainLength:
    bestLineCount = 0
  appendOutput("Photo ")
  appendOutput($photoNumber)
  appendOutput(": ")
  appendOutput($bestLineCount)
  appendOutput(" points eliminated\n")
```

A fresh table starts for each pivot.
The divisor handles vertical and diagonal lines alike.
Adding one counts the pivot itself.
Only lines of four or more spots are reported.

## Complexity

| phase | time | space |
|---|---|---|
| read spots | one pass over each photo | one input string |
| pivot sweep | n pivots times n steps | table of up to n keys |
| output | one line per photo | block buffer |

| measure | Big O |
|---|---|
| per photo | O(n^2) expected time |
| space | O(n) |

Testing every group of four spots would cost far more than counting directions.
