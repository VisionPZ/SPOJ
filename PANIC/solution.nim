const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const readChunkBytes = 1 shl 20
const unreachable = 1 shl 60

{.push checks: off.}
{.passC: "-O3".}

proc nextInt(data: string, pos: var int): int {.inline.} =
  var curPos = pos
  let dataLen = data.len
  while curPos < dataLen and (data[curPos] < '0' or data[curPos] > '9'):
    curPos += 1
  var value = 0
  while curPos < dataLen and data[curPos] >= '0' and data[curPos] <= '9':
    value = value * 10 + int(data[curPos]) - firstDigitValue
    curPos += 1
  pos = curPos
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
var streetFrom = newSeq[int](maxStreetCount)
var streetTarget = newSeq[int](maxStreetCount)
var streetForward = newSeq[int](maxStreetCount)
var streetBackward = newSeq[int](maxStreetCount)
var minDist = newSeq[int](maxNodeCount + 2)
var isBagNode = newSeq[bool](maxNodeCount + 2)
var isParentArc = newSeq[bool](maxArcCount)
var heapNode = newSeq[int](maxArcCount)
var heapDist = newSeq[int](maxArcCount)
var ordered = newSeq[int](maxNodeCount + 2)
var survivalNum = newSeq[int64](maxNodeCount + 2)
var survivalDen = newSeq[int64](maxNodeCount + 2)
var heapSize = 0
var poppedDist = 0

proc heapPush(nodeIndex, nodeDist: int) {.inline.} =
  var idx = heapSize
  heapSize += 1
  while idx > 0:
    let parentIndex = (idx - 1) div 2
    if heapDist[parentIndex] <= nodeDist:
      break
    heapNode[idx] = heapNode[parentIndex]
    heapDist[idx] = heapDist[parentIndex]
    idx = parentIndex
  heapNode[idx] = nodeIndex
  heapDist[idx] = nodeDist

proc heapPop(): int {.inline.} =
  result = heapNode[0]
  poppedDist = heapDist[0]
  heapSize -= 1
  if heapSize == 0:
    return
  let lastNode = heapNode[heapSize]
  let lastDist = heapDist[heapSize]
  var idx = 0
  while true:
    let leftChild = 2 * idx + 1
    if leftChild >= heapSize:
      break
    let rightChild = leftChild + 1
    var child = leftChild
    if rightChild < heapSize and heapDist[rightChild] < heapDist[leftChild]:
      child = rightChild
    if heapDist[child] >= lastDist:
      break
    heapNode[idx] = heapNode[child]
    heapDist[idx] = heapDist[child]
    idx = child
  heapNode[idx] = lastNode
  heapDist[idx] = lastDist

proc siftDown(values: var seq[int], rootIndex, endIndex: int) {.inline.} =
  var root = rootIndex
  while true:
    var child = 2 * root + 1
    if child > endIndex:
      break
    if child < endIndex and minDist[values[child]] > minDist[values[child + 1]]:
      child += 1
    if minDist[values[root]] <= minDist[values[child]]:
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
    minDist[nodeIndex] = unreachable
    isBagNode[nodeIndex] = false

  for streetIndex in 0..<streetCount:
    let fromNode = nextInt(inputData, scanAt)
    let toNode = nextInt(inputData, scanAt)
    streetFrom[streetIndex] = fromNode
    streetTarget[streetIndex] = toNode
    streetForward[streetIndex] = nextInt(inputData, scanAt)
    streetBackward[streetIndex] = nextInt(inputData, scanAt)
    arcCount[fromNode] += 1
    arcCount[toNode] += 1

  arcStart[1] = 0
  for nodeIndex in 1..nodeCount:
    arcStart[nodeIndex + 1] = arcStart[nodeIndex] + arcCount[nodeIndex]
    arcCursor[nodeIndex] = arcStart[nodeIndex]

  for streetIndex in 0..<streetCount:
    let fromNode = streetFrom[streetIndex]
    let toNode = streetTarget[streetIndex]
    let forwardArc = arcCursor[fromNode]
    arcCursor[fromNode] += 1
    arcTo[forwardArc] = toNode
    arcWeight[forwardArc] = streetForward[streetIndex]
    let backwardArc = arcCursor[toNode]
    arcCursor[toNode] += 1
    arcTo[backwardArc] = fromNode
    arcWeight[backwardArc] = streetBackward[streetIndex]
    arcReverse[forwardArc] = backwardArc
    arcReverse[backwardArc] = forwardArc

  for bagIndex in 0..<bagCount:
    let bagNode = nextInt(inputData, scanAt)
    isBagNode[bagNode] = true
    minDist[bagNode] = 0

  heapSize = 0
  for nodeIndex in 1..nodeCount:
    if isBagNode[nodeIndex]:
      heapPush(nodeIndex, 0)

  while heapSize > 0:
    let nodeIndex = heapPop()
    if poppedDist != minDist[nodeIndex]:
      continue
    let baseDist = minDist[nodeIndex]
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      let nextDist = baseDist + arcWeight[arcIndex]
      let target = arcTo[arcIndex]
      if nextDist < minDist[target]:
        minDist[target] = nextDist
        heapPush(target, nextDist)

  for arcIndex in 0..<arcTotal:
    isParentArc[arcIndex] = false
  for nodeIndex in 1..nodeCount:
    if isBagNode[nodeIndex]:
      continue
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      if minDist[arcTo[arcIndex]] + arcWeight[arcReverse[arcIndex]] == minDist[nodeIndex]:
        isParentArc[arcIndex] = true

  for nodeIndex in 1..nodeCount:
    ordered[nodeIndex - 1] = nodeIndex
  sortByDistance(ordered, nodeCount)

  for sliceIndex in 0..<nodeCount:
    let nodeIndex = ordered[sliceIndex]
    if minDist[nodeIndex] == unreachable:
      continue
    var bestNum: int64 = 0
    var bestDen: int64 = 1
    var haveBest = false
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      if not isParentArc[arcIndex]:
        let target = arcTo[arcIndex]
        let forwardWeight = arcWeight[arcIndex]
        let arrive = minDist[nodeIndex] + forwardWeight
        var valueNum: int64 = 0
        var valueDen: int64 = 1
        if arrive == minDist[target]:
          valueNum = survivalNum[target]
          valueDen = survivalDen[target]
        elif minDist[target] < arrive and minDist[nodeIndex] < minDist[target] + arcWeight[arcReverse[arcIndex]]:
          valueNum = int64(minDist[nodeIndex]) * arcWeight[arcReverse[arcIndex]] +
                     int64(minDist[target]) * forwardWeight +
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
      bestNum = int64(minDist[nodeIndex])
      bestDen = 1
    survivalNum[nodeIndex] = bestNum
    survivalDen[nodeIndex] = bestDen

  var hasHidden = false
  for nodeIndex in 1..nodeCount:
    if minDist[nodeIndex] == unreachable:
      hasHidden = true
      break

  if hasHidden:
    var firstWritten = true
    for nodeIndex in 1..nodeCount:
      if minDist[nodeIndex] == unreachable:
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
