## Problem

Read a polygon described by its sides and some of its diagonals. The edges arrive in any order, and the diagonals never cross. Print the vertices in border order, starting at vertex 1, with the smaller neighbor of vertex 1 second.

The judge bounds are:

| Item | Limit |
| --- | --- |
| Data sets | 1 to 20 |
| Vertices per polygon | 3 to 10 000 |
| Diagonals per polygon | 0 to n - 3 |
| Time per run | 7 000 ms |
| Memory per run | 1 536 MB |

Every data set fits in one pass over its edge list.

## Idea

Every polygon with noncrossing diagonals has a vertex with only two edges. Clip that vertex, add the edge between its two neighbors, and repeat until three vertices remain. This touches each edge a constant number of times; trying every vertex order instead takes factorial work.

## Why It Works

A graph drawn with all vertices on a circle and no crossing edges is outerplanar. Every outerplanar graph has a vertex with at most two edges. The border guarantees at least two, so a vertex with exactly two always exists.

When we clip such a vertex, its two neighbors become consecutive on a smaller polygon. Adding their edge keeps that smaller graph outerplanar, so another clip always exists. Reversing the clip list puts every vertex back between its original two neighbors.

We store each unordered edge pair as one integer. The key packs two labels into one number, and the hash table finds that key in constant time on average.

The key terms are:

| Term | Meaning |
| --- | --- |
| `keyStride` | `vertexCount + 1`, larger than every label |
| `firstVertex * keyStride + secondVertex` | key for the pair with the smaller label first |
| `wanted and keyMask` | first hash slot for a key |

The mask keeps the slot inside the table, and linear probing resolves collisions.

A small polygon shows every step:

| Step | Action | Border |
| --- | --- | --- |
| start | degrees 1:4 2:2 3:3 4:3 5:2 | 1 2 3 4 5 |
| clip 2 | neighbors 1 and 3, chord present | 1 3 4 5 |
| clip 3 | neighbors 1 and 4, chord present | 1 4 5 |
| insert 3 | between 1 and 4 | 1 3 4 5 |
| insert 2 | between 1 and 3 | 1 2 3 4 5 |

The last row matches the required border order.

## Code

Text first goes into one buffer, and a hand scanner reads integers from it. Output goes into one buffer that flushes in large blocks.

```
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The loop reads every line once, so the input buffer costs O(input bytes). `$walk` writes an integer, and `appendOutput` keeps at most one block in memory.

Then comes the graph storage and edge lookup.

```
proc addGraphEdge(firstVertex, secondVertex: int) =
  let firstSlot = edgeSlotCount
  let secondSlot = firstSlot + 1
  edgeTo[firstSlot] = secondVertex
  edgeNext[firstSlot] = headEdge[firstVertex]
  headEdge[firstVertex] = firstSlot
  edgeMate[firstSlot] = secondSlot
  edgeAlive[firstSlot] = true
  edgeTo[secondSlot] = firstVertex
  edgeNext[secondSlot] = headEdge[secondVertex]
  headEdge[secondVertex] = secondSlot
  edgeMate[secondSlot] = firstSlot
  edgeAlive[secondSlot] = true
  edgeSlotCount = secondSlot + 1
  degree[firstVertex] += 1
  degree[secondVertex] += 1

proc killGraphEdge(firstSlot, secondSlot, firstVertex, secondVertex: int) =
  edgeAlive[firstSlot] = false
  edgeAlive[secondSlot] = false
  degree[firstVertex] -= 1
  degree[secondVertex] -= 1

proc edgeKeyOf(firstVertex, secondVertex: int): int =
  if firstVertex < secondVertex:
    return firstVertex * keyStride + secondVertex
  return secondVertex * keyStride + firstVertex

proc hasGraphEdge(firstVertex, secondVertex: int): bool =
  let wanted = edgeKeyOf(firstVertex, secondVertex)
  var slot = wanted and keyMask
  while keyTable[slot] != 0:
    if keyTable[slot] == wanted:
      return true
    slot = (slot + 1) and keyMask
  return false

proc markGraphEdge(firstVertex, secondVertex: int) =
  let wanted = edgeKeyOf(firstVertex, secondVertex)
  var slot = wanted and keyMask
  while keyTable[slot] != 0:
    if keyTable[slot] == wanted:
      return
    slot = (slot + 1) and keyMask
  keyTable[slot] = wanted
```

`edgeSlotCount` grows by two per edge, and the arrays are sized for the maximum. `keyTable` holds zero in an empty slot, so no separate used flag is needed. Each lookup scans at most a few slots on average.

The setup resets the arrays per data set and reads the edge pairs.

```
let datasetCount = nextInt(inputData, scanPos)
for datasetIndex in 0..<datasetCount:
  let vertexCount = nextInt(inputData, scanPos)
  let diagonalCount = nextInt(inputData, scanPos)
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
  for slot in 0..<tableSize:
    keyTable[slot] = 0
  keyMask = tableSize - 1
  keyStride = vertexCount + 1

  for edgeIndex in 0..<edgePairCount:
    let firstVertex = nextInt(inputData, scanPos)
    let secondVertex = nextInt(inputData, scanPos)
    addGraphEdge(firstVertex, secondVertex)
    markGraphEdge(firstVertex, secondVertex)
```

The table size is a power of two at least four times the edge count. That keeps the load low. Each edge is inserted once.

The clipping loop builds the ear list.

```
  var queue: seq[int] = @[]
  for vertex in 1..vertexCount:
    if degree[vertex] == 2:
      queue.add vertex
  var queueHead = 0
  var remainingCount = vertexCount
  var slot = 0
  while queueHead < queue.len and remainingCount > 3:
    let vertex = queue[queueHead]
    queueHead += 1
    if removedVertex[vertex] or degree[vertex] != 2:
      continue
    var firstNeighbor = 0
    var secondNeighbor = 0
    var firstSlotFound = -1
    var secondSlotFound = -1
    slot = headEdge[vertex]
    while slot != -1:
      if edgeAlive[slot]:
        if firstNeighbor == 0:
          firstNeighbor = edgeTo[slot]
          firstSlotFound = slot
        else:
          secondNeighbor = edgeTo[slot]
          secondSlotFound = slot
      slot = edgeNext[slot]
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

The loop ends after n - 3 clips. Dead edge slots stay in the lists, but each clip scans its own vertex once. The hash table answers the chord question in constant time on average.

The last block rebuilds the cycle and writes the answer.

```
  var startSurvivor = 0
  for vertex in 1..vertexCount:
    if not removedVertex[vertex]:
      startSurvivor = vertex
      break
  nextVertex.setLen(vertexCount + 1)
  prevVertex.setLen(vertexCount + 1)
  var secondSurvivor = 0
  slot = headEdge[startSurvivor]
  while slot != -1:
    if edgeAlive[slot] and not removedVertex[edgeTo[slot]]:
      secondSurvivor = edgeTo[slot]
      break
    slot = edgeNext[slot]
  var thirdSurvivor = 0
  slot = headEdge[secondSurvivor]
  while slot != -1:
    if edgeAlive[slot] and edgeTo[slot] != startSurvivor and not removedVertex[edgeTo[slot]]:
      thirdSurvivor = edgeTo[slot]
      break
    slot = edgeNext[slot]
  nextVertex[startSurvivor] = secondSurvivor
  prevVertex[secondSurvivor] = startSurvivor
  nextVertex[secondSurvivor] = thirdSurvivor
  prevVertex[thirdSurvivor] = secondSurvivor
  nextVertex[thirdSurvivor] = startSurvivor
  prevVertex[startSurvivor] = thirdSurvivor

  for step in 0..<earVertex.len:
    let earIndex = earVertex.len - 1 - step
    let vertex = earVertex[earIndex]
    let leftNeighbor = earLeft[earIndex]
    let rightNeighbor = earRight[earIndex]
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
  for position in 1..<vertexCount:
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

The rebuild loop runs earVertex.len times. `nextVertex` and `prevVertex` make each insert constant time. The direction test guarantees vertex 1 gets the smaller neighbor second.

## Complexity

Reading and edge insertion take O(n + m) time per data set. Clipping takes O(n + m) expected time, since each edge dies once. Rebuilding and printing take O(n) time.

The total time is O(n + m) per data set and linear over the whole input. Space is also O(n + m) per data set. Trying every vertex order would take O(n!) time.
