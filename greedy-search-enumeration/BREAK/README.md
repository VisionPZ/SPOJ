# BREAK — Breaking in (SPOJ)

<https://www.spoj.com/problems/BREAK/>

## Problem

Find the servers that expose the most other servers when compromised. A compromised server grants access to every server that trusts it, and to every server trusting those, and so on.

The first input line gives the test count `T`. Each case gives `N` and `M`, then `M` directed pairs `A B`, meaning server `A` trusts server `B`. Print the one-based numbers of all most important servers, in increasing order, separated by spaces.

| item | bound |
|---|---|
| tests T | positive integer, blank line before each case |
| servers N | 1 to 9000 |
| trust pairs M | 1 to 52000 |
| judge limit | 500 ms, 1536 MB |

The server count rules out a fresh search from every server.

Sample input:

```
2

5 4
3 1
3 2
4 3
5 3

6 5
1 2
2 3
3 1
1 4
5 6
```

Sample output:

```
1 2
4
```

## Idea

Turn the arrows around, like tracing who holds each spare key instead of which doors each key opens. Compromising a server then becomes ordinary reachability in the reversed graph. Collapse strongly connected components, and reachability becomes a walk on a small acyclic graph. Union bitsets in reverse topological order, then count the bits. A fresh search per server repeats the same work many times. Take the reversed graph with component bitsets as the whole algorithm.

## Why It Works

1. A pair `A B` means `A` trusts `B`, so compromising `B` exposes `A`.
2. Adding the reversed edge `B -> A` makes exposure exactly reachability.
3. All servers in one strongly connected component expose the same set.
4. The component graph is a directed acyclic graph, so reverse topological order processes every successor first.
5. Each component's reach bitset is the union of its own servers and its successors' bitsets.
6. Popcount gives the importance, and the largest value selects the answer servers.

| term | meaning |
|---|---|
| `reverseAdj` | adjacency of the reversed graph, used for Kosaraju's first pass |
| `componentOf` | strongly connected component id for each server |
| `dagAdj` | component graph edges along reversed trust |
| `reachBits` | one bitset of servers reachable from each component |
| `importance` | number of set bits in a component's bitset |

These five structures take the input from trust pairs to the final list.

A script trace for the first sample case gives importance `4, 4, 3, 1, 1` for servers one through five. The maximum is four, held by servers one and two, so the answer is `1 2`.

That trace matches the sample output.

## Code

**Input, counters and buffer.** The hand reader parses pairs, and the popcount helper uses bit tricks.

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

proc popCount64(value: uint64): int =
  var current = value
  current = current - ((current shr 1) and 0x5555555555555555'u64)
  current = (current and 0x3333333333333333'u64) + ((current shr 2) and 0x3333333333333333'u64)
  current = (current + (current shr 4)) and 0x0F0F0F0F0F0F0F0F'u64
  return int((current * 0x0101010101010101'u64) shr 56)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips blank lines between cases.
Both graph directions are kept for Kosaraju.
The buffer collects the answer lines.

**Graph build.** Each trust pair is stored once and added to both directions.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let computerCount = nextInt(inputData, scanPos)
  let trustCount = nextInt(inputData, scanPos)
  var originalAdj = newSeq[seq[int]](computerCount)
  var reverseAdj = newSeq[seq[int]](computerCount)
  for computerIndex in 0 .. computerCount - 1:
    originalAdj[computerIndex] = newSeq[int](0)
    reverseAdj[computerIndex] = newSeq[int](0)
  var edgeFrom = newSeq[int](trustCount)
  var edgeTo = newSeq[int](trustCount)
  for edgeIndex in 0 .. trustCount - 1:
    let trustingComputer = nextInt(inputData, scanPos) - 1
    let trustedComputer = nextInt(inputData, scanPos) - 1
    edgeFrom[edgeIndex] = trustingComputer
    edgeTo[edgeIndex] = trustedComputer
    originalAdj[trustingComputer].add trustedComputer
    reverseAdj[trustedComputer].add trustingComputer
```

Server numbers become zero-based on input.
`originalAdj` follows trust, while `reverseAdj` follows exposure.
Stored pairs are reused for the component graph.

**Component labeling.** Iterative Kosaraju avoids deep recursion on long chains.

```nim
  var visited = newSeq[bool](computerCount)
  var finishOrder = newSeq[int](computerCount)
  var finishedCount = 0
  var stackNodes = newSeq[int](computerCount)
  var stackCursors = newSeq[int](computerCount)
  for startNode in 0 .. computerCount - 1:
    if visited[startNode]:
      continue
    var depth = 0
    stackNodes[0] = startNode
    stackCursors[0] = 0
    visited[startNode] = true
    while depth >= 0:
      let currentNode = stackNodes[depth]
      let cursor = stackCursors[depth]
      if cursor < reverseAdj[currentNode].len:
        let nextNode = reverseAdj[currentNode][cursor]
        stackCursors[depth] = cursor + 1
        if not visited[nextNode]:
          visited[nextNode] = true
          depth += 1
          stackNodes[depth] = nextNode
          stackCursors[depth] = 0
      else:
        finishOrder[finishedCount] = currentNode
        finishedCount += 1
        depth -= 1

  var componentOf = newSeq[int](computerCount)
  for computerIndex in 0 .. computerCount - 1:
    componentOf[computerIndex] = -1
  var componentCount = 0
  var pendingNodes = newSeq[int](computerCount)
  for orderIndex in countdown(finishedCount - 1, 0):
    let startNode = finishOrder[orderIndex]
    if componentOf[startNode] != -1:
      continue
    var stackTop = 0
    pendingNodes[0] = startNode
    componentOf[startNode] = componentCount
    while stackTop >= 0:
      let currentNode = pendingNodes[stackTop]
      stackTop -= 1
      for nextNode in originalAdj[currentNode]:
        if componentOf[nextNode] == -1:
          componentOf[nextNode] = componentCount
          stackTop += 1
          pendingNodes[stackTop] = nextNode
    componentCount += 1
```

The first pass orders servers by finish time.
The second pass walks in reverse finish order.
Every server receives exactly one component id.

**Condensation and ordering.** Internal edges are dropped, and Kahn's algorithm orders the remaining graph.

```nim
  var dagAdj = newSeq[seq[int]](componentCount)
  for componentIndex in 0 .. componentCount - 1:
    dagAdj[componentIndex] = newSeq[int](0)
  for edgeIndex in 0 .. trustCount - 1:
    let reachSourceComponent = componentOf[edgeTo[edgeIndex]]
    let reachTargetComponent = componentOf[edgeFrom[edgeIndex]]
    if reachSourceComponent != reachTargetComponent:
      dagAdj[reachSourceComponent].add reachTargetComponent

  var indegree = newSeq[int](componentCount)
  for componentIndex in 0 .. componentCount - 1:
    for nextComponent in dagAdj[componentIndex]:
      indegree[nextComponent] += 1
  var queueNodes = newSeq[int](componentCount)
  var queueHead = 0
  var queueTail = 0
  for componentIndex in 0 .. componentCount - 1:
    if indegree[componentIndex] == 0:
      queueNodes[queueTail] = componentIndex
      queueTail += 1
  var topoOrder = newSeq[int](componentCount)
  var topoCount = 0
  while queueHead < queueTail:
    let currentComponent = queueNodes[queueHead]
    queueHead += 1
    topoOrder[topoCount] = currentComponent
    topoCount += 1
    for nextComponent in dagAdj[currentComponent]:
      indegree[nextComponent] -= 1
      if indegree[nextComponent] == 0:
        queueNodes[queueTail] = nextComponent
        queueTail += 1
```

An edge runs from the trusted component to the trusting component.
Duplicate edges are harmless for reachability.
Kahn's queue produces a valid topological order.

**Bitset union and output.** Each component ORs its successors' bitsets, then the largest count selects the servers.

```nim
  let wordCount = (computerCount + 63) div 64
  var reachBits = newSeq[uint64](componentCount * wordCount)
  for computerIndex in 0 .. computerCount - 1:
    let owner = componentOf[computerIndex] * wordCount + computerIndex div 64
    reachBits[owner] = reachBits[owner] or (uint64(1) shl (computerIndex mod 64))
  for orderIndex in countdown(topoCount - 1, 0):
    let currentComponent = topoOrder[orderIndex]
    for nextComponent in dagAdj[currentComponent]:
      for wordIndex in 0 .. wordCount - 1:
        let targetSlot = currentComponent * wordCount + wordIndex
        let sourceSlot = nextComponent * wordCount + wordIndex
        reachBits[targetSlot] = reachBits[targetSlot] or reachBits[sourceSlot]

  var componentImportance = newSeq[int](componentCount)
  for componentIndex in 0 .. componentCount - 1:
    var importance = 0
    for wordIndex in 0 .. wordCount - 1:
      importance += popCount64(reachBits[componentIndex * wordCount + wordIndex])
    componentImportance[componentIndex] = importance
  var bestImportance = -1
  for computerIndex in 0 .. computerCount - 1:
    if componentImportance[componentOf[computerIndex]] > bestImportance:
      bestImportance = componentImportance[componentOf[computerIndex]]
  var firstNumber = true
  for computerIndex in 0 .. computerCount - 1:
    if componentImportance[componentOf[computerIndex]] == bestImportance:
      if not firstNumber:
        outputBuffer.add ' '
      appendOutput($(computerIndex + 1))
      firstNumber = false
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Reverse order guarantees every successor is complete before use.
One 64-bit word covers 64 servers, so unions are cheap.
The final loop walks servers in increasing order.

## Complexity

SCC labeling and topological ordering are linear in the graph size. Bitset unions add one word operation per component edge.

| phase | time | space |
|---|---|---|
| input read | one pass over trust pairs | two adjacency lists |
| SCC labeling | two passes over nodes and edges | finish order and stacks |
| component graph | one pass over stored pairs | component adjacency |
| bitset union | one word OR per edge word | one bitset per component |
| output | one line per case | block buffer |

The bitsets and adjacency lists dominate memory use.

| measure | Big O |
|---|---|
| time | O((N + M) * N / 64) |
| space | O(N^2 / 64 + M) |

Running a search from every server would cost O(N*(N+M)). The component bitsets cut that cost sharply.
