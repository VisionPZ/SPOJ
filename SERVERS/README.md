## Problem

Read a connected network of `n` servers and `m` weighted wires, plus one rank per server. Server W is interesting for server V when no server within distance D(V,W) of V has a rank above r(W). Print the total size of all interesting sets as one integer per test case.

The statement sets these limits.

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded |
| Servers per case | 1 to 30000 |
| Wires per case | 1 to 5n |
| Rank | 1 to 10 |
| Answer | at most 30n |
| Time limit | 1335 ms |
| Memory limit | 1536 MB |

The 30n bound keeps the counted work proportional to the answer.

## Idea

`bestDistance[V]` stores the distance from V to the closest server of strictly higher rank. A server of rank r is interesting for V exactly when its distance from V is below `bestDistance[V]`. Process ranks from high to low and grow one Dijkstra wave from each server of the current rank. The top rank needs one multi-source Dijkstra and one multiplication, because every top-rank server is interesting for every server.

Cost per visited pair: one heap pop and at most 10 edge checks.

## Why It Works

A server W of rank r qualifies when the largest rank within distance D(V,W) of V equals r. That happens exactly when no server of higher rank lies within that distance.

The program keeps these three values.

```
bestDistance[V]     = min D(V,U) for every U with r(U) > r
nextBestDistance[V] = min D(V,W) over sources W of rank r
count increase      = one per popped (source, vertex) pair within bestDistance[V]
```

`bestDistance[V]` is the higher-rank cutoff for the current rank. `nextBestDistance[V]` becomes the cutoff for the next lower rank. The count rises only for pairs below the cutoff.

A wave must stop at a vertex u once its path distance reaches `bestDistance[u]`. Take a wire of weight w from u to x. The path reaches x at distance at least `bestDistance[u] + w`, and `bestDistance[x]` is at most that value. Therefore x cannot be interesting through u, and the prune is safe.

Every prefix of a shortest path to an interesting vertex also stays below its own cutoff. Otherwise the final distance would reach or exceed `bestDistance` at the target, which is impossible. So the prune never hides a pair that counts.

The sample graph gives these records; an asterisk marks an interesting server, and `r2` means rank 2.

```
V=1: 1(0,r2)* 4(30,r1) 3(50,r1) 2(70,r3)*  -> 2
V=2: 2(0,r3)* 3(20,r1) 4(40,r1) 1(70,r2)  -> 1
V=3: 3(0,r1)* 2(20,r3)* 4(20,r1) 1(50,r2)  -> 2
V=4: 4(0,r1)* 3(20,r1)* 1(30,r2)* 2(40,r3)*  -> 4
```

The four counts add to 9, the sample answer.

## Code

Input and output use one buffer each.

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

The read loop handles every input line once. `nextInt` skips separators, so spaces and blank lines cannot shift the scan. The output buffer flushes at `flushBlockBytes`, which keeps writes in large blocks.

The heap holds vertex and distance pairs in flat arrays.

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

`pushHeap` grows the two arrays only when `heapSize` reaches their length. `popHeap` moves the last entry down through the smaller child. Each operation touches one root-to-leaf path and costs O(log n).

Each case builds adjacency and fills the top-rank cutoff.

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

  var totalInteresting: int64 = int64(sourcesByRank[topRank].len * serverCount)
```

The rank loop runs at most 10 times, and the edge loop runs `wireCount` times. `edgeHead` stores the newest edge at each vertex, so adjacency stays in flat arrays. One multi-source Dijkstra fills `bestDistance` for the top rank.

Lower ranks count their pairs and update the cutoff.

```nim
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

The rank loop visits the ranks below `topRank`, and each source starts one wave. `generationStamp` stops one source from counting a vertex twice. The `currentDistance >= bestDistance[currentVertex]` test prunes paths that cannot count.

## Complexity

The table gives the cost of each phase for one case. A is the number of interesting pairs, and A is at most 30n.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input size) | O(input size) |
| Case setup | O(n + m) | O(n + m) |
| Top-rank Dijkstra | O((n + m) log n) | O(n) |
| Lower-rank waves | O(A * 10 log n) | O(n) |

Input scan dominates memory, and the waves dominate time when the answer is large. Across all cases the program takes O(input size + A * 10 log n) time and O(input size + n + m) space. A naive run of Dijkstra from every server costs O(n * m log n) per case.
