# BYTESE1 — Lucius Dungeon (SPOJ)

<https://www.spoj.com/problems/BYTESE1/>

## Problem

Find the quickest route from the top-left room to Hermione's room, where entering a room costs the time to defeat its guards. If that quickest time fits before the bomb, print YES and the spare seconds; otherwise print NO.

The first line holds the test count K. Each case gives rows M and columns N, then M lines of single-digit guard times, then the target row, target column and bomb time T. YES cases print two lines; NO cases print one.

| item | bound |
|---|---|
| test cases K | 1 to 20 |
| rows M, columns N | 1 to 100 |
| guard time per room | single digit |
| bomb time T | not bounded in the statement |
| judge limit | 1000 ms, 1536 MB |

The grid size sets the number of rooms to relax.

Sample input:

```
2
4 3 
2 3 2
2 5 1
5 3 1
3 1 1
4 2 15
2 2
1 2
1 1
2 2 2
```

Sample output:

```
YES
4
NO
```

## Idea

Treat each room as a junction whose entry fee is its guard time, then find the cheapest route with Dijkstra's algorithm, like picking the shortest toll road through a city. Every move takes no extra time, so edge weight equals the destination fee. A binary heap always expands the room with the smallest known arrival time. Scanning all paths would grow exponentially with the grid.

| step | cost |
|---|---|
| push or pop one heap entry | logarithmic in rooms |
| relax four neighbours | constant per room |
| total | O(M N log(M N)) per case |

The heap size drives the per-room cost.

## Why It Works

1. Arriving at a room requires paying that room's guard time once, including the starting room and the target room.
2. Every route uses at least one room, so arrival times stay non-negative and Dijkstra applies.
3. When a room is popped with its smallest tentative time, that time is final.
4. Relaxing the four orthogonal neighbours considers every possible next step.
5. The bomb deadline compares against the final target time, and the spare equals T minus that time.

| term | meaning |
|---|---|
| `guardTimes` | fee paid on entering each room |
| `distances` | smallest known arrival time per room |
| `heap` | binary heap of encoded time and room |
| `bombTime` | deadline for reaching the target |

The table links each array to its role in the search.

A script-generated trace for the first sample case:

```
route (1,1) -> (1,2) -> (1,3) -> (2,3) -> (3,3) -> (4,3) -> (4,2)
fees   2       3       2       1       1       1       1
total  2 + 3 + 2 + 1 + 1 + 1 + 1 = 11
spare  15 - 11 = 4
```

The trace matches the sample's YES and spare of 4.

## Code

**Hand scanner and buffered output.** One read pass loads each case, and one string buffers every answer line.

```nim
const flushBlockBytes = 1 shl 17
const unreachableTime = 1 shl 29

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
```

The scanner skips the trailing space after the sample header.
The buffer flushes after 131072 bytes, not per line.
All cases share these helpers.

**Binary heap.** Two sift operations keep the smallest encoded room at the front.

```nim
proc heapPush(heap: var seq[int], encodedValue: int) =
  heap.add encodedValue
  var childIndex = heap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heap[parentIndex] <= heap[childIndex]:
      break
    let parentValue = heap[parentIndex]
    heap[parentIndex] = heap[childIndex]
    heap[childIndex] = parentValue
    childIndex = parentIndex

proc heapPop(heap: var seq[int]): int =
  let smallestValue = heap[0]
  let lastValue = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len > 0:
    heap[0] = lastValue
    var parentIndex = 0
    while true:
      let leftIndex = 2 * parentIndex + 1
      if leftIndex >= heap.len:
        break
      let rightIndex = leftIndex + 1
      var smallerIndex = leftIndex
      if rightIndex < heap.len and heap[rightIndex] < heap[leftIndex]:
        smallerIndex = rightIndex
      if heap[parentIndex] <= heap[smallerIndex]:
        break
      let parentValue = heap[parentIndex]
      heap[parentIndex] = heap[smallerIndex]
      heap[smallerIndex] = parentValue
      parentIndex = smallerIndex
  return smallestValue
```

Sift-up moves a new entry toward the root.
Sift-down restores order after removing the root.
Each entry stores its time multiplied by the room count plus its room index.

**Shortest route.** Stale heap entries are discarded, and the target stops the search early.

```nim
proc shortestTime(rows: int, cols: int, guardTimes: seq[int], targetIndex: int): int =
  let nodeCount = rows * cols
  var distances = newSeq[int](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    distances[nodeIndex] = unreachableTime
  var heap = newSeq[int]()
  let startEncoded = guardTimes[0] * nodeCount
  distances[0] = guardTimes[0]
  heapPush(heap, startEncoded)
  let deltaRows = [-1, 1, 0, 0]
  let deltaCols = [0, 0, -1, 1]
  while heap.len > 0:
    let encodedValue = heapPop(heap)
    let nodeIndex = encodedValue mod nodeCount
    let arrivalTime = encodedValue div nodeCount
    if arrivalTime != distances[nodeIndex]:
      continue
    if nodeIndex == targetIndex:
      break
    let currentRow = nodeIndex div cols
    let currentCol = nodeIndex mod cols
    for directionIndex in 0 .. 3:
      let nextRow = currentRow + deltaRows[directionIndex]
      let nextCol = currentCol + deltaCols[directionIndex]
      if nextRow < 0 or nextRow >= rows or nextCol < 0 or nextCol >= cols:
        continue
      let nextIndex = nextRow * cols + nextCol
      let nextTime = arrivalTime + guardTimes[nextIndex]
      if nextTime < distances[nextIndex]:
        distances[nextIndex] = nextTime
        heapPush(heap, nextTime * nodeCount + nextIndex)
  return distances[targetIndex]
```

The start room pays its own fee before any move.
Each room improves at most when a cheaper route reaches it.
The four direction arrays define the orthogonal neighbours.

**Case loop.** Each case compares the route time with the deadline and writes one answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rows = nextInt(inputData, scanPos)
  let cols = nextInt(inputData, scanPos)
  var guardTimes = newSeq[int](rows * cols)
  for cellIndex in 0 .. rows * cols - 1:
    guardTimes[cellIndex] = nextInt(inputData, scanPos)
  let targetRow = nextInt(inputData, scanPos) - 1
  let targetCol = nextInt(inputData, scanPos) - 1
  let bombTime = nextInt(inputData, scanPos)
  let targetIndex = targetRow * cols + targetCol
  let neededTime = shortestTime(rows, cols, guardTimes, targetIndex)
  if neededTime <= bombTime:
    appendOutput("YES\n")
    appendOutput($(bombTime - neededTime))
    outputBuffer.add '\n'
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Target coordinates are converted from one-based to zero-based.
A route exactly at the deadline still counts as a rescue.
A final flush writes any partial buffer.

## Complexity

Each case relaxes four neighbours per settled room, with heap operations on every improvement.

| phase | time | space |
|---|---|---|
| input read | one pass over room fees | one input string |
| Dijkstra | M N log(M N) worst case | room arrays and heap |
| output | one write per block | block buffer |

Heap work dominates the run on large grids.

| measure | Big O |
|---|---|
| time | O(M N log(M N)) per case |
| space | O(M N) |

Enumerating routes would take exponential time, so the heap search gives the practical bound.
