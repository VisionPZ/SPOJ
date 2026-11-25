# SHOP — Shopping (SPOJ)
<https://www.spoj.com/problems/SHOP/>

## Problem

A grid holds shelves, a start square S, a destination D, and open squares whose digits give crossing time in seconds. Find the minimum time to reach D from S using horizontal and vertical moves.

Input: pairs of integers w and h, ending with 0 0. Each case then has h lines of w characters. `X` is a shelf, `S` the start, `D` the goal, and a digit 1 to 9 the crossing cost. Output: one integer per case, the minimum seconds.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Width w | at most 25 |
| Height h | at most 25 |
| Square cost | 1 to 9 seconds |
| Test cases | until the 0 0 line |
| Judge time limit | 3000 ms |
| Judge memory limit | 1536 MB |

A route always exists, so no failure case is needed.

The sample input:

```
4 3
X1S3
42X4
X1D2

5 5
S5213
2X2X5
51248
4X4X2
1445D

0 0
```

The sample output:

```
4
23
```

## Idea

Spread ripples from the entrance across the grid, like water finding the fastest path around rocks. Each ripple costs an extra second per square crossed. The first ripple reaching the counter gives the minimum time.

The program uses Dijkstra with a bucket queue, also called Dial's algorithm. Costs range from 1 to 9, so a bucket index is the distance itself. The largest useful distance is 625 times 9, so buckets are cheap and fixed. Each settled cell relaxes at most four neighbors. A cell enters a bucket once per improved distance, and cells are removed from the front. A priority-queue heap would do the same job with a logarithm per step.

Small integer costs let buckets replace a heap.

## Why It Works

Four facts carry the program.

1. All step costs are positive integers, so Dijkstra settles cells in nondecreasing distance. The first pop of the goal is therefore optimal.
2. A bucket holds every cell at one distance. Scanning buckets from low to high reproduces Dijkstra's order without comparisons.
3. Costs are at most 9 and cells are at most 625, so no distance exceeds 5625. The bucket count of 5627 covers every reachable distance.
4. A stale entry is skipped when its stored distance differs from the current bucket index. That check replaces a decrease-key operation.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `bucketHead` | first queued node at each distance |
| `bucketVertex` | cell stored in one queue node |
| `distanceValue` | best known cost to reach a cell |
| `touchedBuckets` | bucket list that needs clearing next case |

Every distance is an integer, so no rounding occurs.

A script traces the first sample grid from S at row 0, column 2.

```text
start distance 0 at S (0,2)
step to (0,1) cost 1 -> distance 1
step to (1,1) cost 2 -> distance 3
step to (2,1) cost 1 -> distance 4
step to D (2,2) cost 0 -> distance 4
first pop of D gives 4
```

The answer is 4, matching the sample. The goal square itself adds no cost.

## Code

**Constants and reader.** The whole stream enters one buffer.

```nim
import sequtils

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const maxGridCells = 25 * 25
const maxStepCost = 9
const bucketTotal = maxGridCells * maxStepCost + 2
const nodeCapacity = maxGridCells * 4 + 32
const unreachableCost = 1000000000

var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc skipWhitespace() =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1

proc readInteger(): int =
  skipWhitespace()
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (int(inputData[i]) - firstDigitValue)
    i = i + 1
  return value
```

`bucketTotal` is 5627, one past the largest possible distance. `readInteger` skips blank lines between cases.

**Bucket structures.** Fixed arrays hold queued cells.

```nim
var gridCells: seq[char]
var distanceValue: seq[int]
var bucketHead = repeat(-1, bucketTotal)
var bucketVertex = newSeq[int](nodeCapacity)
var bucketNext = newSeq[int](nodeCapacity)
var touchedBuckets: seq[int]
var nodeTotal = 0

proc enqueueNode(i: int, j: int) =
  if i >= bucketTotal or nodeTotal >= nodeCapacity:
    return
  if bucketHead[i] == -1:
    touchedBuckets.add i
  bucketNext[nodeTotal] = bucketHead[i]
  bucketHead[i] = nodeTotal
  bucketVertex[nodeTotal] = j
  nodeTotal = nodeTotal + 1

proc resetBuckets() =
  for i in touchedBuckets:
    bucketHead[i] = -1
  touchedBuckets.setLen 0
```

`enqueueNode` prepends a node to one bucket in O(1). `resetBuckets` clears only touched buckets, not all 5627.

**Neighbor relaxation.** Shelves are skipped immediately.

```nim
proc tryRelax(neighborCell: int, currentDistance: int) =
  let cellChar = gridCells[neighborCell]
  if cellChar == 'X':
    return
  var stepCost = 0
  if cellChar >= '1' and cellChar <= '9':
    stepCost = int(cellChar) - firstDigitValue
  let candidateDistance = currentDistance + stepCost
  if candidateDistance < distanceValue[neighborCell]:
    distanceValue[neighborCell] = candidateDistance
    enqueueNode(candidateDistance, neighborCell)
```

`S`, `D` and `X` all cost zero to enter, but shelves return early. A cell is enqueued only when its distance improves.

**Dijkstra sweep.** Buckets are scanned in increasing distance.

```nim
proc shortestPathCost(width: int, height: int, startCell: int, targetCell: int): int =
  let cellCount = width * height
  distanceValue.setLen(cellCount)
  for j in 0 .. cellCount - 1:
    distanceValue[j] = unreachableCost
  nodeTotal = 0
  resetBuckets()
  distanceValue[startCell] = 0
  enqueueNode(0, startCell)
  var currentDistance = 0
  while true:
    while true:
      let i = bucketHead[currentDistance]
      if i < 0:
        break
      bucketHead[currentDistance] = bucketNext[i]
      let settledCell = bucketVertex[i]
      if distanceValue[settledCell] != currentDistance:
        continue
      if settledCell == targetCell:
        return currentDistance
      let j = settledCell div width
      let k = settledCell mod width
      if j > 0:
        tryRelax(settledCell - width, currentDistance)
      if j < height - 1:
        tryRelax(settledCell + width, currentDistance)
      if k > 0:
        tryRelax(settledCell - 1, currentDistance)
      if k < width - 1:
        tryRelax(settledCell + 1, currentDistance)
    currentDistance = currentDistance + 1
    while currentDistance < bucketTotal and bucketHead[currentDistance] == -1:
      currentDistance = currentDistance + 1
    if currentDistance >= bucketTotal:
      return unreachableCost
```

The four boundary checks keep moves inside the grid. The stale-entry test skips old queue nodes. Returning at the goal's first pop is safe because bucket order is Dijkstra order.

**Driver.** Each grid produces one line.

```nim
var outputBuffer: string
var width = readInteger()
var height = readInteger()
while width != 0 or height != 0:
  let cellCount = width * height
  gridCells.setLen(cellCount)
  var startCell = -1
  var targetCell = -1
  for j in 0 .. height - 1:
    let rowStart = j * width
    skipWhitespace()
    for k in 0 .. width - 1:
      let cellChar = inputData[i]
      i = i + 1
      gridCells[rowStart + k] = cellChar
      if cellChar == 'S':
        startCell = rowStart + k
      if cellChar == 'D':
        targetCell = rowStart + k
  let answer = shortestPathCost(width, height, startCell, targetCell)
  outputBuffer.add $answer
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  width = readInteger()
  height = readInteger()
stdout.write outputBuffer
```

`skipWhitespace` skips the blank line before each grid. The 0 0 pair ends the loop. The final write emits the remaining bytes.

## Complexity

Each case settles at most 625 cells and scans 5627 buckets.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(B) for B bytes | B bytes |
| Grid load | O(w times h) | O(w times h) |
| Dijkstra | O(bucketTotal + w times h) | O(bucketTotal) |
| Output | O(1) per case | one block |

`bucketTotal` is 5627, and w times h is at most 625.

| Measure | Big O |
| --- | --- |
| Time | O(5627 + w times h) per case |
| Space | O(w times h + 5627) |

A binary-heap Dijkstra costs O(w h log(w h)) per case, which is larger here.
