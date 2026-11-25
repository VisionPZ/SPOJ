# BENEFACT — The Benefactor (SPOJ)

<https://www.spoj.com/problems/BENEFACT/>

## Problem

The streets of a town form a tree, and each street has a length. Report the greatest distance between any two places, where distance is the sum of lengths along the unique route.

Input starts with the number of test cases. Each case gives the number of places, then one line per street with its two endpoints and its length. Output one line per case with that greatest distance.

The statement fixes these bounds:

| Item | Bound |
|---|---|
| Places per case | 2 to 50 000 |
| Streets per case | one fewer than the places |
| Street length | 0 to 19 999 |
| Judge time limit | 10 s |
| Judge memory limit | 1536 MB |
| Source size limit | 10 000 B |

The place count drives the design, since each case needs one pass over all places.

The statement sample, byte for byte:

```
1
6
1 2 3
2 3 4 
2 6 2
6 4 6
6 5 5
```

```
12
```

## Idea

Walk to the farthest place, then walk from that place to its farthest place. Finding the two ends of a rope works the same way: grab any point and walk to the far tip. That second distance is the answer.

The double sweep runs a depth-first search twice. Each walk visits every place once and looks at every street twice. A walk costs linear time in the place count. Checking every pair of places would build many routes, each as long as the whole tree. The double sweep avoids that work.

Two linear walks replace all pairwise routes.

## Why It Works

Four facts support the two walks.

1. The streets join every two places by exactly one route, so the graph is a tree. A walk that skips the street it came from visits each place once.
2. Street lengths are never negative. Under that condition, the farthest place from any start is an end of some longest route.
3. The second walk starts at that end. Its farthest place lies at the opposite end, and their distance is the answer.
4. Zero-length streets create ties. Every tied farthest place is still an end of a longest route, so both walks stay correct.

The program keeps these values while it walks:

| Term | Meaning |
|---|---|
| `headIndex` | first edge slot stored for a place |
| `edgeTarget` | place at the far end of an edge slot |
| `nextEdge` | next edge slot for the same starting place |
| `previousNode` | place we came from, so the walk never turns back |
| `travelDistance` | length from the sweep start to a place |
| `farthestDistance` | largest length seen during the sweep |
| `secondSweep[1]` | final answer, the length of the longest route |

Flat edge arrays keep each walk contiguous in memory.

A script traces the sample tree below.

```
sweep 1 from place 1
place   1   2   3   6   4   5
dist    0   3   7   5  11  10
farthest place 4 distance 11
sweep 2 from place 4
place   4   6   5   2   1   3
dist    0   6  11   8  11  12
farthest place 3 distance 12
```

The second walk reaches place 3 at distance 12, matching the sample answer.

## Code

**Constants.** Digit base, output block size, and the parent marker.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const noPreviousNode = -1
```

`firstDigitValue` is 48, the code of the zero character. `flushBlockBytes` is 128 KiB. `noPreviousNode` marks a place with no parent.

**Number reader.** It skips whitespace and builds integers from digit bytes.

```nim
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var parsedValue = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return parsedValue
```

`scanPos` advances through the one input buffer. `inputData` holds the whole stream. The scanner allocates no token strings, so it costs one pass over the digits.

**Sweep.** One walk from a start finds its farthest place.

```nim
proc farthestFrom(startNode: int, headIndex: seq[int], edgeTarget: seq[int], streetLength: seq[int], nextEdge: seq[int], previousNode: var seq[int], travelDistance: var seq[int64], nodeStack: var seq[int]): (int, int64) =
  var stackTop = 0
  nodeStack[stackTop] = startNode
  stackTop += 1
  previousNode[startNode] = noPreviousNode
  travelDistance[startNode] = 0
  var farthestNode = startNode
  var farthestDistance: int64 = 0
  while stackTop > 0:
    stackTop -= 1
    let currentNode = nodeStack[stackTop]
    if travelDistance[currentNode] > farthestDistance:
      farthestDistance = travelDistance[currentNode]
      farthestNode = currentNode
    var edgeCursor = headIndex[currentNode]
    while edgeCursor != noPreviousNode:
      let neighbor = edgeTarget[edgeCursor]
      if neighbor != previousNode[currentNode]:
        previousNode[neighbor] = currentNode
        travelDistance[neighbor] = travelDistance[currentNode] + int64(streetLength[edgeCursor])
        nodeStack[stackTop] = neighbor
        stackTop += 1
      edgeCursor = nextEdge[edgeCursor]
  return (farthestNode, farthestDistance)
```

`nodeStack` holds places waiting to be expanded. `previousNode` stops the walk from turning back. The loop runs once per place, and each street is examined twice.

**Bulk input.** All lines land in one string before parsing.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var headIndex: seq[int]
var edgeTarget: seq[int]
var streetLength: seq[int]
var nextEdge: seq[int]
var previousNode: seq[int]
var travelDistance: seq[int64]
var nodeStack: seq[int]
var outputBuffer = ""
```

`readLine` appends each line and a newline. `caseCount` comes from the first integer. `outputBuffer` collects answers, and the arrays survive across cases.

**Tree build.** Each street enters the flat arrays in both directions.

```nim
for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  headIndex.setLen(nodeCount + 1)
  for place in 1..nodeCount:
    headIndex[place] = noPreviousNode
  let edgeSlotCount = 2 * (nodeCount - 1)
  edgeTarget.setLen(edgeSlotCount)
  streetLength.setLen(edgeSlotCount)
  nextEdge.setLen(edgeSlotCount)
  var edgeSlot = 0
  for streetOrdinal in 1..<nodeCount:
    let firstPlace = nextInt(inputData, scanPos)
    let secondPlace = nextInt(inputData, scanPos)
    let streetLengthValue = nextInt(inputData, scanPos)
    edgeTarget[edgeSlot] = secondPlace
    streetLength[edgeSlot] = streetLengthValue
    nextEdge[edgeSlot] = headIndex[firstPlace]
    headIndex[firstPlace] = edgeSlot
    edgeSlot += 1
    edgeTarget[edgeSlot] = firstPlace
    streetLength[edgeSlot] = streetLengthValue
    nextEdge[edgeSlot] = headIndex[secondPlace]
    headIndex[secondPlace] = edgeSlot
    edgeSlot += 1
  previousNode.setLen(nodeCount + 1)
  travelDistance.setLen(nodeCount + 1)
  nodeStack.setLen(nodeCount)
```

`headIndex` stores the newest edge slot for each place. `edgeTarget`, `streetLength` and `nextEdge` share one slot index. The `setLen` calls reuse capacity rather than build new arrays.

**Two sweeps and output.** The second walk returns the diameter.

```nim
  let firstSweep = farthestFrom(1, headIndex, edgeTarget, streetLength, nextEdge, previousNode, travelDistance, nodeStack)
  let secondSweep = farthestFrom(firstSweep[0], headIndex, edgeTarget, streetLength, nextEdge, previousNode, travelDistance, nodeStack)
  outputBuffer.add $secondSweep[1]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

`firstSweep[0]` is the end found from place 1. `secondSweep[1]` is the longest route length. `outputBuffer` flushes every `flushBlockBytes` bytes, and the final write emits the tail.

## Complexity

The cost splits into four phases per case.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one pass over digits | input bytes |
| Tree build | one slot pair per street | 2(n − 1) slots |
| Two sweeps | two visits per place, two looks per street | n places and n streets |
| Output | one write per block | up to block size |

No phase rebuilds work for a single place.

Asymptotic bounds follow from the phase costs:

| Measure | Big O |
|---|---|
| Time | O(n) per case, O(t n) for t cases |
| Space | O(n) per case |

Checking all pairs costs O(n^3) in the worst case, while two walks cost O(n). The double sweep stays fast on the largest trees.
