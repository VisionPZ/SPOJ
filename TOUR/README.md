## Problem

Read several fake tournaments. Each contestant supplies a list of rivals who will certainly beat them. Count the contestants for whom the committee can arrange matches so that contestant wins. Print one integer per tournament.

| Quantity | Bound |
| --- | --- |
| Tournaments per file | not fixed |
| Contestants `n` | 1 to 1000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

A contestant wins only when no rival is guaranteed to beat them and the winning group is unique.

## Idea

Build a directed graph with an edge from each listed rival to the contestant they beat. Find the strongly connected components. If exactly one component has no incoming edge, print its size; otherwise print zero.

Kosaraju's method finds components in O(n + e) time per tournament. Checking every ordering of matches would be exponential.

## Why It Works

A listed rival is a guaranteed winner over that contestant, so the edge points from the rival to the victim. Unlisted pairs are not fixed and do not create edges. Contestants in one strongly connected component can eliminate each other in any order, so they behave as one group.

The group with no incoming edge has no guaranteed winner above it. When two such groups exist, neither can eliminate the other with certainty, so no contestant is guaranteed a possible tournament. The condensation of the graph is acyclic, so its source component is unique exactly when one winning group exists.

## Code

Input is read once, and a digit scanner supplies the integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

Every number is non-negative, so the scanner needs no sign branch. Parsing one number visits each digit once.

The two depth-first passes implement Kosaraju's method with explicit stacks.

```nim
proc depthFirstOrder(startVertex: int, adjacency: seq[seq[int]],
                     visited: var seq[bool], finishOrder: var seq[int]) =
  var stackVertices = @[startVertex]
  var stackIndices = @[0]
  visited[startVertex] = true
  while stackVertices.len > 0:
    let currentVertex = stackVertices[^1]
    var k = stackIndices[^1]
    if k < adjacency[currentVertex].len:
      stackIndices[^1] = k + 1
      let neighbor = adjacency[currentVertex][k]
      if not visited[neighbor]:
        visited[neighbor] = true
        stackVertices.add neighbor
        stackIndices.add 0
    else:
      finishOrder.add currentVertex
      stackVertices.setLen(stackVertices.len - 1)
      stackIndices.setLen(stackIndices.len - 1)

proc assignComponents(startVertex: int, adjacency: seq[seq[int]],
                      componentOf: var seq[int], i: int) =
  var stackVertices = @[startVertex]
  componentOf[startVertex] = i
  while stackVertices.len > 0:
    let currentVertex = stackVertices.pop
    for neighbor in adjacency[currentVertex]:
      if componentOf[neighbor] < 0:
        componentOf[neighbor] = i
        stackVertices.add neighbor
```

The first pass orders vertices by finishing time. The second pass walks the reversed graph in that order, which labels each component once. Explicit stacks avoid deep recursion at 1000 contestants.

The driver builds both graphs and counts the source components.

```nim
let caseCount = nextInt(inputData, i)
for j in 1..caseCount:
  let participantCount = nextInt(inputData, i)
  var adjacency = newSeq[seq[int]](participantCount)
  var reverseAdjacency = newSeq[seq[int]](participantCount)
  for k in 0..<participantCount:
    adjacency[k] = @[]
    reverseAdjacency[k] = @[]
  for k in 0..<participantCount:
    let betterCount = nextInt(inputData, i)
    for _ in 0..<betterCount:
      let l = nextInt(inputData, i) - 1
      adjacency[l].add k
      reverseAdjacency[k].add l
  var visited = newSeq[bool](participantCount)
  var finishOrder = newSeq[int]()
  for k in 0..<participantCount:
    if not visited[k]:
      depthFirstOrder(k, adjacency, visited, finishOrder)
  var componentOf = newSeq[int](participantCount)
  for k in 0..<participantCount:
    componentOf[k] = -1
  var componentTotal = 0
  for l in countdown(finishOrder.len - 1, 0):
    let k = finishOrder[l]
    if componentOf[k] < 0:
      assignComponents(k, reverseAdjacency, componentOf, componentTotal)
      componentTotal += 1
  var inDegree = newSeq[int](componentTotal)
  for k in 0..<participantCount:
    for l in adjacency[k]:
      let sourceComponent = componentOf[k]
      let targetComponent = componentOf[l]
      if sourceComponent != targetComponent:
        inDegree[targetComponent] += 1
  var sourceComponentCount = 0
  var l = -1
  for k in 0..<componentTotal:
    if inDegree[k] == 0:
      sourceComponentCount += 1
      l = k
  var winnerCount = 0
  if sourceComponentCount == 1:
    for k in 0..<participantCount:
      if componentOf[k] == l:
        winnerCount += 1
  appendOutput($winnerCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Contestant numbers are one-based in the input and zero-based in the arrays. An edge crosses components only when the rival is not in the same group. Output is written in blocks, not once per case.

## Complexity

Building both graphs takes O(n + e) time and space. Each depth-first pass costs O(n + e), and the indegree count costs O(e). Total time and space per tournament are O(n + e). Checking every possible match schedule would take exponential time.
