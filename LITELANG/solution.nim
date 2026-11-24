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

proc pushMin(heap: var seq[int], id: int) =
  heap.add id
  var i = heap.len - 1
  while i > 0:
    let p = (i - 1) div 2
    if nodeValue[heap[p]] <= nodeValue[heap[i]]:
      break
    let swapId = heap[p]
    heap[p] = heap[i]
    heap[i] = swapId
    i = p

proc pushMax(heap: var seq[int], id: int) =
  heap.add id
  var i = heap.len - 1
  while i > 0:
    let p = (i - 1) div 2
    if nodeValue[heap[p]] >= nodeValue[heap[i]]:
      break
    let swapId = heap[p]
    heap[p] = heap[i]
    heap[i] = swapId
    i = p

proc popMin(heap: var seq[int]): int =
  result = heap[0]
  let lastId = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len == 0:
    return
  heap[0] = lastId
  var i = 0
  while true:
    let leftIndex = 2 * i + 1
    let rightIndex = leftIndex + 1
    var smallest = i
    if leftIndex < heap.len and nodeValue[heap[leftIndex]] < nodeValue[heap[smallest]]:
      smallest = leftIndex
    if rightIndex < heap.len and nodeValue[heap[rightIndex]] < nodeValue[heap[smallest]]:
      smallest = rightIndex
    if smallest == i:
      break
    let swapId = heap[i]
    heap[i] = heap[smallest]
    heap[smallest] = swapId
    i = smallest

proc popMax(heap: var seq[int]): int =
  result = heap[0]
  let lastId = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len == 0:
    return
  heap[0] = lastId
  var i = 0
  while true:
    let leftIndex = 2 * i + 1
    let rightIndex = leftIndex + 1
    var largest = i
    if leftIndex < heap.len and nodeValue[heap[leftIndex]] > nodeValue[heap[largest]]:
      largest = leftIndex
    if rightIndex < heap.len and nodeValue[heap[rightIndex]] > nodeValue[heap[largest]]:
      largest = rightIndex
    if largest == i:
      break
    let swapId = heap[i]
    heap[i] = heap[largest]
    heap[largest] = swapId
    i = largest

proc addLeaf(value: int64) =
  let id = nodeValue.len
  nodeValue.add value
  nodeAlive.add true
  pushMin(minHeap, id)
  pushMax(maxHeap, id)

proc removeLightest(): int64 =
  while not nodeAlive[minHeap[0]]:
    discard popMin(minHeap)
  let id = popMin(minHeap)
  nodeAlive[id] = false
  return nodeValue[id]

proc removeHeaviest(): int64 =
  while not nodeAlive[maxHeap[0]]:
    discard popMax(maxHeap)
  let id = popMax(maxHeap)
  nodeAlive[id] = false
  return nodeValue[id]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let wordTarget = nextInt(inputData, scanPos)
  let letterCount = nextInt(inputData, scanPos)
  var letterWeights: seq[int64]
  letterWeights.setLen(letterCount)
  var weightTotal: int64 = 0
  for i in 0..<letterCount:
    letterWeights[i] = int64(nextInt(inputData, scanPos))
    weightTotal += letterWeights[i]
  for i in 1..<letterCount:
    let key = letterWeights[i]
    var j = i - 1
    while j >= 0 and letterWeights[j] > key:
      letterWeights[j + 1] = letterWeights[j]
      j -= 1
    letterWeights[j + 1] = key

  nodeValue.setLen(0)
  nodeAlive.setLen(0)
  minHeap.setLen(0)
  maxHeap.setLen(0)
  var leafTotal: int64 = 0
  let initialCount = min(wordTarget, letterCount)
  for i in 0..<initialCount:
    addLeaf(letterWeights[i])
    leafTotal += letterWeights[i]
  var leafCount = initialCount

  var bestTotal: int64 = high(int64)
  while leafTotal < bestTotal:
    if leafCount == wordTarget:
      bestTotal = leafTotal
    let lightest = removeLightest()
    leafTotal -= lightest
    leafCount -= 1
    for i in 0..<letterCount:
      let childWeight = lightest + letterWeights[i]
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
