# SERVERS — Servers (SPOJ)
<https://www.spoj.com/problems/SERVERS/>

## Problem

Servers in a connected network carry ranks and positive wire times. A server W interests V when no server within distance D(V,W) of V outranks W; sum the sizes of all interest sets.

Input: an integer z, then z cases. Each case gives server count n and wire count m, then n ranks, then m triples a, b, t. Output: one integer per case, the total number of interesting pairs.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Test cases | z from input |
| Servers n | 1 to 30000 |
| Wires m | 1 to 5n |
| Rank r | 1 to 10 |
| Wire time t | 1 to 1000 ms |
| Judge time limit | 1335 ms |
| Judge memory limit | 1536 MB |

The builder guarantees the answer stays below 30 times n.

The sample input:

```
1
4 3
2
3
1
1
1 4 30
2 3 20
3 4 20
```

The sample output:

```
9
```

## Idea

Count nearby servers by racing waves outward from each rank, like ripples in a pond. The strongest servers interest everyone. A weaker server V becomes interesting only where no stronger or equally strong server has arrived first.

The program runs Dijkstra from all top-rank servers at once. Then it processes lower ranks one level at a time, stopping the wave whenever it reaches a server with a better distance already known. Each server is counted once per rank level. One Dijkstra pass costs O(m log n), and only ten rank levels exist. A separate search from every server would multiply that work by n.

Ten rank waves replace thirty thousand searches.

## Why It Works

Four facts carry the program.

1. A server with the top rank interests every server, because no other rank exceeds it. Each of the n servers therefore contributes n pairs at the top level.
2. For a weaker server, a candidate must beat the distance already known from a stronger server. The wave stops at that boundary.
3. Processing ranks from high to low makes `bestDistance` complete before any lower rank runs. Equal distances are excluded, so ties never add a pair.
4. The builder bounds the answer by 30 times n, so the total fits comfortably in 64 bits.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `bestDistance` | shortest distance from any stronger server |
| `nextBestDistance` | new distances found at the current rank |
| `sourcesByRank` | server lists grouped by rank |
| `totalInteresting` | running sum of all interest pairs |

The `visitGeneration` stamp avoids clearing a visited array per source.

A script traces the sample network with four servers.

```text
ranks: server1=2 server2=3 server3=1 server4=1
top rank 3 sources: server2
top-level pairs: 4 servers times 1 source = 4
rank 2: server1 at distance 30, only itself before a better node -> 1
rank 1: server3 reaches server4 at 20, server4 reaches server3 at 20 -> 4
total 4 + 1 + 4 = 9
```

The answer is 9, matching the sample. Distances are integers, so no rounding appears.

## Code

**Input and output plumbing.** Bulk reads and a binary heap share one buffer.

```nim
{.push checks: off.}
{.optimization: speed.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infiniteDistance = 1000000000
const initialHeapCapacity = 1024

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int {.inline.} =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) {.inline.} =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One line loop fills the buffer, so parsing stays local. The scanner skips non-digits and handles no sign.

**Heap push.** The array doubles when full.

```nim
var heapDistance = newSeq[int](initialHeapCapacity)
var heapVertex = newSeq[int](initialHeapCapacity)
var heapSize = 0

proc pushHeap(distanceValue: int, vertex: int) {.inline.} =
  if heapSize == heapDistance.len:
    heapDistance.setLen(heapSize * 2)
    heapVertex.setLen(heapSize * 2)
  var i = heapSize
  heapSize += 1
  while i > 0:
    let j = (i - 1) div 2
    if heapDistance[j] <= distanceValue:
      break
    heapDistance[i] = heapDistance[j]
    heapVertex[i] = heapVertex[j]
    i = j
  heapDistance[i] = distanceValue
  heapVertex[i] = vertex
```

The parent index is `(i - 1) div 2`. Sifting up costs O(log n) per push.

**Heap pop.** The last element sifts down.

```nim
var poppedDistance = 0
var poppedVertex = 0

proc popHeap() {.inline.} =
  poppedDistance = heapDistance[0]
  poppedVertex = heapVertex[0]
  heapSize -= 1
  if heapSize > 0:
    let lastDistance = heapDistance[heapSize]
    let lastVertex = heapVertex[heapSize]
    var i = 0
    while true:
      let j = i * 2 + 1
      if j >= heapSize:
        break
      let k = j + 1
      var l = j
      if k < heapSize and heapDistance[k] < heapDistance[j]:
        l = k
      if heapDistance[l] >= lastDistance:
        break
      heapDistance[i] = heapDistance[l]
      heapVertex[i] = heapVertex[l]
      i = l
    heapDistance[i] = lastDistance
    heapVertex[i] = lastVertex
```

The smaller child wins each step. The smallest distance is always at index zero.

**Top-rank wave.** All strongest sources start together.

```nim
var sourcesByRank: array[11, seq[int]]

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let serverCount = nextInt(inputData, i)
  let wireCount = nextInt(inputData, i)

  for k in 1..10:
    sourcesByRank[k].setLen 0
  for l in 1..serverCount:
    let k = nextInt(inputData, i)
    sourcesByRank[k].add l

  var edgeHead = newSeq[int](serverCount + 1)
  var edgeTarget = newSeq[int](2 * wireCount + 1)
  var edgeWeight = newSeq[int](2 * wireCount + 1)
  var nextEdge = newSeq[int](2 * wireCount + 1)
  var l = 0
  for k in 0..<wireCount:
    let endpointA = nextInt(inputData, i)
    let endpointB = nextInt(inputData, i)
    let transmissionTime = nextInt(inputData, i)
    l += 1
    edgeTarget[l] = endpointB
    edgeWeight[l] = transmissionTime
    nextEdge[l] = edgeHead[endpointA]
    edgeHead[endpointA] = l
    l += 1
    edgeTarget[l] = endpointA
    edgeWeight[l] = transmissionTime
    nextEdge[l] = edgeHead[endpointB]
    edgeHead[endpointB] = l

  var bestDistance = newSeq[int](serverCount + 1)
  var nextBestDistance = newSeq[int](serverCount + 1)
  var visitGeneration = newSeq[int](serverCount + 1)
  for l in 1..serverCount:
    bestDistance[l] = infiniteDistance

  var topRank = 1
  var rankScan = 10
  while rankScan >= 1:
    if sourcesByRank[rankScan].len > 0:
      topRank = rankScan
      break
    rankScan -= 1

  heapSize = 0
  for l in 0..<sourcesByRank[topRank].len:
    pushHeap(0, sourcesByRank[topRank][l])
  while heapSize > 0:
    popHeap()
    if poppedDistance > bestDistance[poppedVertex]:
      continue
    bestDistance[poppedVertex] = poppedDistance
    var k = edgeHead[poppedVertex]
    while k != 0:
      let candidateDistance = poppedDistance + edgeWeight[k]
      if candidateDistance < bestDistance[edgeTarget[k]]:
        pushHeap(candidateDistance, edgeTarget[k])
      k = nextEdge[k]
```

Each wire is stored twice, so both directions are walkable. `edgeHead` starts a linked list per server. The multi-source pass fills `bestDistance` for the top rank.

**Lower-rank waves.** Each weaker rank stops at known better distances.

```nim
  var totalInteresting: int64 = int64(sourcesByRank[topRank].len * serverCount)
  var generationStamp = 0
  var k = topRank - 1
  while k >= 1:
    if sourcesByRank[k].len > 0:
      for l in 1..serverCount:
        nextBestDistance[l] = infiniteDistance
      for l in 0..<sourcesByRank[k].len:
        let sourceVertex = sourcesByRank[k][l]
        generationStamp += 1
        heapSize = 0
        pushHeap(0, sourceVertex)
        while heapSize > 0:
          popHeap()
          let currentVertex = poppedVertex
          let waveDistance = poppedDistance
          if visitGeneration[currentVertex] == generationStamp:
            continue
          if waveDistance >= bestDistance[currentVertex]:
            continue
          visitGeneration[currentVertex] = generationStamp
          totalInteresting += 1
          if waveDistance < nextBestDistance[currentVertex]:
            nextBestDistance[currentVertex] = waveDistance
          var k = edgeHead[currentVertex]
          while k != 0:
            let neighborVertex = edgeTarget[k]
            let candidateDistance = waveDistance + edgeWeight[k]
            if candidateDistance < bestDistance[neighborVertex] and visitGeneration[neighborVertex] != generationStamp:
              pushHeap(candidateDistance, neighborVertex)
            k = nextEdge[k]
      for l in 1..serverCount:
        if nextBestDistance[l] < bestDistance[l]:
          bestDistance[l] = nextBestDistance[l]
    k -= 1

  appendOutput($totalInteresting)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The generation stamp replaces a per-source visited clear. Only ranks below the top run this loop. After each rank, better distances update `bestDistance` for the next level.

## Complexity

Heap work dominates each rank wave.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(B) for B bytes | B bytes |
| Graph build | O(n + m) | O(n + m) |
| Top-rank Dijkstra | O(m log n) | O(n) |
| Lower-rank waves | at most 9 times O(m log n) | O(n) |
| Output | O(z) lines | one block |

Ranks run from 10 down to 1, so at most ten waves occur.

| Measure | Big O |
| --- | --- |
| Time | O(10 times m log n) per case |
| Space | O(n + m) per case |

A search from every server would cost O(n times m log n) per case.
