## Problem

A ball rolls diagonally on a rectangular board of cells. It starts at a cell next to an edge, bounces off the edges, and stops when it enters that cell again. Each entered cell receives a point. Print the number of cells that receive an odd number of points, for each dataset.

The limits are:

| Limit | Value |
| --- | --- |
| Datasets | at most 10 |
| Board sides | each greater than 2 |
| Cells | at most 10⁹ |
| Start | next to an edge |
| Time | 5000 ms |
| Memory | 1536 MB |

The board can be large, so the answer must come from arithmetic rather than a walk over every cell.

## Idea

Model the roll as steps between cell centers. Each step moves one cell sideways and one cell up or down, and a wall reflects the step. The path repeats after a fixed number of steps. Count how many cells get visited an odd number of times in one repeat. The greatest common divisor (gcd) of the two reduced board sides gives that count directly.

Each dataset costs one gcd and a fixed number of arithmetic operations.

## Why It Works

The ball's center stays one radius from each wall. Its contact point therefore travels from the center of one cell to the center of a diagonal neighbor. One step enters exactly one new cell.

Let X and Y be the board sides minus one. Let g be their gcd. When the start's offset along the edge is a multiple of g, the ball reaches a corner and only two cells get odd counts. Otherwise the walk lasts 2XY/g steps. It revisits 2(X/g)(Y/g) − X/g − Y/g cells. The odd count equals the walk length minus twice that revisit count.

If the start lies on the horizontal edge instead, the code swaps the two axes. The offset that matters is then the coordinate along that edge.

Generated example for input `10 7 1 5`:

```text
board 10 by 7, start (1,5)
X=6, Y=9, g=3
along=4, across=0, along mod g=1
widthSegments=2, heightSegments=3
period=36, crossings=7, odd cells=22
```

The swap turns the vertical-edge start into a horizontal-edge start. Since 4 mod 3 is not zero, the walk length 36 and seven revisits give 22 odd cells.

## Code

```nim
const zeroDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var scanPosition = 0

proc nextInteger(sourceData: string, scanPos: var int): int64 =
  while scanPos < sourceData.len and sourceData[scanPos] < '0':
    scanPos += 1
  var parsedValue: int64 = 0
  while scanPos < sourceData.len and sourceData[scanPos] >= '0':
    parsedValue = parsedValue * 10 + int64(int(sourceData[scanPos]) - zeroDigitValue)
    scanPos += 1
  return parsedValue
```

The read loop runs once per input line and appends to one buffer. The scanner skips separators and reads digits in place, so it allocates nothing. Parsing costs one pass over the input bytes.

```nim
proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue
```

Euclid's loop ends when the remainder reaches zero. It uses 64-bit values so the answer stays exact at the largest board. The loop takes O(log(min(X, Y))) steps.

```nim
var outputBuffer = ""

let dataSetCount = nextInteger(inputData, scanPosition)
var caseIndex: int64 = 0
while caseIndex < dataSetCount:
  var boardWidth = nextInteger(inputData, scanPosition) - 1
  var boardHeight = nextInteger(inputData, scanPosition) - 1
  var startColumn = nextInteger(inputData, scanPosition) - 1
  var startRow = nextInteger(inputData, scanPosition) - 1
  if startRow != 0 and startRow != boardHeight:
    swap(boardWidth, boardHeight)
    swap(startColumn, startRow)
  let commonDivisor = greatestCommonDivisor(boardWidth, boardHeight)
  var oddFieldCount: int64
  if startColumn mod commonDivisor == 0:
    oddFieldCount = 2
  else:
    let widthSegments = boardWidth div commonDivisor
    let heightSegments = boardHeight div commonDivisor
    oddFieldCount = 2 * boardWidth * boardHeight div commonDivisor -
                    4 * widthSegments * heightSegments +
                    2 * widthSegments + 2 * heightSegments
  outputBuffer.add $oddFieldCount
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

if outputBuffer.len > 0:
  stdout.write outputBuffer
```

The loop runs exactly `dataSetCount` times. The swap keeps the edge coordinate in `startRow`, so `startColumn` always holds the offset that matters. Output collects in one buffer and flushes only after 256 KiB, which avoids a write per answer.

## Complexity

Input reading and scanning take time linear in the number of input bytes. Each dataset spends O(log(min(X, Y))) time in the gcd and O(1) time elsewhere. Total time is O(input bytes + d log(min(X, Y))).

The program stores the input buffer and an output buffer capped at the flush size. Space is O(input bytes + flushBlockBytes).

A direct walk over the whole repeat takes O(XY/g) steps per dataset, which can approach 10⁹. The closed form removes that walk.
