# OFFSTRAT — Problem Offensive Strategy (SPOJ)
<https://www.spoj.com/problems/OFFSTRAT/>

## Problem

Check whether a list of passes only moves play toward the enemy goal line and lets every listed position reach the goal. Print `Yes` for a strongly offensive strategy and `No` otherwise.

Input starts with the test count. Each test gives even field dimensions `W H`, then `M` passes with four integers `x0 y0 x1 y1`. The goal sits at `(W, H/2)`.

| item | bound |
|---|---|
| tests | up to 20 |
| width W | even, 2 to 100 |
| height H | even, 2 to 100 |
| passes M | 1 to 999999 |
| judge limit | 1238 ms, 1536 MB |

A pass may not lower the x coordinate. All pass positions must reach the goal through listed passes.

Sample input:

```
2

2 2 1
0 1 2 1

2 2 4
0 1 2 1
0 0 1 1
0 2 1 1
1 1 2 1

```

Sample output:

```
Yes
Yes
```

## Idea

Treat the passes as one-way roads, like a fleet of trucks that never drives back downhill. Every road must keep the truck the same distance or closer to the goal line. Then walk backwards from the goal to see which positions can arrive there.

Reverse adjacency stores each pass only once. A single breadth-first search from the goal marks every position with a route to it. The whole test costs one sweep over the passes plus one sweep over the marked positions.

## Why It Works

1. Distance from `(x, y)` to the goal line `x = W` equals `W - x`.
2. A pass never increases that distance exactly when `x1 >= x0`.
3. A position reaches the goal if a chain of passes ends at `(W, H/2)`.
4. Reversing every pass turns that chain into a path from the goal to the position.
5. A breadth-first search over reverse passes finds all positions with such a path.

| term | meaning |
|---|---|
| `rowLength` | stride used to pack a field position into one integer |
| `goalSite` | packed index of the goal point |
| `reverseHead` | first reverse pass leaving each position |
| `usedSite` | whether a position occurs in any pass |
| `reachable` | whether a position can reach the goal |

In the first sample test, the pass runs from `(0, 1)` to `(2, 1)`. The endpoint is the goal, so both positions pass. In the second test, every pass either enters the goal or enters `(1, 1)`, which then enters the goal.

## Code

**Input and helpers.** The scanner reads integers from one buffer, and each answer is queued.

```nim
const flushBlockBytes = 1 shl 17
const emptyEdge = 0

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

proc answerText(isStrong: bool): string =
  if isStrong:
    return "Yes"
  return "No"
```

Blank lines need no special handling.
The sentinel zero ends each reverse edge chain.
The output buffer flushes only when full.

**Read the passes.** Each pass is checked and stored in reverse form.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0 .. caseCount - 1:
  let fieldWidth = nextInt(inputData, scanPos)
  let fieldHeight = nextInt(inputData, scanPos)
  let passCount = nextInt(inputData, scanPos)
  let rowLength = fieldHeight + 1
  let siteCount = (fieldWidth + 1) * rowLength
  let goalSite = fieldWidth * rowLength + fieldHeight div 2
  var reverseHead = newSeq[int](siteCount)
  var edgeFrom = newSeq[int](passCount + 1)
  var edgeNext = newSeq[int](passCount + 1)
  var usedSite = newSeq[bool](siteCount)
  var isStrong = true
  var edgeIndex = 0
  for passNumber in 0 .. passCount - 1:
    let startX = nextInt(inputData, scanPos)
    let startY = nextInt(inputData, scanPos)
    let endX = nextInt(inputData, scanPos)
    let endY = nextInt(inputData, scanPos)
    if endX < startX:
      isStrong = false
    let startSite = startX * rowLength + startY
    let endSite = endX * rowLength + endY
    usedSite[startSite] = true
    usedSite[endSite] = true
    edgeIndex += 1
    edgeFrom[edgeIndex] = startSite
    edgeNext[edgeIndex] = reverseHead[endSite]
    reverseHead[endSite] = edgeIndex
```

Packing a position as `x * rowLength + y` avoids pair keys.
A backward pass marks the strategy invalid but is still stored.
Both endpoints are recorded for the final check.

**Search backwards.** The queue expands reverse passes from the goal.

```nim
  var reachable = newSeq[bool](siteCount)
  var queue = newSeq[int](siteCount)
  var queueHead = 0
  var queueTail = 0
  reachable[goalSite] = true
  queue[queueTail] = goalSite
  queueTail += 1
  while queueHead < queueTail:
    let currentSite = queue[queueHead]
    queueHead += 1
    var edgeCursor = reverseHead[currentSite]
    while edgeCursor != emptyEdge:
      let previousSite = edgeFrom[edgeCursor]
      if not reachable[previousSite]:
        reachable[previousSite] = true
        queue[queueTail] = previousSite
        queueTail += 1
      edgeCursor = edgeNext[edgeCursor]
```

Each position enters the queue at most once.
The queue holds packed positions, not coordinate pairs.
Unreachable positions stay false after the search ends.

**Final check.** Every used position must appear in the reachable set.

```nim
  if isStrong:
    for siteIndex in 0 .. siteCount - 1:
      if usedSite[siteIndex] and not reachable[siteIndex]:
        isStrong = false
        break
  appendOutput(answerText(isStrong))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A failed monotonicity check skips the scan.
One answer line is emitted per test.
The final flush writes all buffered lines at once.

## Complexity

Each pass is read, checked and linked once.

| phase | time | space |
|---|---|---|
| pass reading | one pass over M passes | two edge arrays |
| reverse search | one visit per reachable site | queue and mark arrays |
| final check | one pass over field sites | no extra space |

| measure | Big O |
|---|---|
| time per test | O(M + W*H) |
| space per test | O(M + W*H) |

Testing each position with its own search would cost O(M * W*H) time.
The single reverse search gives the same answer in linear time.
