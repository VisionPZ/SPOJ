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

var nodeValue: seq[int64]
var nodeAlive: seq[bool]
var minHeap: seq[int]
var maxHeap: seq[int]

proc pushMin(heap: var seq[int], nodeId: int) =
  heap.add nodeId
  var idx = heap.len - 1
  while idx > 0:
    let parentIdx = (idx - 1) div 2
    if nodeValue[heap[parentIdx]] <= nodeValue[heap[idx]]:
      break
    let swapId = heap[parentIdx]
    heap[parentIdx] = heap[idx]
    heap[idx] = swapId
    idx = parentIdx

proc pushMax(heap: var seq[int], nodeId: int) =
  heap.add nodeId
  var idx = heap.len - 1
  while idx > 0:
    let parentIdx = (idx - 1) div 2
    if nodeValue[heap[parentIdx]] >= nodeValue[heap[idx]]:
      break
    let swapId = heap[parentIdx]
    heap[parentIdx] = heap[idx]
    heap[idx] = swapId
    idx = parentIdx

proc popMin(heap: var seq[int]): int =
  result = heap[0]
  let lastId = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len == 0:
    return
  heap[0] = lastId
  var idx = 0
  while true:
    let leftIndex = 2 * idx + 1
    let rightIndex = leftIndex + 1
    var smallest = idx
    if leftIndex < heap.len and nodeValue[heap[leftIndex]] < nodeValue[heap[smallest]]:
      smallest = leftIndex
    if rightIndex < heap.len and nodeValue[heap[rightIndex]] < nodeValue[heap[smallest]]:
      smallest = rightIndex
    if smallest == idx:
      break
    let swapId = heap[idx]
    heap[idx] = heap[smallest]
    heap[smallest] = swapId
    idx = smallest

proc popMax(heap: var seq[int]): int =
  result = heap[0]
  let lastId = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len == 0:
    return
  heap[0] = lastId
  var idx = 0
  while true:
    let leftIndex = 2 * idx + 1
    let rightIndex = leftIndex + 1
    var largest = idx
    if leftIndex < heap.len and nodeValue[heap[leftIndex]] > nodeValue[heap[largest]]:
      largest = leftIndex
    if rightIndex < heap.len and nodeValue[heap[rightIndex]] > nodeValue[heap[largest]]:
      largest = rightIndex
    if largest == idx:
      break
    let swapId = heap[idx]
    heap[idx] = heap[largest]
    heap[largest] = swapId
    idx = largest

proc addLeaf(value: int64) =
  let nodeId = nodeValue.len
  nodeValue.add value
  nodeAlive.add true
  pushMin(minHeap, nodeId)
  pushMax(maxHeap, nodeId)

proc removeLightest(): int64 =
  while not nodeAlive[minHeap[0]]:
    discard popMin(minHeap)
  let nodeId = popMin(minHeap)
  nodeAlive[nodeId] = false
  return nodeValue[nodeId]

proc removeHeaviest(): int64 =
  while not nodeAlive[maxHeap[0]]:
    discard popMax(maxHeap)
  let nodeId = popMax(maxHeap)
  nodeAlive[nodeId] = false
  return nodeValue[nodeId]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let wordTarget = nextInt(inputData, scanPos)
  let letterCount = nextInt(inputData, scanPos)
  var letterWeights: seq[int64]
  letterWeights.setLen(letterCount)
  for idx in 0..<letterCount:
    letterWeights[idx] = int64(nextInt(inputData, scanPos))
  for curIdx in 1..<letterCount:
    let key = letterWeights[curIdx]
    var prevIdx = curIdx - 1
    while prevIdx >= 0 and letterWeights[prevIdx] > key:
      letterWeights[prevIdx + 1] = letterWeights[prevIdx]
      prevIdx -= 1
    letterWeights[prevIdx + 1] = key

  nodeValue.setLen(0)
  nodeAlive.setLen(0)
  minHeap.setLen(0)
  maxHeap.setLen(0)
  var leafTotal: int64 = 0
  let initialCount = min(wordTarget, letterCount)
  for idx in 0..<initialCount:
    addLeaf(letterWeights[idx])
    leafTotal += letterWeights[idx]
  var leafCount = initialCount

  var bestTotal: int64 = high(int64)
  while leafTotal < bestTotal:
    if leafCount == wordTarget:
      bestTotal = leafTotal
    let lightest = removeLightest()
    leafTotal -= lightest
    leafCount -= 1
    for idx in 0..<letterCount:
      let childWeight = lightest + letterWeights[idx]
      addLeaf(childWeight)
      leafTotal += childWeight
      leafCount += 1
    while leafCount > wordTarget:
      leafTotal -= removeHeaviest()
      leafCount -= 1

  appendOutput($(bestTotal))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
