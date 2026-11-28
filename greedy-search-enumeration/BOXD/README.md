# BOXD — Boxdropper (SPOJ)

<https://www.spoj.com/problems/BOXD/>

## Problem

Boxes float on a large lake and geese walk freely over any box. Between boxes they fly in a straight line. For each query, report the least flying distance needed to travel between two boxes.

Input is a stream of commands read to end of file. A line starting with B and four coordinates drops an axis-aligned box with those opposite corners. A line starting with G and two numbers asks for the flight distance between the ath and bth boxes dropped. Coordinates have absolute value at most 10^6, with at most 500 boxes and 10^6 commands. Print one distance per query with two decimals.

| item | bound |
|---|---|
| boxes | 1 to 500 |
| commands | up to 10^6 |
| coordinate magnitude | at most 10^6 |
| judge limit | 4000 ms, 1536 MB |

The box count drives the table size; the command count drives the write path.

The sample input:

```
B -1 2 1 5
B 3 -4 4 1
G 2 1
B 4 -3 6 -2
B 6 -6 8 -4
G 2 3
G 1 4
```

The sample output:

```
2.24
0.00
3.24
```

## Idea

The shortest flight may land on intermediate boxes, like a trip that splits one long water crossing into two shorter hops. Model boxes as graph nodes with edge weight equal to the gap between their rectangles. Maintain all-pairs shortest paths as boxes arrive, so each query reads one table cell. A fresh search per query costs quadratic work each time. The direct gap between two boxes is not enough, because a path through a third box can be shorter. Each new box updates the table in quadratic time and answers become constant time.

## Why It Works

1. Walking inside a box is free, so only flights between boxes add distance.
2. The gap between two axis-aligned rectangles is the Euclidean norm of their separate x and y gaps.
3. Overlapping or touching rectangles have a zero gap.
4. Any physical trip visits a sequence of boxes, so the answer is a shortest path in the box graph.
5. When box k arrives, old box pairs only improve through k, and distances to k improve through old boxes.
6. Both updates are quadratic in k, and reversing the gap never helps because edges are symmetric.

| term | meaning |
|---|---|
| `BoxRect` | normalised rectangle with low and high x and y edges |
| `rectangleDistance` | straight-line gap between two rectangles |
| `distances` | flat all-pairs shortest-path table |
| `throughNew` | candidate cost of routing a pair through the new box |

The table names the structures used during each insertion.

A script trace of the sample queries:

```
after boxes 1 and 2: gap x = 3-1 = 2, gap y = 2-1 = 1
                     distance = sqrt(4+1) = 2.24
after box 3:         boxes 2 and 3 touch at x = 4 -> 0.00
after box 4:         box 3 to box 4 has gap y = 1 -> 1.00
                     route 1 -> 2 -> 3 -> 4 costs 2.24 + 0 + 1.00 = 3.24
```

The trace matches all three sample answers.

Two decimals exceed the requested precision. The table stores full double values and rounds only at print time.

## Code

**Input and helpers.** The reader loads the command stream and parses signed coordinates and command letters.

```nim
import math
import strutils

const flushBlockBytes = 1 shl 17
const maxBoxCount = 500

type BoxRect = object
  xLow: int
  xHigh: int
  yLow: int
  yHigh: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
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

proc nextCommand(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  if pos >= data.len:
    return '\0'
  result = data[pos]
  pos += 1
  return result

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextCommand` returns a zero character at end of input.
`nextInt` keeps a sign branch for negative coordinates.
The output buffer flushes in blocks rather than per query.

**Rectangle gap.** The gap separates into independent x and y distances.

```nim
proc rectangleDistance(firstBox: BoxRect, secondBox: BoxRect): float =
  var gapX = 0
  var gapY = 0
  if firstBox.xLow > secondBox.xHigh:
    gapX = firstBox.xLow - secondBox.xHigh
  elif secondBox.xLow > firstBox.xHigh:
    gapX = secondBox.xLow - firstBox.xHigh
  if firstBox.yLow > secondBox.yHigh:
    gapY = firstBox.yLow - secondBox.yHigh
  elif secondBox.yLow > firstBox.yHigh:
    gapY = secondBox.yLow - firstBox.yHigh
  return sqrt(float(gapX * gapX + gapY * gapY))
```

Each axis contributes zero when the spans overlap.
Squared gaps are integers before the square root.
Touching boxes produce a zero distance.

**Incremental table.** Each new box improves distances to old boxes and then old pairs.

```nim
var boxes: array[maxBoxCount, BoxRect]
var distances = newSeq[float](maxBoxCount * maxBoxCount)

proc addBox(boxIndex: int, newBox: BoxRect) =
  boxes[boxIndex] = newBox
  for previousBox in 0 .. boxIndex - 1:
    let gap = rectangleDistance(boxes[previousBox], newBox)
    distances[boxIndex * maxBoxCount + previousBox] = gap
    distances[previousBox * maxBoxCount + boxIndex] = gap
  for middleBox in 0 .. boxIndex - 1:
    for targetBox in 0 .. boxIndex - 1:
      let throughOld = distances[boxIndex * maxBoxCount + middleBox] +
                       distances[middleBox * maxBoxCount + targetBox]
      if throughOld < distances[boxIndex * maxBoxCount + targetBox]:
        distances[boxIndex * maxBoxCount + targetBox] = throughOld
        distances[targetBox * maxBoxCount + boxIndex] = throughOld
  for leftBox in 0 .. boxIndex - 1:
    for rightBox in 0 .. boxIndex - 1:
      let throughNew = distances[leftBox * maxBoxCount + boxIndex] +
                       distances[boxIndex * maxBoxCount + rightBox]
      if throughNew < distances[leftBox * maxBoxCount + rightBox]:
        distances[leftBox * maxBoxCount + rightBox] = throughNew
```

The first loop stores direct rectangle gaps.
The second loop finds better routes from the new box through old boxes.
The third loop uses the new box as a midpoint for old pairs.

**Command loop.** Box commands extend the table and query commands read one cell.

```nim
var boxCount = 0
while true:
  let command = nextCommand(inputData, scanPos)
  if command == '\0':
    break
  if command == 'B':
    let firstX = nextInt(inputData, scanPos)
    let firstY = nextInt(inputData, scanPos)
    let secondX = nextInt(inputData, scanPos)
    let secondY = nextInt(inputData, scanPos)
    var newBox: BoxRect
    if firstX <= secondX:
      newBox.xLow = firstX
      newBox.xHigh = secondX
    else:
      newBox.xLow = secondX
      newBox.xHigh = firstX
    if firstY <= secondY:
      newBox.yLow = firstY
      newBox.yHigh = secondY
    else:
      newBox.yLow = secondY
      newBox.yHigh = firstY
    addBox(boxCount, newBox)
    boxCount += 1
  else:
    let fromBox = nextInt(inputData, scanPos) - 1
    let toBox = nextInt(inputData, scanPos) - 1
    let flightDistance = distances[fromBox * maxBoxCount + toBox]
    appendOutput(formatFloat(flightDistance, ffDecimal, 2) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Corner order is normalised before the box joins the table.
Query numbers are one-based, so the code subtracts one.
Each query costs one table lookup and one formatted line.

## Complexity

Insertion cost grows with the number of boxes already present.

| phase | time | space |
|---|---|---|
| input read | one pass over all commands | one input string |
| box insertion | two quadratic sweeps per box | distance table |
| query | one lookup and one formatted line | block buffer |

Insertion dominates total runtime; queries only stream output.

| measure | Big O |
|---|---|
| time | O(n^3 + q) |
| space | O(n^2) |

n is the box count, at most 500, and q is the query count.

Running a fresh search for every query costs O(q n^2) time. The incremental table pays once per box and answers each query in constant time.
