# RELATS1 — Relations (SPOJ)

<https://www.spoj.com/problems/RELATS1/>

## Problem

Each data set describes a directed graph. Every edge carries `<`, `>`, or `=`.
Assign an integer from 0 to k to each vertex so every edge label holds.
Print the smallest k that works, or NO when no k works.

Bounds and judge limit:

| item | bound |
|---|---|
| data sets | at most 10 |
| vertices | 1 to 1000 |
| edges | 0 to 10000 |
| labels | -1, 0, 1 |
| judge limit | 5 s, 1536 MB |

The graph has no self-loops and no parallel edges. The four sample answers are 2, NO, 1 and 0.

## Idea

Rewrite each label as a lower bound. A `<` edge from u to v means value[v] is at
least value[u] + 1. A `>` edge puts the +1 on u instead. An `=` edge forces equal
values, so merge those vertices into one group.

Strict edges between the merged groups form a directed graph. A cycle in that
graph makes the labels impossible. Otherwise the answer is the longest path
length, and an isolated group has length 0.

Cost per item: one union for an equality edge, one stored edge for a strict edge,
and one queue step per group. Trying each candidate k repeats that whole walk for
every candidate.

## Why It Works

Each edge becomes `value[target] >= value[source] + weight`. A `<` edge has weight
1 toward its right vertex. A `>` edge has weight 1 toward its left vertex. An `=`
edge gives two edges of weight 0.

A virtual source has value 0 and reaches every group with a weight-0 edge. The
smallest feasible value of a group is the heaviest path ending there. A cycle
with a strict edge forces `value[x] >= value[x] + 1`, so no labeling exists.

Equality edges have weight 0 in both directions. Merging their connected groups
removes those zero cycles and keeps every strict constraint. Kahn's ordering
then detects a cycle and computes the longest path in the same pass.

The first sample case works as follows:

| group | vertices | indegree | longest path |
|---|---|---|---|
| 1 | 1 | 0 | 0 |
| 2 | 2, 3 | 1 | 1 |
| 3 | 4 | 2 | 2 |

The queue visits groups 1, 2, 3. The answer is 2.

The scanner accepts a minus sign, since input labels include -1.

## Code

Constants fix the output block size and the byte value of a digit.

```nim
const flushBlockBytes = 1 shl 18
const digitZeroValue = 48
```

`nextInt` skips separators and reads an optional minus sign. It builds the value
from digit bytes and moves `i` forward.

```nim
proc nextInt(inputData: string, i: var int): int =
  var byteCount = inputData.len
  while i < byteCount and (inputData[i] < '0' or inputData[i] > '9') and inputData[i] != '-':
    i = i + 1
  var signValue = 1
  if i < byteCount and inputData[i] == '-':
    signValue = -1
    i = i + 1
  var value = 0
  while i < byteCount and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - digitZeroValue
    i = i + 1
  return signValue * value
```

`i` is a `var` parameter, so its position survives across calls. No token
string is created.

`findRoot` walks to the group root and shortens the path on the way back.

```nim
proc findRoot(parent: var seq[int], i: int): int =
  var root = i
  while parent[root] != root:
    root = parent[root]
  var j = i
  while parent[j] != root:
    var nextVertex = parent[j]
    parent[j] = root
    j = nextVertex
  return root
```

Each equality edge needs one root lookup for each endpoint.

`readLine` appends every input line to one buffer. The scanner then reads the
case count, the vertex count and the edge count from that buffer.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string

for j in 1 .. caseCount:
  var vertexCount = nextInt(inputData, i)
  var edgeCount = nextInt(inputData, i)
```

Equality edges merge their endpoints. Strict edges are stored as source and
target, and a `>` label swaps the pair.

```nim
  var parent = newSeq[int](vertexCount + 1)
  for k in 1 .. vertexCount:
    parent[k] = k
  var strictFrom = newSeq[int](edgeCount)
  var strictTo = newSeq[int](edgeCount)
  var strictCount = 0
  for k in 0 ..< edgeCount:
    var fromVertex = nextInt(inputData, i)
    var toVertex = nextInt(inputData, i)
    var edgeLabel = nextInt(inputData, i)
    if edgeLabel == 0:
      var fromRoot = findRoot(parent, fromVertex)
      var toRoot = findRoot(parent, toVertex)
      if fromRoot != toRoot:
        parent[toRoot] = fromRoot
    else:
      strictFrom[strictCount] = fromVertex
      strictTo[strictCount] = toVertex
      if edgeLabel > 0:
        swap strictFrom[strictCount], strictTo[strictCount]
      strictCount = strictCount + 1
```

`strictCount` holds the number of stored strict edges.

Every vertex gets a group number. Each strict edge becomes one adjacency entry
between groups.

```nim
  var componentOf = newSeq[int](vertexCount + 1)
  var componentCount = 0
  for k in 1 .. vertexCount:
    var componentRoot = findRoot(parent, k)
    if componentOf[componentRoot] == 0:
      componentCount = componentCount + 1
      componentOf[componentRoot] = componentCount
    componentOf[k] = componentOf[componentRoot]

  var adjacency = newSeq[seq[int]](componentCount + 1)
  var inDegree = newSeq[int](componentCount + 1)
  for k in 0 ..< strictCount:
    var sourceComponent = componentOf[strictFrom[k]]
    var targetComponent = componentOf[strictTo[k]]
    adjacency[sourceComponent].add targetComponent
    inDegree[targetComponent] = inDegree[targetComponent] + 1
```

`componentOf` maps each original vertex to its group. `inDegree` counts incoming
strict edges.

Groups without an incoming strict edge start the queue. The loop relaxes each
group's longest path and enqueues groups whose indegree reaches zero.

```nim
  var queue = newSeq[int](componentCount + 1)
  var queueHead = 0
  var queueTail = 0
  for k in 1 .. componentCount:
    if inDegree[k] == 0:
      queue[queueTail] = k
      queueTail = queueTail + 1

  var longestPath = newSeq[int](componentCount + 1)
  var maxLongestPath = 0
  var processedCount = 0
  while queueHead < queueTail:
    var currentComponent = queue[queueHead]
    queueHead = queueHead + 1
    processedCount = processedCount + 1
    if longestPath[currentComponent] > maxLongestPath:
      maxLongestPath = longestPath[currentComponent]
    for neighbor in adjacency[currentComponent]:
      if longestPath[neighbor] < longestPath[currentComponent] + 1:
        longestPath[neighbor] = longestPath[currentComponent] + 1
      inDegree[neighbor] = inDegree[neighbor] - 1
      if inDegree[neighbor] == 0:
        queue[queueTail] = neighbor
        queueTail = queueTail + 1
```

`processedCount` counts finished groups, so a cycle leaves some groups behind.

An unprocessed group means NO. Otherwise `maxLongestPath` is the smallest k.
Output waits in one buffer until it reaches `flushBlockBytes`.

```nim
  if processedCount < componentCount:
    outputBuffer.add "NO\n"
  else:
    outputBuffer.add $maxLongestPath
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

The final write covers the tail after the last block.

## Complexity

Costs for one data set with vertex count n and edge count m:

| phase | time | space |
|---|---|---|
| input scan | one pass over the buffer | input bytes |
| equality merge | one root lookup per endpoint | n integers |
| strict edges | one append and one indegree update per edge | m integers |
| queue pass | one relax per edge, one step per group | n integers |
| output | one write per 256 KiB block | 256 KiB |

At the largest case the queue pass handles 1000 groups and 10000 edges.

Asymptotic form:

| measure | Big O |
|---|---|
| time | O(n + m) per data set |
| space | O(n + m) per data set |

Trying each k from 0 upward repeats the O(n + m) check O(n) times.
