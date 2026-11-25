const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc hasMoreNumbers(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type ValueHeap = object
  items: seq[int64]

proc heapPush(heap: var ValueHeap, value: int64) =
  heap.items.add value
  var childIndex = heap.items.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heap.items[parentIndex] >= heap.items[childIndex]:
      break
    let childValue = heap.items[childIndex]
    heap.items[childIndex] = heap.items[parentIndex]
    heap.items[parentIndex] = childValue
    childIndex = parentIndex

proc heapPop(heap: var ValueHeap): int64 =
  result = heap.items[0]
  let lastIndex = heap.items.len - 1
  let lastValue = heap.items[lastIndex]
  heap.items.setLen lastIndex
  if lastIndex > 0:
    heap.items[0] = lastValue
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      if leftIndex >= heap.items.len:
        break
      let rightIndex = leftIndex + 1
      var largerIndex = leftIndex
      if rightIndex < heap.items.len and heap.items[rightIndex] > heap.items[leftIndex]:
        largerIndex = rightIndex
      if heap.items[parentIndex] >= heap.items[largerIndex]:
        break
      let parentValue = heap.items[parentIndex]
      heap.items[parentIndex] = heap.items[largerIndex]
      heap.items[largerIndex] = parentValue
      parentIndex = largerIndex

proc secondLargest(heap: ValueHeap): int64 =
  if heap.items.len < 2:
    return heap.items[0]
  if heap.items.len == 2:
    return heap.items[1]
  if heap.items[1] > heap.items[2]:
    return heap.items[1]
  return heap.items[2]

proc takeTurn(current: var ValueHeap, opponent: var ValueHeap): bool =
  let currentMax = current.items[0]
  let opponentMax = opponent.items[0]
  var currentPairSum = currentMax
  if current.items.len >= 2:
    currentPairSum = currentMax + secondLargest(current)
  var opponentPairSum = opponentMax
  if opponent.items.len >= 2:
    opponentPairSum = opponentMax + secondLargest(opponent)
  if current.items.len >= 2 and currentPairSum > opponentPairSum:
    let firstValue = heapPop(current)
    let secondValue = heapPop(current)
    heapPush(current, firstValue + secondValue)
    return false
  if currentMax > opponentMax:
    discard heapPop(opponent)
    return false
  if current.items.len >= 2:
    let firstValue = heapPop(current)
    let secondValue = heapPop(current)
    heapPush(current, firstValue + secondValue)
    return false
  return true

var caseNumber = 1
while hasMoreNumbers(inputData, scanPos):
  let takeoverCount = nextInt(inputData, scanPos)
  let buyoutCount = nextInt(inputData, scanPos)
  var takeoverHeap: ValueHeap
  var buyoutHeap: ValueHeap
  takeoverHeap.items = newSeq[int64](0)
  buyoutHeap.items = newSeq[int64](0)
  var takeoverIndex = 0
  while takeoverIndex < takeoverCount:
    heapPush(takeoverHeap, int64(nextInt(inputData, scanPos)))
    takeoverIndex += 1
  var buyoutIndex = 0
  while buyoutIndex < buyoutCount:
    heapPush(buyoutHeap, int64(nextInt(inputData, scanPos)))
    buyoutIndex += 1
  var takeoverTurn = true
  var consecutivePasses = 0
  while takeoverHeap.items.len > 0 and buyoutHeap.items.len > 0 and consecutivePasses < 2:
    var passed: bool
    if takeoverTurn:
      passed = takeTurn(takeoverHeap, buyoutHeap)
    else:
      passed = takeTurn(buyoutHeap, takeoverHeap)
    if passed:
      consecutivePasses += 1
    else:
      consecutivePasses = 0
    takeoverTurn = not takeoverTurn
  appendOutput("Case " & $caseNumber & ": ")
  if takeoverHeap.items.len == 0:
    appendOutput("Buyout Limited")
  else:
    appendOutput("Takeover Incorporated")
  outputBuffer.add '\n'
  caseNumber += 1
stdout.write outputBuffer
outputBuffer.setLen 0
