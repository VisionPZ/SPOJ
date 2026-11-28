# COCONUTS — Coconuts (SPOJ)

<https://www.spoj.com/problems/COCONUTS/>

## Problem

Guards vote yes or no, and each guard pays one penalty for voting against a personal belief. Each friendship adds one penalty when its two guards vote differently. Find the smallest total penalty.

Input holds several test cases. A case starts with the guard count and friendship count, then one belief per guard, then one line per friendship. A line with two zeros ends the input. Output holds one minimum penalty per case.

| item | bound |
|---|---|
| guards | 2 to 300 |
| friendships | up to n(n-1)/2 |
| belief value | 0 or 1 |
| judge limit | 0.100 s, 1536 MB |

Friendships never repeat and list two distinct guards.

Sample input:

```
3 3
1 0 0
1 2
1 3
3 2
6 6
1 1 1 0 0 0
1 2
2 3
4 2
3 5
4 5
5 6
0 0
```

Sample output:

```
1
2
```

## Idea

Think of each guard as a light switch wired to a power source and a drain. Flipping a switch across the cut costs a coin, and each friendship is a spring that charges one coin when its ends land on opposite sides. This is a minimum s-t cut, so a maximum-flow routine gives the answer. Dinic's algorithm sends blocking flows in layers and stays fast on these unit capacities. Trying every voting pattern would grow as two to the power of the guard count.

## Why It Works

1. Put a guard on the source side when the vote is yes, and on the sink side when the vote is no.
2. A guard who believes yes has a unit edge from the source, so a no vote cuts it.
3. A guard who believes no has a unit edge to the sink, so a yes vote cuts it.
4. Each friendship gets one unit edge in each direction, so opposite votes cut exactly one of them.
5. The minimum cut cost equals the maximum flow value by the max-flow min-cut theorem.

| term | meaning |
|---|---|
| `addEdge` | adds a forward arc and its zero-capacity reverse arc |
| `buildLevels` | finds the next layered network by breadth-first search |
| `sendFlow` | pushes flow along one admissible layered path |
| `nodeLevel` | distance from the source in the current layer graph |
| `minimumCost` | total flow, equal to the cheapest penalty |

A script check of the first sample case uses three guards with beliefs 1, 0, 0 and friendships (1,2) and (1,3). If all guards vote no, the cut crosses only the source edge of guard one, giving 1. If the first guard votes yes, both friendship edges cross the cut, giving 2. The minimum is 1.

All capacities are integers, so the flow stays integral and the cut cost is an integer. No rounding step enters the computation.

## Code

**Input and buffering.** The hand reader loads stdin before any graph work starts.

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

Each integer is parsed from the shared input string.
Results leave through one buffered output path.

**Network storage.** Arcs live in parallel arrays, with a head index per node.

```nim
var headArc: seq[int] = @[]
var targetNode: seq[int] = @[]
var nextArc: seq[int] = @[]
var arcCapacity: seq[int] = @[]
var nodeLevel: seq[int] = @[]
var currentArc: seq[int] = @[]
var queueNodes: seq[int] = @[]
var sourceNode = 0
var sinkNode = 0

proc addEdge(startNode: int, endNode: int, capacity: int) =
  targetNode.add endNode
  arcCapacity.add capacity
  nextArc.add headArc[startNode]
  headArc[startNode] = targetNode.len - 1
  targetNode.add startNode
  arcCapacity.add 0
  nextArc.add headArc[endNode]
  headArc[endNode] = targetNode.len - 1

proc buildLevels(): bool =
  for nodeIndex in 0 .. nodeLevel.len - 1:
    nodeLevel[nodeIndex] = -1
  queueNodes.setLen 0
  nodeLevel[sourceNode] = 0
  queueNodes.add sourceNode
  var frontIndex = 0
  while frontIndex < queueNodes.len:
    let node = queueNodes[frontIndex]
    frontIndex += 1
    var arc = headArc[node]
    while arc != -1:
      let reachedNode = targetNode[arc]
      if arcCapacity[arc] > 0 and nodeLevel[reachedNode] == -1:
        nodeLevel[reachedNode] = nodeLevel[node] + 1
        queueNodes.add reachedNode
      arc = nextArc[arc]
  return nodeLevel[sinkNode] != -1
```

Every forward arc gets a reverse arc for residual flow.
The queue reuses one sequence across all breadth-first searches.

**Flow and driver.** Blocking flows are pushed until the sink becomes unreachable.

```nim
proc sendFlow(node: int, flowLimit: int): int =
  if node == sinkNode:
    return flowLimit
  while currentArc[node] != -1:
    let arc = currentArc[node]
    let reachedNode = targetNode[arc]
    if arcCapacity[arc] > 0 and nodeLevel[reachedNode] == nodeLevel[node] + 1:
      let pushed = sendFlow(reachedNode, min(flowLimit, arcCapacity[arc]))
      if pushed > 0:
        arcCapacity[arc] -= pushed
        arcCapacity[arc xor 1] += pushed
        return pushed
    currentArc[node] = nextArc[arc]
  return 0

proc minimumCost(): int =
  var totalFlow = 0
  while buildLevels():
    for nodeIndex in 0 .. currentArc.len - 1:
      currentArc[nodeIndex] = headArc[nodeIndex]
    while true:
      let pushed = sendFlow(sourceNode, high(int) div 4)
      if pushed == 0:
        break
      totalFlow += pushed
  return totalFlow

while scanPos < inputData.len:
  let guardCount = nextInt(inputData, scanPos)
  let friendCount = nextInt(inputData, scanPos)
  if guardCount == 0 and friendCount == 0:
    break
  let nodeCount = guardCount + 2
  sourceNode = 0
  sinkNode = guardCount + 1
  headArc = newSeq[int](nodeCount)
  nodeLevel = newSeq[int](nodeCount)
  currentArc = newSeq[int](nodeCount)
  targetNode = @[]
  nextArc = @[]
  arcCapacity = @[]
  for nodeIndex in 0 .. nodeCount - 1:
    headArc[nodeIndex] = -1
  for guardIndex in 0 .. guardCount - 1:
    let belief = nextInt(inputData, scanPos)
    if belief == 1:
      addEdge(sourceNode, guardIndex + 1, 1)
    else:
      addEdge(guardIndex + 1, sinkNode, 1)
  for friendIndex in 0 .. friendCount - 1:
    let firstGuard = nextInt(inputData, scanPos)
    let secondGuard = nextInt(inputData, scanPos)
    addEdge(firstGuard, secondGuard, 1)
    addEdge(secondGuard, firstGuard, 1)
  appendOutput($minimumCost())
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The current-arc array skips arcs already exhausted at a node.
The driver writes one cost per case after its flow finishes.

## Complexity

| phase | time | space |
|---|---|---|
| graph build | one pass over friendships | two arcs per entry |
| layered search | one breadth-first scan per phase | queue and level array |
| blocking flow | one depth-first scan per pushed path | current-arc array |

| measure | Big O |
|---|---|
| time per case | O(E * sqrt(V)) on this unit-capacity network |
| space | O(V + E) |

Enumerating every voting pattern would need two to the power of 300 checks for the largest cases.

The layered search keeps repeated augmentations local, so the largest cases finish quickly.
