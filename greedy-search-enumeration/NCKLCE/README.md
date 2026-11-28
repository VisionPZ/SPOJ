# NCKLCE — Another Necklace Problem (SPOJ)

<https://www.spoj.com/problems/NCKLCE/>

## Problem

A circular necklace has N beads, each with a color from 1 to C. Maintain it under rotations, flips, swaps, range repainting, and two kinds of part counts.

Input gives N and C, then N bead colors, then the number of orders. Orders are `R k`, `F`, `S i j`, `P i j x`, `C`, and `CS i j`. Print one answer for each `C` or `CS` order.

| item | bound |
|---|---|
| beads N | at most 500000 |
| colors C | not separately bounded beyond bead colors |
| orders Q | at most 500000 |
| judge limit | 1000 ms, 1536 MB |

Both N and Q reach 500000, so every order must finish in logarithmic time.

Sample input:

```
5 3
1 2 3 2 1
4
C
R 2
P 5 5 2
CS 4 1
```

Sample output:

```
4
1
```

## Idea

Keep the necklace in one fixed array, like a ring of beads clipped to a board, and remember only a rotation and a mirror flag. A lazy segment tree stores the number of color parts for every interval. Each order changes at most two tree paths or one covered interval. Rescanning all beads per order would cost linear time and cannot handle 500000 orders. Takeaway: move the coordinate frame in constant time and let the tree handle only real color changes.

## Why It Works

1. A rotation adds k to a stored offset; a flip toggles a mirror flag and negates that offset.
2. Logical position p maps to a physical index by subtracting the offset, then mirroring when flipped.
3. Under a mirror, clockwise order runs backwards through the physical array, so range endpoints swap.
4. A tree node stores its part count plus its first and last color.
5. Joining two nodes adds their part counts, then subtracts one when the touching colors match.
6. A whole-necklace count also subtracts one when the first and last colors match, because the ring closes.
7. Lazy repainting writes one part and a pending color to a covered node, then pushes that color down before any partial visit.

| term | meaning |
|---|---|
| `rotationOffset` | clockwise shift applied to logical positions |
| `orientationReversed` | whether the necklace is currently mirrored |
| `PartData` | part count with first and last color for an interval |
| `pendingTree` | color waiting to be pushed into a node's children |
| `combineParts` | rule that joins two adjacent intervals |

The generator simulates the same orders by physically moving a Python list, which keeps the tree check independent.

## Code

**Input and scanning.** All input is buffered, and a second scanner reads command letters.

```nim
const flushBlockBytes = 1 shl 17
const noPendingColor = -1

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

proc nextCommand(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The integer scanner skips letters and spaces.
The command scanner returns the next non-space letter.
Answers leave through one block buffer.

**Node state.** Three fields per node describe color runs on an interval.

```nim
type
  PartData = object
    partCount: int
    firstColor: int
    lastColor: int

var partTree: seq[int]
var firstTree: seq[int]
var lastTree: seq[int]
var pendingTree: seq[int]
var beadColors: seq[int]

proc combineParts(leftData, rightData: PartData): PartData =
  if leftData.partCount == 0:
    return rightData
  if rightData.partCount == 0:
    return leftData
  result.partCount = leftData.partCount + rightData.partCount
  if leftData.lastColor == rightData.firstColor:
    result.partCount -= 1
  result.firstColor = leftData.firstColor
  result.lastColor = rightData.lastColor

proc readPartNode(nodeIndex: int): PartData =
  result.partCount = partTree[nodeIndex]
  result.firstColor = firstTree[nodeIndex]
  result.lastColor = lastTree[nodeIndex]
```

An empty result lets a wrapped query join two intervals.
Equal touching colors merge two parts into one.
Each merge runs in constant time.

**Lazy updates.** Painting a covered node records one part and defers the color.

```nim
proc applyPaint(nodeIndex, spanLength, colorValue: int) =
  partTree[nodeIndex] = 1
  firstTree[nodeIndex] = colorValue
  lastTree[nodeIndex] = colorValue
  if spanLength > 1:
    pendingTree[nodeIndex] = colorValue

proc pushPending(nodeIndex, spanLength: int) =
  let pendingColor = pendingTree[nodeIndex]
  if pendingColor != noPendingColor and spanLength > 1:
    applyPaint(nodeIndex * 2, spanLength div 2, pendingColor)
    applyPaint(nodeIndex * 2 + 1, spanLength - spanLength div 2, pendingColor)
    pendingTree[nodeIndex] = noPendingColor

proc pullNode(nodeIndex: int) =
  let combined = combineParts(readPartNode(nodeIndex * 2), readPartNode(nodeIndex * 2 + 1))
  partTree[nodeIndex] = combined.partCount
  firstTree[nodeIndex] = combined.firstColor
  lastTree[nodeIndex] = combined.lastColor
```

A pending color reaches children only on a partial visit.
Leaves never keep a pending color.
The pull step restores a parent after any child change.

**Tree operations.** Build, swap, paint, and query all follow root-to-leaf paths.

```nim
proc buildParts(nodeIndex, leftEdge, rightEdge: int) =
  if rightEdge - leftEdge == 1:
    let beadColor = beadColors[leftEdge]
    partTree[nodeIndex] = 1
    firstTree[nodeIndex] = beadColor
    lastTree[nodeIndex] = beadColor
    return
  let middle = (leftEdge + rightEdge) div 2
  buildParts(nodeIndex * 2, leftEdge, middle)
  buildParts(nodeIndex * 2 + 1, middle, rightEdge)
  pullNode(nodeIndex)

proc setBead(nodeIndex, leftEdge, rightEdge, changedIndex, colorValue: int) =
  if rightEdge - leftEdge == 1:
    partTree[nodeIndex] = 1
    firstTree[nodeIndex] = colorValue
    lastTree[nodeIndex] = colorValue
    pendingTree[nodeIndex] = noPendingColor
    return
  pushPending(nodeIndex, rightEdge - leftEdge)
  let middle = (leftEdge + rightEdge) div 2
  if changedIndex < middle:
    setBead(nodeIndex * 2, leftEdge, middle, changedIndex, colorValue)
  else:
    setBead(nodeIndex * 2 + 1, middle, rightEdge, changedIndex, colorValue)
  pullNode(nodeIndex)

proc paintSegment(nodeIndex, leftEdge, rightEdge, paintLeft, paintRight, colorValue: int) =
  if paintRight <= leftEdge or rightEdge <= paintLeft:
    return
  if paintLeft <= leftEdge and rightEdge <= paintRight:
    applyPaint(nodeIndex, rightEdge - leftEdge, colorValue)
    return
  pushPending(nodeIndex, rightEdge - leftEdge)
  let middle = (leftEdge + rightEdge) div 2
  if paintLeft < middle:
    paintSegment(nodeIndex * 2, leftEdge, middle, paintLeft, paintRight, colorValue)
  if paintRight > middle:
    paintSegment(nodeIndex * 2 + 1, middle, rightEdge, paintLeft, paintRight, colorValue)
  pullNode(nodeIndex)

proc queryParts(nodeIndex, leftEdge, rightEdge, queryLeft, queryRight: int): PartData =
  if queryRight <= leftEdge or rightEdge <= queryLeft:
    return PartData(partCount: 0, firstColor: 0, lastColor: 0)
  if queryLeft <= leftEdge and rightEdge <= queryRight:
    return readPartNode(nodeIndex)
  pushPending(nodeIndex, rightEdge - leftEdge)
  let middle = (leftEdge + rightEdge) div 2
  return combineParts(queryParts(nodeIndex * 2, leftEdge, middle, queryLeft, queryRight),
                      queryParts(nodeIndex * 2 + 1, middle, rightEdge, queryLeft, queryRight))
```

The overlap guard keeps empty ranges away from leaves.
A covered range returns its node without visiting children.
All four operations cost logarithmic time.

**Command driver.** Each order either updates the frame, changes the tree, or prints a count.

```nim
let beadCount = nextInt(inputData, scanPos)
let colorCount = nextInt(inputData, scanPos)
beadColors = newSeq[int](beadCount)
for beadIndex in 0 .. beadCount - 1:
  beadColors[beadIndex] = nextInt(inputData, scanPos)
let treeCapacity = 4 * beadCount + 5
partTree = newSeq[int](treeCapacity)
firstTree = newSeq[int](treeCapacity)
lastTree = newSeq[int](treeCapacity)
pendingTree = newSeq[int](treeCapacity)
for nodeIndex in 0 .. treeCapacity - 1:
  pendingTree[nodeIndex] = noPendingColor
buildParts(1, 0, beadCount)

var rotationOffset = 0
var orientationReversed = false
let commandCount = nextInt(inputData, scanPos)
for commandIndex in 0 .. commandCount - 1:
  var command = nextCommand(inputData, scanPos)
  if command == 'C' and scanPos < inputData.len and inputData[scanPos] == 'S':
    scanPos += 1
    command = 'X'
  case command
  of 'R':
    let shift = nextInt(inputData, scanPos)
    rotationOffset = (rotationOffset + shift) mod beadCount
  of 'F':
    orientationReversed = not orientationReversed
    rotationOffset = (beadCount - rotationOffset) mod beadCount
  of 'S':
    let firstPosition = nextInt(inputData, scanPos)
    let secondPosition = nextInt(inputData, scanPos)
    var firstIndex = (firstPosition - 1 - rotationOffset + beadCount) mod beadCount
    var secondIndex = (secondPosition - 1 - rotationOffset + beadCount) mod beadCount
    if orientationReversed:
      firstIndex = (beadCount - firstIndex) mod beadCount
      secondIndex = (beadCount - secondIndex) mod beadCount
    let firstColor = queryParts(1, 0, beadCount, firstIndex, firstIndex + 1).firstColor
    let secondColor = queryParts(1, 0, beadCount, secondIndex, secondIndex + 1).firstColor
    setBead(1, 0, beadCount, firstIndex, secondColor)
    setBead(1, 0, beadCount, secondIndex, firstColor)
  of 'P':
    let firstPosition = nextInt(inputData, scanPos)
    let secondPosition = nextInt(inputData, scanPos)
    let paintColor = nextInt(inputData, scanPos)
    var leftIndex = (firstPosition - 1 - rotationOffset + beadCount) mod beadCount
    var rightIndex = (secondPosition - 1 - rotationOffset + beadCount) mod beadCount
    if orientationReversed:
      leftIndex = (beadCount - leftIndex) mod beadCount
      rightIndex = (beadCount - rightIndex) mod beadCount
      let swapIndex = leftIndex
      leftIndex = rightIndex
      rightIndex = swapIndex
    rightIndex = (rightIndex + 1) mod beadCount
    if leftIndex < rightIndex:
      paintSegment(1, 0, beadCount, leftIndex, rightIndex, paintColor)
    else:
      paintSegment(1, 0, beadCount, 0, rightIndex, paintColor)
      paintSegment(1, 0, beadCount, leftIndex, beadCount, paintColor)
  of 'C':
    let whole = queryParts(1, 0, beadCount, 0, beadCount)
    var answer = whole.partCount
    if answer > 1 and whole.firstColor == whole.lastColor:
      answer -= 1
    appendOutput($answer)
    outputBuffer.add '\n'
  of 'X':
    let firstPosition = nextInt(inputData, scanPos)
    let secondPosition = nextInt(inputData, scanPos)
    var leftIndex = (firstPosition - 1 - rotationOffset + beadCount) mod beadCount
    var rightIndex = (secondPosition - 1 - rotationOffset + beadCount) mod beadCount
    if orientationReversed:
      leftIndex = (beadCount - leftIndex) mod beadCount
      rightIndex = (beadCount - rightIndex) mod beadCount
      let swapIndex = leftIndex
      leftIndex = rightIndex
      rightIndex = swapIndex
    rightIndex = (rightIndex + 1) mod beadCount
    var segmentData: PartData
    if leftIndex < rightIndex:
      segmentData = queryParts(1, 0, beadCount, leftIndex, rightIndex)
    else:
      segmentData = combineParts(queryParts(1, 0, beadCount, leftIndex, beadCount),
                                 queryParts(1, 0, beadCount, 0, rightIndex))
    appendOutput($segmentData.partCount)
    outputBuffer.add '\n'
  else:
    discard

stdout.write outputBuffer
outputBuffer.setLen 0
```

Rotations and flips never touch the tree.
A wrapped interval is painted or queried as two intervals.
The circular count removes one part when both ends share a color.

## Complexity

Each order is one frame change or one logarithmic tree walk.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| tree build | one merge per internal node | four arrays of size 4N |
| rotation or flip | constant work | two frame variables |
| swap | two point updates | recursion stack |
| paint | one lazy interval update | recursion stack |
| count | one or two interval queries | recursion stack |
| output | one line per counted order | block buffer |

| measure | Big O |
|---|---|
| time | O(N + Q log N) |
| space | O(N) |

Moving every bead for a rotation would cost O(N) per order, while the tree keeps each order logarithmic.
