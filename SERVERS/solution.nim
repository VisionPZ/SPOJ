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
