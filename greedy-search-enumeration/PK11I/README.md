# PK11I — Paths in a Tree (SPOJ)

<https://www.spoj.com/problems/PK11I/>

## Problem

Directed edges of a tree leave some nodes short of incoming arrows. Add the fewest reversed paths so every node can reach every other node.

Input starts with the number of test cases. Each case gives the node count, then one directed edge per line. Nodes are numbered from 0 to N-1. Output Case i: answer, one line per case.

| item | bound |
|---|---|
| test cases | up to 30 |
| nodes per case | 2 to 20000 |
| judge limit | 906 ms, 1536 MB |

The node bound drives a single pass over edges, with no graph traversal.

Sample input:

```
2
4
0 1
1 2
1 3
5
0 1
1 2
1 3
0 4
```

Sample output:

```
Case 1: 2
Case 2: 3
```

## Idea

Every tree edge needs a return route, like a one-way street that needs a lane back. Count the arrows entering and leaving each node. A node with more incoming arrows than outgoing arrows starts that many reversed paths.

The algorithm scans every edge once and adds each positive difference. It costs constant work per node after the scan. Searching all path covers grows exponentially with the edge count.

Each surplus incoming arrow becomes one path start, and the sum is the answer.

## Why It Works

1. A tree has one route between any two nodes, so each edge needs a reversed arc.
2. A special path reverses a chain of edges that point toward its current node.
3. Arriving at a node consumes one incoming original edge and leaves along another one.
4. A node with `incomingCounts` above `outgoingCounts` has unmatched entries; each needs a new path.
5. Pairing the remaining entries with exits at each node uses all other edges, so the count is achieved.

| term | meaning |
|---|---|
| `incomingCounts` | number of tree edges pointing into a node |
| `outgoingCounts` | number of tree edges pointing out of a node |
| `pathCount` | total number of reversed paths needed |

The surplus at each node counts exactly the paths that start there.

The sample's first case has four nodes. Node 0 has 0 in and 1 out, node 1 has 1 in and 2 out. Nodes 2 and 3 each have 1 in and 0 out, so each contributes one path.

```
node 0: 0 in, 1 out -> 0
node 1: 1 in, 2 out -> 0
node 2: 1 in, 0 out -> 1
node 3: 1 in, 0 out -> 1
total -> 2
```

The trace matches Case 1: 2 in the sample output.

## Code

**Input and output helpers.** The whole input is scanned once, and lines are buffered.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

`nextInt` skips separators without allocating tokens.

`appendOutput` flushes one large block at a time.

**Degree scan.** Each directed edge updates two counters.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  var incomingCounts = newSeq[int](nodeCount)
  var outgoingCounts = newSeq[int](nodeCount)
  var edgeIndex = 1
  while edgeIndex < nodeCount:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    outgoingCounts[fromNode] += 1
    incomingCounts[toNode] += 1
    edgeIndex += 1
```

The loop runs exactly `nodeCount - 1` times.

Both counters start at zero for every case.

**Surplus sum.** Positive differences give the path count.

```nim
  var pathCount = 0
  for nodeIndex in 0 .. nodeCount - 1:
    if incomingCounts[nodeIndex] > outgoingCounts[nodeIndex]:
      pathCount += incomingCounts[nodeIndex] - outgoingCounts[nodeIndex]
  appendOutput("Case " & $caseIndex & ": " & $pathCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Nodes with a surplus start that many reversed paths.

The answer is written once per case.

## Complexity

Each case reads one edge per node and then visits every node once.

| phase | time | space |
|---|---|---|
| input read | one pass over all edges | input string |
| degree scan | one update per edge | two count arrays |
| surplus sum | one check per node | block buffer |

The degree scan dominates the work in each case.

| measure | Big O |
|---|---|
| time | O(N) per case |
| space | O(N) per case |

N is the node count, and no adjacency list is built.

Trying every set of reversed paths is exponential, while the degree balance gives the answer in one linear pass.
