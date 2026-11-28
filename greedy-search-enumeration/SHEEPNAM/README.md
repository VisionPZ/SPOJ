# SHEEPNAM — Nam The Sheep Watcher (SPOJ)

<https://www.spoj.com/problems/SHEEPNAM/>

## Problem

Nam and Ryan ride bikes from their university at node X to a sheep field at node Y. The trail is a tree of n crossroads, so exactly one route connects the two nodes. Report the total riding time on that route.

Input starts with n, X, and Y. The next n-1 lines each give two node numbers and the time along that undirected road. Output one integer, the travel time from X to Y.

| item | bound |
|---|---|
| nodes n | at most 100000 |
| road time Ti | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The unique path in a tree means a single traversal from X finds the answer.

Sample input:

```
6 2 6
1 2 2
2 3 1
2 4 5
4 6 2
4 5 4
```

Sample output:

```
7
```

The route 2 to 4 to 6 costs 5 + 2 = 7.

## Idea

A tree has one path between two nodes, like a single corridor between two rooms. Walk that corridor once from X and stop on reaching Y, adding the road times as you go.

The algorithm is a breadth-first traversal over an adjacency list, stopping early at Y. Each road is inspected once from each endpoint, so the cost is O(n). Recomputing all-pairs distances would cost O(n^3) and waste the tree structure.

## Why It Works

1. A tree with n nodes has n-1 roads and one path between any two nodes.
2. Starting from X, the traversal reaches each node by that unique path.
3. The stored distance at a node equals the sum of road times on the path from X.
4. The traversal stops at Y, whose stored distance is the required time.
5. Times up to 1e9 per road need int64 for the running sum.

| term | meaning |
|---|---|
| `head` | first outgoing edge index for each node |
| `target` | far endpoint of each directed edge |
| `weight` | travel time stored for each directed edge |
| `distances` | accumulated time from X to each visited node |
| `queue` | nodes waiting to be expanded |

The queue processes nodes in discovery order, and each node is enqueued once.

The sample trace from the generator is:

```
from X=2: reach 1 (2), 3 (1), 4 (5)
from 4:   reach 6 (5+2=7), 5 (5+4=9)
target Y=6 -> 7
```

The trace matches the sample output.

## Code

**Input and helpers.** The reader loads stdin once and sets up block-buffered output.

```nim
const flushBlockBytes = 1 shl 17

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

The hand scanner ignores line breaks and extra spaces.
Each road time is read as an integer and widened later.
Output uses one shared buffer with block flushes.

**Tree storage.** Each road is stored twice, once in each direction.

```nim
let nodeCount = nextInt(inputData, scanPos)
let startNode = nextInt(inputData, scanPos)
let targetNode = nextInt(inputData, scanPos)
let edgeCapacity = 2 * (nodeCount - 1)
var head = newSeq[int](nodeCount + 1)
for nodeIndex in 0 .. nodeCount:
  head[nodeIndex] = -1
var target = newSeq[int](edgeCapacity)
var weight = newSeq[int64](edgeCapacity)
var nextEdge = newSeq[int](edgeCapacity)
var edgeIndex = 0
for roadIndex in 0 .. nodeCount - 2:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  let roadTime = int64(nextInt(inputData, scanPos))
  target[edgeIndex] = secondNode
  weight[edgeIndex] = roadTime
  nextEdge[edgeIndex] = head[firstNode]
  head[firstNode] = edgeIndex
  edgeIndex += 1
  target[edgeIndex] = firstNode
  weight[edgeIndex] = roadTime
  nextEdge[edgeIndex] = head[secondNode]
  head[secondNode] = edgeIndex
  edgeIndex += 1
```

Adjacency arrays avoid nested sequences and keep memory linear.
A -1 head marks a node with no stored edge yet.
Times are int64 from the moment they are parsed.

**Traversal and output.** The walk from X stops as soon as Y is reached.

```nim
var distances = newSeq[int64](nodeCount + 1)
for nodeIndex in 0 .. nodeCount:
  distances[nodeIndex] = -1
var queue = newSeq[int](nodeCount + 1)
var queueStart = 0
var queueEnd = 0
queue[queueEnd] = startNode
queueEnd += 1
distances[startNode] = 0
while queueStart < queueEnd and queue[queueStart] != targetNode:
  let currentNode = queue[queueStart]
  queueStart += 1
  var currentEdge = head[currentNode]
  while currentEdge != -1:
    let neighbour = target[currentEdge]
    if distances[neighbour] == -1:
      distances[neighbour] = distances[currentNode] + weight[currentEdge]
      queue[queueEnd] = neighbour
      queueEnd += 1
    currentEdge = nextEdge[currentEdge]
appendOutput($distances[targetNode])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A distance of -1 marks a node that has not been seen.
The loop breaks early at Y instead of scanning the whole tree.
The single answer is written after the walk ends.

## Complexity

The work splits into parsing, traversal, and output.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| adjacency build | two entries per road | O(n) edge arrays |
| traversal | one visit per node up to Y | O(n) queue and distances |
| output | one line | block buffer |

Parsing and traversal are both linear in the node count.

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(n) |

An all-pairs method would take O(n^3) time. Use the tree property and stop after one walk.
