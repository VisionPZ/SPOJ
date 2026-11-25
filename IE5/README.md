# IE5 — Hamiltonian Cycles (SPOJ)

<https://www.spoj.com/problems/IE5/>

## Problem

Count Hamiltonian cycles of a complete graph that avoid a short list of forbidden edges. Cycles with the same edges count once, and the answer is taken modulo 9901.

Input starts with the case count. Each case gives node count n and forbidden count k, followed by k vertex pairs. Output `Case #X: Y` on one line per case, starting from case 1.

| item | bound |
|---|---|
| case count | 1 to 10 |
| nodes n | 3 to 300 in scored cases |
| forbidden edges k | 0 to 15 |
| judge limit | 1416 ms, 1536 MB |

Sample input:

```
2
4 1
1 2
8 4
1 2
2 3
4 5
5 6
```

Sample output:

```
Case #1: 1
Case #2: 660
```

## Idea

Remove bad cycles by inclusion-exclusion, like subtracting every ticket that mentions a banned seat. Each subset of forbidden edges is either impossible, a set of disjoint paths, or the whole cycle.

For a linear forest, contracting each path gives fewer nodes, and each path offers two directions. The number of cycles containing that forest is (n - e - 1)! / 2 times 2 pathCount. Only 2^k subsets need checking because k is at most 15. Enumerating all cycles would cost factorial time. Takeaway: sum signed forest counts over forbidden subsets.

## Why It Works

1. Inclusion-exclusion subtracts cycles using one forbidden edge, adds those using two, and so on.
2. A vertex with three chosen edges cannot lie on any Hamiltonian cycle, so its subset contributes zero.
3. Chosen edges must form disjoint paths unless they form one cycle covering every vertex.
4. Contracting e path edges leaves n - e supernodes, which have (n - e - 1)! / 2 undirected cycles.
5. Each contracted path can be travelled in two directions, giving the factor 2 pathCount.

| term | meaning |
|---|---|
| `edgeTally` | chosen edges ending at each union-find root |
| `vertexTally` | used vertices belonging to each root |
| `pathComponents` | number of nontrivial path components |
| `contribution` | signed cycle count for one subset |
| `inverseOfTwo` | modular inverse of 2 modulo 9901 |

A script handles n = 4 with forbidden edges 1-2 and 3-4. The empty subset gives 3 cycles. Each single-edge subset gives 2 cycles, leaving -1. Both edges together form two paths and give 2 cycles, so the answer returns to 1.

The whole-cycle case is counted as one cycle. Nodes fewer than three give zero cycles, since a simple graph on two nodes has no Hamiltonian cycle.

## Code

**Reader and helpers.** The stream is loaded once and union-find uses path compression.

```nim
const flushBlockBytes = 1 shl 17
const cycleModulus = 9901
const inverseOfTwo = 4951

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

proc findRoot(parent: var seq[int], vertex: int): int =
  var current = vertex
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current
```

`nextInt` reads every vertex label without line assumptions.
`findRoot` returns the component root for a vertex.
`appendOutput` groups the case lines into block writes.

**Case setup.** Factorials and powers of two are precomputed once per case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  let forbiddenCount = nextInt(inputData, scanPos)
  var edgeStart = newSeq[int](forbiddenCount)
  var edgeEnd = newSeq[int](forbiddenCount)
  for edgeIndex in 0 .. forbiddenCount - 1:
    edgeStart[edgeIndex] = nextInt(inputData, scanPos) - 1
    edgeEnd[edgeIndex] = nextInt(inputData, scanPos) - 1
  var factorial = newSeq[int](nodeCount + 1)
  factorial[0] = 1
  for position in 1 .. nodeCount:
    factorial[position] = factorial[position - 1] * position mod cycleModulus
  var powersOfTwo = newSeq[int](forbiddenCount + 1)
  powersOfTwo[0] = 1
  for position in 1 .. forbiddenCount:
    powersOfTwo[position] = powersOfTwo[position - 1] * 2 mod cycleModulus
  var degree = newSeq[int](nodeCount)
  var parent = newSeq[int](nodeCount)
  var edgeTally = newSeq[int](nodeCount)
  var vertexTally = newSeq[int](nodeCount)
  var answer = 0
```

Vertex labels are shifted down by one for array indexing.
`factorial` holds every value up to n modulo 9901.
`powersOfTwo` supplies the path orientation factor.

**Subset sweep.** Each forbidden subset contributes one signed forest count.

```nim
  if nodeCount >= 3:
    for subset in 0 .. (1 shl forbiddenCount) - 1:
      for nodeIndex in 0 .. nodeCount - 1:
        degree[nodeIndex] = 0
        parent[nodeIndex] = nodeIndex
        edgeTally[nodeIndex] = 0
        vertexTally[nodeIndex] = 0
      var invalid = false
      var selectedEdges = 0
      for edgeIndex in 0 .. forbiddenCount - 1:
        if (subset and (1 shl edgeIndex)) != 0:
          let startNode = edgeStart[edgeIndex]
          let endNode = edgeEnd[edgeIndex]
          degree[startNode] += 1
          degree[endNode] += 1
          selectedEdges += 1
          if degree[startNode] > 2 or degree[endNode] > 2:
            invalid = true
      if invalid:
        continue
      var usedVertices = 0
      for nodeIndex in 0 .. nodeCount - 1:
        if degree[nodeIndex] > 0:
          usedVertices += 1
      var contribution = 0
      if selectedEdges == 0:
        contribution = factorial[nodeCount - 1] * inverseOfTwo mod cycleModulus
      else:
        for edgeIndex in 0 .. forbiddenCount - 1:
          if (subset and (1 shl edgeIndex)) != 0:
            let startRoot = findRoot(parent, edgeStart[edgeIndex])
            let endRoot = findRoot(parent, edgeEnd[edgeIndex])
            if startRoot != endRoot:
              parent[startRoot] = endRoot
        for nodeIndex in 0 .. nodeCount - 1:
          if degree[nodeIndex] > 0:
            let rootNode = findRoot(parent, nodeIndex)
            vertexTally[rootNode] += 1
        for edgeIndex in 0 .. forbiddenCount - 1:
          if (subset and (1 shl edgeIndex)) != 0:
            let rootNode = findRoot(parent, edgeStart[edgeIndex])
            edgeTally[rootNode] += 1
        var hasCycle = false
        var componentCount = 0
        for nodeIndex in 0 .. nodeCount - 1:
          if vertexTally[nodeIndex] > 0:
            componentCount += 1
            if edgeTally[nodeIndex] == vertexTally[nodeIndex]:
              hasCycle = true
        if hasCycle:
          if selectedEdges == nodeCount and usedVertices == nodeCount and componentCount == 1:
            contribution = 1
        else:
          var pathComponents = 0
          for nodeIndex in 0 .. nodeCount - 1:
            if edgeTally[nodeIndex] > 0:
              pathComponents += 1
          contribution = factorial[nodeCount - selectedEdges - 1] * inverseOfTwo mod cycleModulus
          contribution = contribution * powersOfTwo[pathComponents] mod cycleModulus
      if (selectedEdges mod 2) == 1:
        answer = (answer - contribution) mod cycleModulus
      else:
        answer = (answer + contribution) mod cycleModulus
      if answer < 0:
        answer = answer + cycleModulus
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A vertex of degree three marks the subset invalid.
A closed component only contributes when it is the whole cycle.
The sign flips with the parity of the selected edge count.

## Complexity

Each case checks 2^k subsets and scans k edges in each subset.

| phase | time | space |
|---|---|---|
| parse edges | one pass over k pairs | two arrays of size k |
| subset sweep | 2^k times k union steps | four arrays of size n |
| output | one buffered write | one output string |

| measure | Big O |
|---|---|
| time | O(2^k * k) per case |
| space | O(n + k) |

Listing every Hamiltonian cycle would take factorial time in n. Takeaway: only the 2^k forbidden subsets matter when k stays small.
