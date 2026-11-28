# MSTS — Count Minimum Spanning Trees (SPOJ)

<https://www.spoj.com/problems/MSTS/>

## Problem

A connected weighted graph has one or more minimum spanning trees. Count them, reduced modulo 31011.

Input gives node count, edge count, then one weighted undirected edge per line. Output one line with the count modulo 31011.

| item | bound |
|---|---|
| nodes N | 1 to 100 |
| edges M | 1 to 1000 |
| weight c | 1 to 10^9 |
| parallel edges | none |
| judge limit | 1333 ms, 1536 MB |

The modulus drives the design: it is composite, so plain modular inverses do not work for every pivot.

Sample input:

```
4 6
1 2 1
1 3 1
1 4 1
2 3 2
2 4 1
3 4 1
```

Sample output:

```
8
```

## Idea

Process equal weights in batches, like laying identical bricks one layer at a time before moving to the next layer.

Kirchhoff matrix-tree theorem counts spanning trees of each batch graph after cheaper batches are contracted. Multiply those counts. Split the composite modulus into primes 3 and 10337, take two determinants, then recombine with the Chinese remainder theorem.
Each batch costs a determinant over its contracted components. Listing all spanning trees costs exponential time.
The batch product is the answer.

## Why It Works

1. A minimum spanning tree fixes how many edges of each weight it uses.
2. Cheaper edges contract into components before the current batch is considered.
3. Within one weight batch, every spanning forest of the auxiliary graph gives the same total weight.
4. Kirchhoff theorem turns the forest count into a Laplacian minor determinant.
5. The modulus factors into two primes, so two prime-field determinants recombine to the exact residue.

| term | meaning |
|---|---|
| `answerModulus` | target modulus 31011 |
| `firstPrime` | prime factor 3 |
| `secondPrime` | prime factor 10337 |
| `determinantModulo` | Gaussian elimination over one prime field |
| `spanningTreeCount` | determinant of a connected batch component |
| `unionRoots` | merge components after one batch |

The table names the pieces that turn a graph count into a modular number.

Worked example on the sample graph:

```
weight 1 batch: vertices 1 2 3 4, edges 1-2 1-3 1-4 2-4 3-4
spanning trees of that batch = 8
weight 2 batch: endpoints already connected, contribution = 1
answer = 8 * 1 mod 31011 = 8
```

The batch product reproduces the sample output.

## Code

**Prime-field determinant.** These routines reduce the Laplacian minor modulo each prime.

```nim
proc powerModulo(baseValue: int64, exponent: int64, modulus: int64): int64 =
  var result: int64 = 1
  var current = baseValue mod modulus
  var powerLeft = exponent
  while powerLeft > 0:
    if (powerLeft and 1) == 1:
      result = (result * current) mod modulus
    current = (current * current) mod modulus
    powerLeft = powerLeft shr 1
  return result

proc determinantModulo(matrix: seq[int64], dimension: int, modulus: int64): int64 =
  var work = newSeq[int64](dimension * dimension)
  for rowIndex in 0 .. dimension - 1:
    for columnIndex in 0 .. dimension - 1:
      var value = matrix[rowIndex * dimension + columnIndex] mod modulus
      if value < 0:
        value = value + modulus
      work[rowIndex * dimension + columnIndex] = value
  var result: int64 = 1
  for columnIndex in 0 .. dimension - 1:
    var pivotRow = columnIndex
    while pivotRow < dimension and work[pivotRow * dimension + columnIndex] == 0:
      pivotRow += 1
    if pivotRow == dimension:
      return 0
    if pivotRow != columnIndex:
      for columnScan in 0 .. dimension - 1:
        swap work[pivotRow * dimension + columnScan], work[columnIndex * dimension + columnScan]
      result = (-result) mod modulus
      if result < 0:
        result = result + modulus
    let pivotValue = work[columnIndex * dimension + columnIndex]
    result = (result * pivotValue) mod modulus
    let pivotInverse = powerModulo(pivotValue, modulus - 2, modulus)
    for rowIndex in columnIndex + 1 .. dimension - 1:
      if work[rowIndex * dimension + columnIndex] == 0:
        continue
      let factor = (work[rowIndex * dimension + columnIndex] * pivotInverse) mod modulus
      for columnScan in columnIndex .. dimension - 1:
        var updated = work[rowIndex * dimension + columnScan] - factor * work[columnIndex * dimension + columnScan]
        updated = updated mod modulus
        if updated < 0:
          updated = updated + modulus
        work[rowIndex * dimension + columnScan] = updated
  return result

```

Fermat exponentiation supplies each pivot inverse.
Row swaps flip the determinant sign.
A zero pivot returns zero for that batch.

**Forest count.** This routine builds the minor and calls the determinant once per prime.

```nim
proc spanningTreeCount(adjacency: seq[seq[int]], members: seq[int], modulus: int64): int64 =
  let vertexCount = members.len
  if vertexCount < 2:
    return 1
  let dimension = vertexCount - 1
  var removedLocal = members[0]
  for memberLocal in members:
    if memberLocal > removedLocal:
      removedLocal = memberLocal
  var matrixIndex = newSeq[int](adjacency.len)
  for indexValue in 0 .. matrixIndex.len - 1:
    matrixIndex[indexValue] = -1
  var nextIndex = 0
  for memberLocal in members:
    if memberLocal != removedLocal:
      matrixIndex[memberLocal] = nextIndex
      nextIndex += 1
  var matrix = newSeq[int64](dimension * dimension)
  for sourceLocal in members:
    for targetLocal in adjacency[sourceLocal]:
      if sourceLocal >= targetLocal:
        continue
      let sourceIndex = matrixIndex[sourceLocal]
      let targetIndex = matrixIndex[targetLocal]
      if sourceIndex != -1:
        matrix[sourceIndex * dimension + sourceIndex] = matrix[sourceIndex * dimension + sourceIndex] + 1
      if targetIndex != -1:
        matrix[targetIndex * dimension + targetIndex] = matrix[targetIndex * dimension + targetIndex] + 1
      if sourceIndex != -1 and targetIndex != -1:
        matrix[sourceIndex * dimension + targetIndex] = matrix[sourceIndex * dimension + targetIndex] - 1
        matrix[targetIndex * dimension + sourceIndex] = matrix[targetIndex * dimension + sourceIndex] - 1
  return determinantModulo(matrix, dimension, modulus)

```

Each undirected edge adds two diagonal entries and two off-diagonal entries.
The highest local index is removed from the minor.
A single-vertex component contributes one forest.

**Weight batches.** The driver sorts edges, contracts each batch, and combines residues.

```nim
var groupStart = 0
while groupStart < edgeCount:
  var groupEnd = groupStart
  while groupEnd < edgeCount and edges[groupEnd].weight == edges[groupStart].weight:
    groupEnd += 1
  var localRoots = newSeq[int]()
  var auxEdges = newSeq[tuple[first: int, second: int]]()
  for edgeIndex in groupStart .. groupEnd - 1:
    let firstRoot = findRoot(edges[edgeIndex].sourceNode)
    let secondRoot = findRoot(edges[edgeIndex].targetNode)
    if firstRoot == secondRoot:
      continue
    if localIndex[firstRoot] == -1:
      localIndex[firstRoot] = localRoots.len
      localRoots.add firstRoot
    if localIndex[secondRoot] == -1:
      localIndex[secondRoot] = localRoots.len
      localRoots.add secondRoot
    auxEdges.add (localIndex[firstRoot], localIndex[secondRoot])
  let localCount = localRoots.len
  var adjacency = newSeq[seq[int]](localCount)
  for localEdge in auxEdges:
    adjacency[localEdge.first].add localEdge.second
    adjacency[localEdge.second].add localEdge.first
  var visited = newSeq[bool](localCount)
  for startLocal in 0 .. localCount - 1:
    if visited[startLocal]:
      continue
    var members = newSeq[int]()
    var stack = newSeq[int]()
    stack.add startLocal
    visited[startLocal] = true
    while stack.len > 0:
      let currentLocal = stack[stack.len - 1]
      stack.setLen(stack.len - 1)
      members.add currentLocal
      for neighborLocal in adjacency[currentLocal]:
        if not visited[neighborLocal]:
          visited[neighborLocal] = true
          stack.add neighborLocal
    var areaCount = spanningTreeCount(adjacency, members, int64(firstPrime))
    var bigCount = spanningTreeCount(adjacency, members, int64(secondPrime))
    let difference = (bigCount - areaCount mod int64(secondPrime) + int64(secondPrime)) mod int64(secondPrime)
    let combined = (areaCount + int64(firstPrime) * ((difference * int64(inverseThree)) mod int64(secondPrime))) mod int64(answerModulus)
    answer = (answer * combined) mod int64(answerModulus)
  for edgeIndex in groupStart .. groupEnd - 1:
    unionRoots(edges[edgeIndex].sourceNode, edges[edgeIndex].targetNode)
  for localRoot in localRoots:
    localIndex[localRoot] = -1
  groupStart = groupEnd

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Insertion sort keeps the edge order stable.
The two prime residues recombine with a precomputed inverse of three.
All endpoints union after their batch is counted.

## Complexity

Costs follow the size of each weight batch.

| phase | time | space |
|---|---|---|
| edge sort | O(M^2) insertion sort | O(M) |
| batch determinants | O(sum of v^3) | O(v^2) |
| unions | O(M alpha(N)) | O(N) |
| output | one line | block buffer |

The determinant phases dominate the phase table.

| measure | Big O |
|---|---|
| time per group | O(v^3 log p) |
| space | O(N + M + v^2) |

Enumerating spanning-tree subsets takes exponential time and cannot reach M = 1000.
The determinant reduces each batch to polynomial work.
