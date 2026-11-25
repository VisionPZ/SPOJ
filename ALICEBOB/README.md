# ALICEBOB — Alice and Bob (SPOJ)
<https://www.spoj.com/problems/ALICEBOB/>

## Problem

Alice draws a convex polygon but hands Bob only a bag of edges, without marking which are sides.
Bob must rebuild the border order from that bag of vertex pairs.

The first line gives the dataset count. Each dataset gives n and m, then 2(m+n) endpoint integers for the sides and diagonals. Print vertices 1 to n in border order, starting at 1 with the smaller border neighbor second.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Datasets d | 1 to 20 |
| Vertices n | 3 to 10000 |
| Diagonals m | 0 to n-3 |
| Judge time | 7 s |
| Judge memory | 1536 MB |

Every dataset has a valid puzzle, so no rejection path is needed.

The sample input and its expected output follow byte for byte.

```
1
4 1
1 3 4 2 1 2
4 1 2 3
```

```
1 3 2 4
```


## Idea

Peel degree-two corners (ears) from the polygon, like trimming ears off paper until a triangle remains. A reverse pass glues them back.
The program stores every given edge once in an adjacency list and once in a hash table. The hash table stops duplicate diagonals when an ear is removed.
A queue repeatedly removes a degree-two vertex, links its two neighbors, and records the ear. The survivors form a triangle, and a reverse pass restores every removed vertex.
Trying all vertex permutations costs factorial time, while peeling touches each ear once.
Ear clipping rebuilds the border in linear expected time.

## Why It Works

1. In a convex polygon with noncrossing diagonals, any degree-two vertex is an ear on the current border.
2. Removing an ear deletes its two edges and adds one edge between its neighbors.
3. The hash table records that new edge, so it is never added twice.
4. Each ear is saved with both neighbors, which lets a reverse pass place it back on the border.
5. The last three survivors form a triangle. A walk from vertex 1 takes the smaller neighbor first, as required.

Four terms carry the proof.

| Term | Meaning |
| --- | --- |
| ear | degree-two vertex that can be peeled |
| diagonal | segment between two nonadjacent vertices |
| hash key | ordered pair that identifies an edge |
| border order | vertex sequence around the polygon |

They explain how the bag of edges becomes one ordered walk.

A script check of the sample reads n=4 and five edges: (1,3), (4,2), (1,2), (4,1), (2,3).
Vertex 3 has degree 2, so it peels first, and vertex 4 also has degree 2.
Restoring the ears after the triangle yields 1 3 2 4, matching the sample.

## Code

**Edge storage and keys.**
```nim
proc addGraphEdge(firstVertex, secondVertex: int) =
  let i = edgeSlotCount
  let j = i + 1
  edgeTo[i] = secondVertex
  edgeNext[i] = headEdge[firstVertex]
  headEdge[firstVertex] = i
  edgeMate[i] = j
  edgeAlive[i] = true
  edgeTo[j] = firstVertex
  edgeNext[j] = headEdge[secondVertex]
  headEdge[secondVertex] = j
  edgeMate[j] = i
  edgeAlive[j] = true
  edgeSlotCount = j + 1
  degree[firstVertex] += 1
  degree[secondVertex] += 1

proc killGraphEdge(i, j, firstVertex, secondVertex: int) =
  edgeAlive[i] = false
  edgeAlive[j] = false
  degree[firstVertex] -= 1
  degree[secondVertex] -= 1

proc edgeKeyOf(firstVertex, secondVertex: int): int =
  if firstVertex < secondVertex:
    return firstVertex * keyStride + secondVertex
  return secondVertex * keyStride + firstVertex
```

`addGraphEdge` writes both directions of an edge and updates degrees. `edgeKeyOf` sorts a pair into one canonical key. The hash lookup then sees each edge only once.

**Dataset setup.**
```nim
let datasetCount = nextInt(inputData, i)
for j in 0..<datasetCount:
  let vertexCount = nextInt(inputData, i)
  let diagonalCount = nextInt(inputData, i)
  let edgePairCount = vertexCount + diagonalCount
  let maxSlots = 2 * (edgePairCount + vertexCount) + 10

  headEdge.setLen(vertexCount + 1)
  for vertex in 0..vertexCount:
    headEdge[vertex] = -1
  edgeTo.setLen(maxSlots)
  edgeNext.setLen(maxSlots)
  edgeMate.setLen(maxSlots)
  edgeAlive.setLen(maxSlots)
  degree.setLen(vertexCount + 1)
  for vertex in 0..vertexCount:
    degree[vertex] = 0
  edgeSlotCount = 0

  var tableSize = 1
  while tableSize < 4 * (edgePairCount + vertexCount + 4):
    tableSize = tableSize shl 1
  keyTable.setLen(tableSize)
  for k in 0..<tableSize:
    keyTable[k] = 0
  keyMask = tableSize - 1
  keyStride = vertexCount + 1

  for k in 0..<edgePairCount:
    let firstVertex = nextInt(inputData, i)
    let secondVertex = nextInt(inputData, i)
    addGraphEdge(firstVertex, secondVertex)
    markGraphEdge(firstVertex, secondVertex)
```

The code sizes every array from the vertex and edge counts. It rebuilds the hash table with a power-of-two span. Each input edge is added and marked before peeling starts.

**Ear peeling queue.**
```nim
  var queue: seq[int] = @[]
  for vertex in 1..vertexCount:
    if degree[vertex] == 2:
      queue.add vertex
  var queueHead = 0
  var remainingCount = vertexCount
  var k = 0
  while queueHead < queue.len and remainingCount > 3:
    let vertex = queue[queueHead]
    queueHead += 1
    if removedVertex[vertex] or degree[vertex] != 2:
      continue
    var firstNeighbor = 0
    var secondNeighbor = 0
    var firstSlotFound = -1
    var secondSlotFound = -1
    k = headEdge[vertex]
    while k != -1:
      if edgeAlive[k]:
        if firstNeighbor == 0:
          firstNeighbor = edgeTo[k]
          firstSlotFound = k
        else:
          secondNeighbor = edgeTo[k]
          secondSlotFound = k
      k = edgeNext[k]
    if secondNeighbor == 0:
      continue
    removedVertex[vertex] = true
    remainingCount -= 1
    earVertex.add vertex
    earLeft.add firstNeighbor
    earRight.add secondNeighbor
    killGraphEdge(firstSlotFound, edgeMate[firstSlotFound], vertex, firstNeighbor)
    killGraphEdge(secondSlotFound, edgeMate[secondSlotFound], vertex, secondNeighbor)
    if not hasGraphEdge(firstNeighbor, secondNeighbor):
      addGraphEdge(firstNeighbor, secondNeighbor)
      markGraphEdge(firstNeighbor, secondNeighbor)
    if not removedVertex[firstNeighbor] and degree[firstNeighbor] == 2:
      queue.add firstNeighbor
    if not removedVertex[secondNeighbor] and degree[secondNeighbor] == 2:
      queue.add secondNeighbor

```

The queue holds vertices whose degree equals 2. Each pop links the two surviving neighbors. The loop stops once three vertices remain.

**Border rebuild and output.**
```nim
  var startSurvivor = 0
  for vertex in 1..vertexCount:
    if not removedVertex[vertex]:
      startSurvivor = vertex
      break
  nextVertex.setLen(vertexCount + 1)
  prevVertex.setLen(vertexCount + 1)
  var secondSurvivor = 0
  k = headEdge[startSurvivor]
  while k != -1:
    if edgeAlive[k] and not removedVertex[edgeTo[k]]:
      secondSurvivor = edgeTo[k]
      break
    k = edgeNext[k]
  var thirdSurvivor = 0
  k = headEdge[secondSurvivor]
  while k != -1:
    if edgeAlive[k] and edgeTo[k] != startSurvivor and not removedVertex[edgeTo[k]]:
      thirdSurvivor = edgeTo[k]
      break
    k = edgeNext[k]
  nextVertex[startSurvivor] = secondSurvivor
  prevVertex[secondSurvivor] = startSurvivor
  nextVertex[secondSurvivor] = thirdSurvivor
  prevVertex[thirdSurvivor] = secondSurvivor
  nextVertex[thirdSurvivor] = startSurvivor
  prevVertex[startSurvivor] = thirdSurvivor

  for i in 0..<earVertex.len:
    let j = earVertex.len - 1 - i
    let vertex = earVertex[j]
    let leftNeighbor = earLeft[j]
    let rightNeighbor = earRight[j]
    if nextVertex[leftNeighbor] == rightNeighbor:
      prevVertex[vertex] = leftNeighbor
      nextVertex[vertex] = rightNeighbor
      nextVertex[leftNeighbor] = vertex
      prevVertex[rightNeighbor] = vertex
    else:
      prevVertex[vertex] = rightNeighbor
      nextVertex[vertex] = leftNeighbor
      nextVertex[rightNeighbor] = vertex
      prevVertex[leftNeighbor] = vertex

  var anchor = startSurvivor
  while anchor != 1:
    anchor = nextVertex[anchor]
  let forwardNeighbor = nextVertex[1]
  let backwardNeighbor = prevVertex[1]
  var walk = forwardNeighbor
  var goBackward = false
  if backwardNeighbor < forwardNeighbor:
    walk = backwardNeighbor
    goBackward = true
  outputBuffer.add '1'
  for i in 1..<vertexCount:
    outputBuffer.add ' '
    appendOutput($walk)
    if goBackward:
      walk = prevVertex[walk]
    else:
      walk = nextVertex[walk]
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The code seeds a triangle from three survivors. Ears are inserted in reverse peel order using their saved neighbors. The walk starts at vertex 1 and takes the smaller neighbor first.


## Complexity

The hash table makes edge tests constant on average and each vertex is peeled once.

| Phase | Time | Space |
| --- | --- | --- |
| edge setup | O(n+m) | adjacency and hash arrays |
| ear peeling | O(n) expected | queue and ear records |
| border rebuild | O(n) | next and prev arrays |

All arrays are reused across datasets, so no per-ear allocation occurs.

Big O uses vertex count n and diagonal count m.

| Measure | Big O |
| --- | --- |
| time | O(n+m) expected per dataset |
| space | O(n+m) |

A permutation search would take factorial time, while peeling is linear.
