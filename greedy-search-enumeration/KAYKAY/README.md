# KAYKAY — Disjoint Subtrees (SPOJ)

<https://www.spoj.com/problems/KAYKAY/>

## Problem

Pick two disjoint connected vertex sets A and B of sizes k1 and k2 in a valued tree, and maximize the sum on A minus the sum on B. Print -1 when no such pair exists.

Input starts with the test count. Each case gives n, k1, k2, then n vertex values, then n-1 undirected edges. Print one integer per case.

| item | bound |
|---|---|
| vertices n | 2 to 200 |
| sizes k1, k2 | 1 to n |
| vertex value | -100000 to 100000 |
| test count | not stated |
| judge limit | 500 ms, 1536 MB |

Negative values drive the need for both maximum and minimum sums.

Sample input:

```
2
7 3 3
0 1 -1 2 3 -2 -3
0 1
0 2
1 3
1 4
2 5
2 6
3 2 2
1 2 3
0 1
0 2
```

Sample output:

```
12
-1
```

The first case uses {1,3,4} and {2,5,6}.

## Idea

Cutting one edge separates any valid pair, like cutting a rope to hang two baskets on opposite sides. Tree knapsack computes the best connected subtree containing each vertex inside its rooted part. A rerooting pass computes the best subtree anywhere inside each edge's other component. Trying both assignments of A and B across every edge gives the optimum. Checking all subset pairs would take exponential time. The two knapsack sweeps turn that search into polynomial work.

## Why It Works

1. For disjoint connected sets, an edge on the path between them splits A and B into separate components.
2. A connected subtree inside a rooted part has a highest vertex and contains that vertex.
3. Knapsack merging adds one attached child subtree at a time, keeping the highest vertex fixed.
4. Excluding one child from the parent side gives the component on that child's edge.
5. A is taken at maximum sum and B at minimum sum, so their difference is largest.

| term | meaning |
|---|---|
| `downMax` | largest connected subtree containing a vertex inside its rooted part |
| `downMin` | smallest such subtree |
| `subtreeMax` | best value anywhere in a rooted part |
| `complementMax` | best value outside that rooted part |
| `bestAnswer` | largest difference over all edges |

The table names the arrays that carry each side of an edge.

A script trace for the first sample case follows:

```
A = {1,3,4}: 1 + 2 + 3 = 6
B = {2,5,6}: -1 + -2 + -3 = -6
difference = 6 - (-6) = 12
edge (0,1) separates those two sets
```

The trace matches the first sample answer.

Sentinels of plus or minus 10^18 mark impossible sizes, so negative answers remain valid.

## Code

**Knapsack helpers and input.** The scanner accepts minus signs for vertex values.

```nim
const flushBlockBytes = 1 shl 17
const negativeInfinity = -1000000000000000000'i64
const positiveInfinity = 1000000000000000000'i64

proc makeEmptyArray(limitValue: int, initializer: int64): seq[int64] =
  var resultArray = newSeq[int64](limitValue + 1)
  for sizeValue in 0 .. limitValue:
    resultArray[sizeValue] = initializer
  resultArray[0] = 0
  return resultArray

proc mergeMaximum(leftArray, rightArray: seq[int64], limitValue: int): seq[int64] =
  var mergedArray = makeEmptyArray(limitValue, negativeInfinity)
  for leftSize in 1 .. limitValue:
    if leftArray[leftSize] <= negativeInfinity div 2:
      continue
    for rightSize in 0 .. limitValue - leftSize:
      if rightArray[rightSize] <= negativeInfinity div 2:
        continue
      let combinedValue = leftArray[leftSize] + rightArray[rightSize]
      if combinedValue > mergedArray[leftSize + rightSize]:
        mergedArray[leftSize + rightSize] = combinedValue
  return mergedArray

proc mergeMinimum(leftArray, rightArray: seq[int64], limitValue: int): seq[int64] =
  var mergedArray = makeEmptyArray(limitValue, positiveInfinity)
  for leftSize in 1 .. limitValue:
    if leftArray[leftSize] >= positiveInfinity div 2:
      continue
    for rightSize in 0 .. limitValue - leftSize:
      if rightArray[rightSize] >= positiveInfinity div 2:
        continue
      let combinedValue = leftArray[leftSize] + rightArray[rightSize]
      if combinedValue < mergedArray[leftSize + rightSize]:
        mergedArray[leftSize + rightSize] = combinedValue
  return mergedArray

proc mergeSiblingMaximum(leftArray, rightArray: seq[int64], limitValue: int): seq[int64] =
  var mergedArray = makeEmptyArray(limitValue, negativeInfinity)
  for leftSize in 0 .. limitValue:
    if leftArray[leftSize] <= negativeInfinity div 2 and leftSize > 0:
      continue
    for rightSize in 0 .. limitValue - leftSize:
      if rightArray[rightSize] <= negativeInfinity div 2 and rightSize > 0:
        continue
      let combinedValue = leftArray[leftSize] + rightArray[rightSize]
      if combinedValue > mergedArray[leftSize + rightSize]:
        mergedArray[leftSize + rightSize] = combinedValue
  return mergedArray

proc mergeSiblingMinimum(leftArray, rightArray: seq[int64], limitValue: int): seq[int64] =
  var mergedArray = makeEmptyArray(limitValue, positiveInfinity)
  for leftSize in 0 .. limitValue:
    if leftArray[leftSize] >= positiveInfinity div 2 and leftSize > 0:
      continue
    for rightSize in 0 .. limitValue - leftSize:
      if rightArray[rightSize] >= positiveInfinity div 2 and rightSize > 0:
        continue
      let combinedValue = leftArray[leftSize] + rightArray[rightSize]
      if combinedValue < mergedArray[leftSize + rightSize]:
        mergedArray[leftSize + rightSize] = combinedValue
  return mergedArray

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The left array always contains the highest vertex.
The right array may be empty, which skips that child.
The scanner keeps a minus sign before digit skipping.

**Bottom-up pass.** Each child merges into its parent in reverse order.

```nim
  var parentVertex = newSeq[int](vertexCount)
  for vertex in 0 .. vertexCount - 1:
    parentVertex[vertex] = -1
  var traversalOrder = newSeq[int]()
  traversalOrder.add 0
  var traversalIndex = 0
  while traversalIndex < traversalOrder.len:
    let currentVertex = traversalOrder[traversalIndex]
    for neighbor in adjacency[currentVertex]:
      if neighbor != parentVertex[currentVertex]:
        parentVertex[neighbor] = currentVertex
        traversalOrder.add neighbor
    traversalIndex += 1

  var downMax = newSeq[seq[int64]](vertexCount)
  var downMin = newSeq[seq[int64]](vertexCount)
  var subtreeMax = newSeq[seq[int64]](vertexCount)
  var subtreeMin = newSeq[seq[int64]](vertexCount)
  for vertex in 0 .. vertexCount - 1:
    downMax[vertex] = makeEmptyArray(sizeLimit, negativeInfinity)
    downMin[vertex] = makeEmptyArray(sizeLimit, positiveInfinity)
    downMax[vertex][1] = vertexValues[vertex]
    downMin[vertex][1] = vertexValues[vertex]

  for orderIndex in countdown(traversalOrder.len - 1, 0):
    let currentVertex = traversalOrder[orderIndex]
    for neighbor in adjacency[currentVertex]:
      if parentVertex[neighbor] == currentVertex:
        downMax[currentVertex] = mergeMaximum(downMax[currentVertex], downMax[neighbor], sizeLimit)
        downMin[currentVertex] = mergeMinimum(downMin[currentVertex], downMin[neighbor], sizeLimit)
    subtreeMax[currentVertex] = downMax[currentVertex]
    subtreeMin[currentVertex] = downMin[currentVertex]
    for neighbor in adjacency[currentVertex]:
      if parentVertex[neighbor] == currentVertex:
        for sizeValue in 0 .. sizeLimit:
          if subtreeMax[neighbor][sizeValue] > subtreeMax[currentVertex][sizeValue]:
            subtreeMax[currentVertex][sizeValue] = subtreeMax[neighbor][sizeValue]
          if subtreeMin[neighbor][sizeValue] < subtreeMin[currentVertex][sizeValue]:
            subtreeMin[currentVertex][sizeValue] = subtreeMin[neighbor][sizeValue]
```

Each rooted part keeps one entry per exact size.
Subtree bests aggregate children after merging.
Sentinels block sizes that do not fit.

**Edge decision.** Every non-root vertex represents one separating edge.

```nim
  var bestAnswer = negativeInfinity
  for vertex in 1 .. vertexCount - 1:
    let insideFirst = subtreeMax[vertex][firstSize]
    let insideSecond = subtreeMin[vertex][secondSize]
    let outsideFirst = complementMax[vertex][firstSize]
    let outsideSecond = complementMin[vertex][secondSize]
    if insideFirst > negativeInfinity div 2 and outsideSecond < positiveInfinity div 2:
      let candidateValue = insideFirst - outsideSecond
      if candidateValue > bestAnswer:
        bestAnswer = candidateValue
    if outsideFirst > negativeInfinity div 2 and insideSecond < positiveInfinity div 2:
      let candidateValue = outsideFirst - insideSecond
      if candidateValue > bestAnswer:
        bestAnswer = candidateValue

  if bestAnswer <= negativeInfinity div 2:
    appendOutput("-1")
  else:
    appendOutput($bestAnswer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Both assignments of A and B are tested.
An unreachable sentinel leaves that candidate aside.
A sentinel result is printed as -1.

## Complexity

The two knapsack sweeps dominate each case.

| phase | time | space |
|---|---|---|
| rooting | one pass over edges | parent array |
| bottom-up knapsack | child merges per vertex | four size tables |
| top-down exclusion | prefix and suffix per vertex | complement tables |
| edge decision | one check per edge | block buffer |

The phase table separates the two knapsack directions.

| measure | Big O |
|---|---|
| time | O(n times k squared) |
| space | O(n times k) |

Checking all subset pairs takes exponential time. Tree knapsack replaces that check with two polynomial sweeps.
