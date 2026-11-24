const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const readChunkBytes = 1 shl 20
const unreachable = 1 shl 60

{.push checks: off.}
{.passC: "-O3".}

proc nextInt(data: string, pos: var int): int {.inline.} =
  var i = pos
  let dataLen = data.len
  while i < dataLen and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < dataLen and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  pos = i
  return value

var inputData = ""
var readChunk = newString(readChunkBytes)
while true:
  let bytesRead = stdin.readBuffer(readChunk[0].addr, readChunk.len)
  if bytesRead == 0:
    break
  let startPos = inputData.len
  inputData.setLen(startPos + bytesRead)
  copyMem(inputData[startPos].addr, readChunk[0].addr, bytesRead)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanAt = 0
let caseCount = nextInt(inputData, scanAt)
var scanProbe = scanAt
var largestNodeCount = 0
var largestStreetCount = 0
for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanProbe)
  let streetCount = nextInt(inputData, scanProbe)
  let bagCount = nextInt(inputData, scanProbe)
  if nodeCount > largestNodeCount:
    largestNodeCount = nodeCount
  if streetCount > largestStreetCount:
    largestStreetCount = streetCount
  for streetIndex in 0..<streetCount:
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
  for bagIndex in 0..<bagCount:
    discard nextInt(inputData, scanProbe)

let maxNodeCount = largestNodeCount + 2
let maxArcCount = 2 * largestStreetCount + 5
let maxStreetCount = largestStreetCount + 2

var arcStart = newSeq[int](maxNodeCount + 2)
var arcCursor = newSeq[int](maxNodeCount + 2)
var arcCount = newSeq[int](maxNodeCount + 2)
var arcTo = newSeq[int](maxArcCount)
var arcWeight = newSeq[int](maxArcCount)
var arcReverse = newSeq[int](maxArcCount)
var tempFrom = newSeq[int](maxStreetCount)
var tempTarget = newSeq[int](maxStreetCount)
var tempForward = newSeq[int](maxStreetCount)
var tempBackward = newSeq[int](maxStreetCount)
var distArr = newSeq[int](maxNodeCount + 2)
var isBagArr = newSeq[bool](maxNodeCount + 2)
var isParentArc = newSeq[bool](maxArcCount)
var heapNode = newSeq[int](maxArcCount)
var heapDist = newSeq[int](maxArcCount)
var ordered = newSeq[int](maxNodeCount + 2)
var sortTemp = newSeq[int](maxNodeCount + 2)
var survivalNum = newSeq[int64](maxNodeCount + 2)
var survivalDen = newSeq[int64](maxNodeCount + 2)
var heapSize = 0
var poppedDist = 0

proc heapPush(nodeIndex, nodeDist: int) {.inline.} =
  var i = heapSize
  heapSize += 1
  while i > 0:
    let parentIndex = (i - 1) div 2
    if heapDist[parentIndex] <= nodeDist:
      break
    heapNode[i] = heapNode[parentIndex]
    heapDist[i] = heapDist[parentIndex]
    i = parentIndex
  heapNode[i] = nodeIndex
  heapDist[i] = nodeDist

proc heapPop(): int {.inline.} =
  result = heapNode[0]
  poppedDist = heapDist[0]
  heapSize -= 1
  if heapSize == 0:
    return
  let lastNode = heapNode[heapSize]
  let lastDist = heapDist[heapSize]
  var i = 0
  while true:
    let leftChild = 2 * i + 1
    if leftChild >= heapSize:
      break
    let rightChild = leftChild + 1
    var child = leftChild
    if rightChild < heapSize and heapDist[rightChild] < heapDist[leftChild]:
      child = rightChild
    if heapDist[child] >= lastDist:
      break
    heapNode[i] = heapNode[child]
    heapDist[i] = heapDist[child]
    i = child
  heapNode[i] = lastNode
  heapDist[i] = lastDist

proc siftDown(values: var seq[int], rootIndex, endIndex: int) {.inline.} =
  var root = rootIndex
  while true:
    var child = 2 * root + 1
    if child > endIndex:
      break
    if child < endIndex and distArr[values[child]] > distArr[values[child + 1]]:
      child += 1
    if distArr[values[root]] <= distArr[values[child]]:
      break
    swap(values[root], values[child])
    root = child

proc sortByDistance(values: var seq[int], count: int) =
  var startIndex = count div 2 - 1
  while startIndex >= 0:
    siftDown(values, startIndex, count - 1)
    startIndex -= 1
  var finish = count - 1
  while finish > 0:
    swap(values[0], values[finish])
    siftDown(values, 0, finish - 1)
    finish -= 1

for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanAt)
  let streetCount = nextInt(inputData, scanAt)
  let bagCount = nextInt(inputData, scanAt)
  let arcTotal = 2 * streetCount

  for nodeIndex in 1..nodeCount:
    arcCount[nodeIndex] = 0
    distArr[nodeIndex] = unreachable
    isBagArr[nodeIndex] = false

  for streetIndex in 0..<streetCount:
    let u = nextInt(inputData, scanAt)
    let v = nextInt(inputData, scanAt)
    tempFrom[streetIndex] = u
    tempTarget[streetIndex] = v
    tempForward[streetIndex] = nextInt(inputData, scanAt)
    tempBackward[streetIndex] = nextInt(inputData, scanAt)
    arcCount[u] += 1
    arcCount[v] += 1

  arcStart[1] = 0
  for nodeIndex in 1..nodeCount:
    arcStart[nodeIndex + 1] = arcStart[nodeIndex] + arcCount[nodeIndex]
    arcCursor[nodeIndex] = arcStart[nodeIndex]

  for streetIndex in 0..<streetCount:
    let u = tempFrom[streetIndex]
    let v = tempTarget[streetIndex]
    let forwardArc = arcCursor[u]
    arcCursor[u] += 1
    arcTo[forwardArc] = v
    arcWeight[forwardArc] = tempForward[streetIndex]
    let backwardArc = arcCursor[v]
    arcCursor[v] += 1
    arcTo[backwardArc] = u
    arcWeight[backwardArc] = tempBackward[streetIndex]
    arcReverse[forwardArc] = backwardArc
    arcReverse[backwardArc] = forwardArc

  for bagIndex in 0..<bagCount:
    let bagNode = nextInt(inputData, scanAt)
    isBagArr[bagNode] = true
    distArr[bagNode] = 0

  heapSize = 0
  for nodeIndex in 1..nodeCount:
    if isBagArr[nodeIndex]:
      heapPush(nodeIndex, 0)

  while heapSize > 0:
    let nodeIndex = heapPop()
    if poppedDist != distArr[nodeIndex]:
      continue
    let baseDist = distArr[nodeIndex]
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      let nextDist = baseDist + arcWeight[arcIndex]
      let target = arcTo[arcIndex]
      if nextDist < distArr[target]:
        distArr[target] = nextDist
        heapPush(target, nextDist)

  for arcIndex in 0..<arcTotal:
    isParentArc[arcIndex] = false
  for nodeIndex in 1..nodeCount:
    if isBagArr[nodeIndex]:
      continue
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      if distArr[arcTo[arcIndex]] + arcWeight[arcReverse[arcIndex]] == distArr[nodeIndex]:
        isParentArc[arcIndex] = true

  for nodeIndex in 1..nodeCount:
    ordered[nodeIndex - 1] = nodeIndex
  sortByDistance(ordered, nodeCount)

  for sliceIndex in 0..<nodeCount:
    let nodeIndex = ordered[sliceIndex]
    if distArr[nodeIndex] == unreachable:
      continue
    var bestNum: int64 = 0
    var bestDen: int64 = 1
    var haveBest = false
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      if not isParentArc[arcIndex]:
        let target = arcTo[arcIndex]
        let forwardWeight = arcWeight[arcIndex]
        let arrive = distArr[nodeIndex] + forwardWeight
        var valueNum: int64 = 0
        var valueDen: int64 = 1
        if arrive == distArr[target]:
          valueNum = survivalNum[target]
          valueDen = survivalDen[target]
        elif distArr[target] < arrive and distArr[nodeIndex] < distArr[target] + arcWeight[arcReverse[arcIndex]]:
          valueNum = int64(distArr[nodeIndex]) * arcWeight[arcReverse[arcIndex]] +
                     int64(distArr[target]) * forwardWeight +
                     int64(forwardWeight) * arcWeight[arcReverse[arcIndex]]
          valueDen = int64(forwardWeight + arcWeight[arcReverse[arcIndex]])
        else:
          valueNum = int64(arrive)
          valueDen = 1
        if not haveBest or valueNum * bestDen > bestNum * valueDen:
          bestNum = valueNum
          bestDen = valueDen
          haveBest = true
    if not haveBest:
      bestNum = int64(distArr[nodeIndex])
      bestDen = 1
    survivalNum[nodeIndex] = bestNum
    survivalDen[nodeIndex] = bestDen

  var hasHidden = false
  for nodeIndex in 1..nodeCount:
    if distArr[nodeIndex] == unreachable:
      hasHidden = true
      break

  if hasHidden:
    var firstWritten = true
    for nodeIndex in 1..nodeCount:
      if distArr[nodeIndex] == unreachable:
        if not firstWritten:
          appendOutput(" ")
        appendOutput($(nodeIndex))
        firstWritten = false
    appendOutput("\n")
    continue

  var maxNum: int64 = survivalNum[1]
  var maxDen: int64 = survivalDen[1]
  for nodeIndex in 2..nodeCount:
    if survivalNum[nodeIndex] * maxDen > maxNum * survivalDen[nodeIndex]:
      maxNum = survivalNum[nodeIndex]
      maxDen = survivalDen[nodeIndex]

  var firstWritten = true
  for nodeIndex in 1..nodeCount:
    if survivalNum[nodeIndex] * maxDen == maxNum * survivalDen[nodeIndex]:
      if not firstWritten:
        appendOutput(" ")
      appendOutput($(nodeIndex))
      firstWritten = false
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
