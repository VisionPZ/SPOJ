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
