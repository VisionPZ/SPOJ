# TOUR — Fake tournament (SPOJ)

<https://www.spoj.com/problems/TOUR/>

## Problem

A sports committee schedules matches one pair at a time. Some rivals always beat a given contestant, so only certain players can be guided to the trophy.

Input: `t` tests. Each test starts with `n`, followed by `n` lines. Line `k` begins with a count `m`, then lists contestants who always beat player `k`.

Output: one integer per test, the number of contestants who can be made champion.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Contestants `n` | 1 to 1000 |
| Relations | one list per contestant |
| Judge limit | 1000 ms, 1536 MB |

The lists describe a directed graph, so the answer depends on reachability, not on raw counts.

The sample input and output:

```
1
3
2 3 2
1 3
0
```

```
1
```

## Idea

Group rivals who can all reach each other, then look for a group with no rivals above it. Think of political factions: only a faction with no stronger faction can take power.

The program uses Kosaraju's algorithm for strongly connected components (groups with two-way reachability). It runs two depth-first searches, one on the graph and one on the reversed graph.

Then it counts components with no incoming edges. Each test costs `O(n + e)` time and space.

Testing each contestant separately repeats the same reachability work `n` times. Component condensation settles every contestant at once.

A unique source group gives the answer; two source groups mean nobody can win.

## Why It Works

Five facts prove the component rule.

1. Draw an edge from each contestant to every rival who always beats them.
2. Inside a strongly connected component, any member can reach any other. The members therefore share the same chance of becoming champion.
3. Contracting each component yields a directed acyclic graph. A champion must lie in a component with no incoming edge.
4. If two source components exist, neither can eliminate the other, so no contestant can win. With one source, every member of it can be scheduled to win.
5. Kosaraju's first search records finish order; the second search on the reversed graph labels components in that order.

The arrays built by the driver:

| Term | Meaning |
| --- | --- |
| `adjacency[k]` | contestants whom player `k` beats |
| `reverseAdjacency[k]` | contestants who beat player `k` |
| `depthFirstOrder` | vertices in increasing finish time |
| `componentOf` | component id of each contestant |
| `inDegree` | edges entering a component from another |

The input lines name better players, so the program reverses them while building the graph.

A script trace of the sample test:

```
players [1, 2, 3]
| beats edge | from | to |
| 3 beats 1 | 3 | 1 |
| 2 beats 1 | 2 | 1 |
| 3 beats 2 | 3 | 2 |
SCCs: {1}, {2}, {3}
| component | incoming edges |
| {3} | 0 |
| {2} | 1 from {3} |
| {1} | 2 from {2}, {3} |
source components = 1, members = {3}, answer = 1
```

Only contestant 3 has no rival above them.

## Code

**Input and helpers.** One buffer holds the stream, and a digit scanner reads the lists.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

All input values are positive, so the scanner needs no sign branch.
`appendOutput` flushes at 128 KiB.
Each case reads exactly `n` lists.

**Two depth-first searches.** Both helpers use explicit stacks to avoid recursion depth limits.

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

`depthFirstOrder` records a vertex when all neighbors are done.
`assignComponents` walks the reversed graph and labels every reachable vertex with one id.
Neither helper allocates inside the inner loop.

**Case driver.** The driver builds both graphs, condenses them, and counts sources.

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

Each input line adds one edge to `adjacency` and its reverse.
The second search uses `countdown(finishOrder.len - 1, 0)` over finish order.

`inDegree` ignores edges inside one component. The answer is the size of the single source component, or zero.

## Complexity

Both graph searches and the condensation are linear in vertices plus edges.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Graph build | O(n + e) | O(n + e) for two graph arrays |
| Finish-order search | O(n + e) | O(n) for stack and flags |
| Component assignment | O(n + e) | O(n) for labels |
| Source count | O(n + e) | O(c) for in-degrees |
| Output | one write per 128 KiB block | 128 KiB |
| Total per test | O(n + e) | O(n + e) |

At `n = 1000` the searches visit every contestant and every listed relation once.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(n + e) per test |
| Space | O(n + e) per test, plus buffers |

Trying each contestant as a separate champion repeats reachability work `n` times. Component condensation answers all contestants in one pass.
