## Problem

Read t cases. Each case gives n points with integer coordinates from 1 to 1000000. Find the largest box with a corner at the origin, edges on the positive axes, and no given point in its interior. A point on a wall does not count. Print the positive coordinates of the far corner. Any largest box is accepted.

The table lists the input bounds and the judge limits.

| Quantity | Bound |
| --- | --- |
| Test cases t | at most 10 |
| Points per case n | at most 5000 |
| Each coordinate | 1 to 1000000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

Up to 50000 points per run rules out a search over all coordinate triples.

## Idea

Use a sweep over the x edge and a segment tree over the y edge. Each box edge stops at a point or at the coordinate limit, so point x values cover every answer. The tree keeps the best y*z per point at O(log^2 n) steps, instead of checking all coordinate triples.

## Why It Works

A point with integer coordinates is inside box (X,Y,Z) when x<X, y<Y, and z<Z. A point on a wall never counts, so equality is safe.

For a fixed X, only points with x<X matter. For each candidate Y, the largest safe Z is the smallest z among those points with y<Y. When no such point exists, Z is 1000000. Call this value minZ(Y).

minZ(Y) never grows as Y grows. Adding point (y,z) lowers minZ(Y) for Y>y, and only where minZ(Y)>z. Those Y values form one interval, so one range set handles the insertion.

The tree stores Y*minZ(Y) at each compressed Y. A range set to z puts the largest Y in that range at the top. The sweep tries X at every point x and at 1000000. The best X equals the smallest x of the points blocking some Y,Z, or 1000000, so the list is complete.

The script prints one row per candidate x edge for the sample points.

| X edge | best Y*Z | chosen Y | chosen Z | volume |
| --- | --- | --- | --- | --- |
| 2 | 1000000000000 | 1000000 | 1000000 | 2000000000000 |
| 3 | 200000000 | 200000 | 1000 | 600000000 |
| 90000 | 200000000 | 200000 | 1000 | 18000000000000 |
| 1000000 | 200000000 | 200000 | 1000 | 200000000000000 |

The last row is largest, which gives the sample answer.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxEdge = 1000000

type
  Point = object
    coordX: int
    coordY: int
    coordZ: int

proc nextInt(data: string, position: var int): int =
  let dataLength = data.len
  while position < dataLength and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < dataLength and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

Both loops stop at dataLength, the end of the one input buffer. Skipping non-digits absorbs the blank lines between cases. Scanning costs one pass over the bytes.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer = ""
```

The loop runs once per input line and keeps all data in one buffer. The newline keeps two neighboring numbers apart. Reading costs one pass over the stream.

```nim
var yValues: seq[int]
var treeMax: seq[int64]
var treeArg: seq[int]
var treeLazy: seq[int]

proc applyValue(nodeIndex, rightBound, value: int) =
  treeMax[nodeIndex] = int64(value) * int64(yValues[rightBound])
  treeArg[nodeIndex] = rightBound
  treeLazy[nodeIndex] = value

proc buildTree(nodeIndex, leftBound, rightBound: int) =
  treeLazy[nodeIndex] = -1
  if leftBound == rightBound:
    treeMax[nodeIndex] = int64(maxEdge) * int64(yValues[leftBound])
    treeArg[nodeIndex] = leftBound
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound)
  if treeMax[nodeIndex * 2 + 1] >= treeMax[nodeIndex * 2]:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2 + 1]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2 + 1]
  else:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2]

proc pushDown(nodeIndex, leftBound, rightBound: int) =
  let pending = treeLazy[nodeIndex]
  if pending != -1:
    let middle = (leftBound + rightBound) div 2
    applyValue(nodeIndex * 2, middle, pending)
    applyValue(nodeIndex * 2 + 1, rightBound, pending)
    treeLazy[nodeIndex] = -1
```

Build runs once per case over the sorted y values. applyValue sets a whole node range to one z value, so the largest Y in that range wins. pushDown clears a stale parent value before a partial update.

```nim
proc valueAt(nodeIndex, leftBound, rightBound, target: int): int =
  if treeLazy[nodeIndex] != -1:
    return treeLazy[nodeIndex]
  if leftBound == rightBound:
    return int(treeMax[nodeIndex] div int64(yValues[leftBound]))
  let middle = (leftBound + rightBound) div 2
  if target <= middle:
    return valueAt(nodeIndex * 2, leftBound, middle, target)
  return valueAt(nodeIndex * 2 + 1, middle + 1, rightBound, target)

proc assignRange(nodeIndex, leftBound, rightBound, queryLeft, queryRight, value: int) =
  if queryLeft <= leftBound and rightBound <= queryRight:
    applyValue(nodeIndex, rightBound, value)
    return
  pushDown(nodeIndex, leftBound, rightBound)
  let middle = (leftBound + rightBound) div 2
  if queryLeft <= middle:
    assignRange(nodeIndex * 2, leftBound, middle, queryLeft, queryRight, value)
  if queryRight > middle:
    assignRange(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, value)
  if treeMax[nodeIndex * 2 + 1] >= treeMax[nodeIndex * 2]:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2 + 1]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2 + 1]
  else:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2]

proc insertPoint(pointY, pointZ: int) =
  let lastIndex = yValues.len - 1
  var low = 0
  var high = lastIndex
  while low < high:
    let middle = (low + high) div 2
    if yValues[middle] < pointY:
      low = middle + 1
    else:
      high = middle
  let firstAffected = low + 1
  if firstAffected > lastIndex:
    return
  if valueAt(1, 0, lastIndex, firstAffected) <= pointZ:
    return
  var leftIndex = firstAffected
  var rightIndex = lastIndex
  while leftIndex < rightIndex:
    let middle = (leftIndex + rightIndex + 1) div 2
    if valueAt(1, 0, lastIndex, middle) > pointZ:
      leftIndex = middle
    else:
      rightIndex = middle - 1
  assignRange(1, 0, lastIndex, firstAffected, leftIndex, pointZ)
```

insertPoint finds the first y edge above the point with a binary search. A second binary search finds the last edge whose minZ exceeds z. assignRange then updates that interval once. Each insertion costs about log^2 n steps.

```nim
proc considerEdge(edgeX: int, bestVolume: var int64, answerX, answerY, answerZ: var int) =
  let product = treeMax[1]
  let winningIndex = treeArg[1]
  let winningY = yValues[winningIndex]
  let winningZ = valueAt(1, 0, yValues.len - 1, winningIndex)
  let volume = int64(edgeX) * product
  if volume > bestVolume:
    bestVolume = volume
    answerX = edgeX
    answerY = winningY
    answerZ = winningZ
```

considerEdge reads the top product from the root. The stored index gives Y, and valueAt gives Z. One check costs one tree descent.

```nim
var caseIndex = 0
while caseIndex < caseCount:
  let pointCount = nextInt(inputData, i)
  var points = newSeq[Point](pointCount)
  for j in 0..<pointCount:
    points[j].coordX = nextInt(inputData, i)
    points[j].coordY = nextInt(inputData, i)
    points[j].coordZ = nextInt(inputData, i)

  points.sort(proc (left, right: Point): int = left.coordX - right.coordX)

  yValues = @[maxEdge]
  for j in 0..<pointCount:
    yValues.add points[j].coordY
  yValues.sort(proc (left, right: int): int = left - right)
  var yCount = 0
  for j in 0..<yValues.len:
    if j == 0 or yValues[j] != yValues[j - 1]:
      yValues[yCount] = yValues[j]
      yCount += 1
  yValues.setLen yCount

  let lastIndex = yValues.len - 1
  treeMax = newSeq[int64](lastIndex * 4 + 9)
  treeArg = newSeq[int](lastIndex * 4 + 9)
  treeLazy = newSeq[int](lastIndex * 4 + 9)
  buildTree(1, 0, lastIndex)

  var bestVolume: int64 = -1
  var answerX = maxEdge
  var answerY = maxEdge
  var answerZ = maxEdge

  var scanIndex = 0
  while scanIndex < pointCount:
    let edgeX = points[scanIndex].coordX
    considerEdge(edgeX, bestVolume, answerX, answerY, answerZ)
    while scanIndex < pointCount and points[scanIndex].coordX == edgeX:
      insertPoint(points[scanIndex].coordY, points[scanIndex].coordZ)
      scanIndex += 1
  considerEdge(maxEdge, bestVolume, answerX, answerY, answerZ)

  outputBuffer.add $(answerX)
  outputBuffer.add ' '
  outputBuffer.add $(answerY)
  outputBuffer.add ' '
  outputBuffer.add $(answerZ)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs once per case. Points sort by x, then groups enter in x order. The final considerEdge handles X=1000000. Output waits in one buffer and flushes in blocks.

## Complexity

Reading and parsing cost O(N) in the input bytes, where N is the number of tokens. Sorting one case costs O(n log n). The sweep does n insertions at O(log^2 n) steps each, so one case costs O(n log^2 n) time.

The input buffer holds O(N) bytes. The tree arrays hold four slots per distinct y value, so O(n) space per case.

A brute search tries every X,Y,Z triple and then checks every point. That costs O(n^4) time per case, far beyond the limit.
