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

var scanPos = 0

proc nextInt(data: string, position: var int): int {.inline.} =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
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
  var holeIndex = heapSize
  heapSize += 1
  while holeIndex > 0:
    let parentIndex = (holeIndex - 1) div 2
    if heapDistance[parentIndex] <= distanceValue:
      break
    heapDistance[holeIndex] = heapDistance[parentIndex]
    heapVertex[holeIndex] = heapVertex[parentIndex]
    holeIndex = parentIndex
  heapDistance[holeIndex] = distanceValue
  heapVertex[holeIndex] = vertex

var poppedDistance = 0
var poppedVertex = 0

proc popHeap() {.inline.} =
  poppedDistance = heapDistance[0]
  poppedVertex = heapVertex[0]
  heapSize -= 1
  if heapSize > 0:
    let lastDistance = heapDistance[heapSize]
    let lastVertex = heapVertex[heapSize]
    var holeIndex = 0
    while true:
      let leftChild = holeIndex * 2 + 1
      if leftChild >= heapSize:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < heapSize and heapDistance[rightChild] < heapDistance[leftChild]:
        smallerChild = rightChild
      if heapDistance[smallerChild] >= lastDistance:
        break
      heapDistance[holeIndex] = heapDistance[smallerChild]
      heapVertex[holeIndex] = heapVertex[smallerChild]
      holeIndex = smallerChild
    heapDistance[holeIndex] = lastDistance
    heapVertex[holeIndex] = lastVertex
```

`pushHeap` grows the two arrays only when `heapSize` reaches their length. `popHeap` moves the last entry down through the smaller child. Each operation touches one root-to-leaf path and costs O(log n).

Each case builds adjacency and fills the top-rank cutoff.

```nim
var sourcesByRank: array[11, seq[int]]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let serverCount = nextInt(inputData, scanPos)
  let wireCount = nextInt(inputData, scanPos)

  for rankValue in 1..10:
    sourcesByRank[rankValue].setLen 0
  for serverIndex in 1..serverCount:
    let rankValue = nextInt(inputData, scanPos)
    sourcesByRank[rankValue].add serverIndex

  var edgeHead = newSeq[int](serverCount + 1)
  var edgeTarget = newSeq[int](2 * wireCount + 1)
  var edgeWeight = newSeq[int](2 * wireCount + 1)
  var nextEdge = newSeq[int](2 * wireCount + 1)
  var edgeCursor = 0
  for wireIndex in 0..<wireCount:
    let endpointA = nextInt(inputData, scanPos)
    let endpointB = nextInt(inputData, scanPos)
    let transmissionTime = nextInt(inputData, scanPos)
    edgeCursor += 1
    edgeTarget[edgeCursor] = endpointB
    edgeWeight[edgeCursor] = transmissionTime
    nextEdge[edgeCursor] = edgeHead[endpointA]
    edgeHead[endpointA] = edgeCursor
    edgeCursor += 1
    edgeTarget[edgeCursor] = endpointA
    edgeWeight[edgeCursor] = transmissionTime
    nextEdge[edgeCursor] = edgeHead[endpointB]
    edgeHead[endpointB] = edgeCursor

  var bestDistance = newSeq[int](serverCount + 1)
  var nextBestDistance = newSeq[int](serverCount + 1)
  var visitGeneration = newSeq[int](serverCount + 1)
  for serverIndex in 1..serverCount:
    bestDistance[serverIndex] = infiniteDistance

  var topRank = 1
  var rankScan = 10
  while rankScan >= 1:
    if sourcesByRank[rankScan].len > 0:
      topRank = rankScan
      break
    rankScan -= 1

  heapSize = 0
  for sourceIndex in 0..<sourcesByRank[topRank].len:
    pushHeap(0, sourcesByRank[topRank][sourceIndex])
  while heapSize > 0:
    popHeap()
    if poppedDistance > bestDistance[poppedVertex]:
      continue
    bestDistance[poppedVertex] = poppedDistance
    var edgeIndex = edgeHead[poppedVertex]
    while edgeIndex != 0:
      let candidateDistance = poppedDistance + edgeWeight[edgeIndex]
      if candidateDistance < bestDistance[edgeTarget[edgeIndex]]:
        pushHeap(candidateDistance, edgeTarget[edgeIndex])
      edgeIndex = nextEdge[edgeIndex]

  var totalInteresting: int64 = int64(sourcesByRank[topRank].len * serverCount)
```

The rank loop runs at most 10 times, and the edge loop runs `wireCount` times. `edgeHead` stores the newest edge at each vertex, so adjacency stays in flat arrays. One multi-source Dijkstra fills `bestDistance` for the top rank.

Lower ranks count their pairs and update the cutoff.

```nim
  var generationStamp = 0
  var rankValue = topRank - 1
  while rankValue >= 1:
    if sourcesByRank[rankValue].len > 0:
      for serverIndex in 1..serverCount:
        nextBestDistance[serverIndex] = infiniteDistance
      for sourceIndex in 0..<sourcesByRank[rankValue].len:
        let sourceVertex = sourcesByRank[rankValue][sourceIndex]
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
          var edgeIndex = edgeHead[currentVertex]
          while edgeIndex != 0:
            let neighborVertex = edgeTarget[edgeIndex]
            let candidateDistance = waveDistance + edgeWeight[edgeIndex]
            if candidateDistance < bestDistance[neighborVertex] and visitGeneration[neighborVertex] != generationStamp:
              pushHeap(candidateDistance, neighborVertex)
            edgeIndex = nextEdge[edgeIndex]
      for serverIndex in 1..serverCount:
        if nextBestDistance[serverIndex] < bestDistance[serverIndex]:
          bestDistance[serverIndex] = nextBestDistance[serverIndex]
    rankValue -= 1

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
