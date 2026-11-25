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

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false

proc deadlineFor(ratioSum: int64, nextQuantity: int, ratio: int): int64 =
  let product = ratioSum * int64(nextQuantity)
  return (product + int64(ratio) - 1) div int64(ratio)

var heapDeadlines = newSeq[int64](0)
var heapTypes = newSeq[int](0)

proc heapLess(leftIndex: int, rightIndex: int): bool =
  if heapDeadlines[leftIndex] < heapDeadlines[rightIndex]:
    return true
  if heapDeadlines[leftIndex] > heapDeadlines[rightIndex]:
    return false
  return heapTypes[leftIndex] < heapTypes[rightIndex]

proc swapHeap(leftIndex: int, rightIndex: int) =
  let savedDeadline = heapDeadlines[leftIndex]
  let savedType = heapTypes[leftIndex]
  heapDeadlines[leftIndex] = heapDeadlines[rightIndex]
  heapTypes[leftIndex] = heapTypes[rightIndex]
  heapDeadlines[rightIndex] = savedDeadline
  heapTypes[rightIndex] = savedType

proc siftUpHeap(startIndex: int) =
  var childIndex = startIndex
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapLess(childIndex, parentIndex):
      swapHeap(childIndex, parentIndex)
      childIndex = parentIndex
    else:
      break

proc siftDownHeap(startIndex: int) =
  var parentIndex = startIndex
  while true:
    let leftIndex = parentIndex * 2 + 1
    if leftIndex >= heapDeadlines.len:
      break
    let rightIndex = leftIndex + 1
    var smallestIndex = leftIndex
    if rightIndex < heapDeadlines.len and heapLess(rightIndex, leftIndex):
      smallestIndex = rightIndex
    if heapLess(smallestIndex, parentIndex):
      swapHeap(parentIndex, smallestIndex)
      parentIndex = smallestIndex
    else:
      break

proc pushDeadline(deadline: int64, sweetType: int) =
  heapDeadlines.add deadline
  heapTypes.add sweetType
  siftUpHeap(heapDeadlines.len - 1)

proc popDeadline(deadline: var int64, sweetType: var int) =
  deadline = heapDeadlines[0]
  sweetType = heapTypes[0]
  let lastIndex = heapDeadlines.len - 1
  heapDeadlines[0] = heapDeadlines[lastIndex]
  heapTypes[0] = heapTypes[lastIndex]
  heapDeadlines.setLen(lastIndex)
  heapTypes.setLen(lastIndex)
  if heapDeadlines.len > 0:
    siftDownHeap(0)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextToken(inputData, scanPos):
  let typeCount = nextInt(inputData, scanPos)
  let eatenCount = nextInt(inputData, scanPos)
  var ratios = newSeq[int](typeCount)
  var ratioSum: int64 = 0
  for typeIndex in 0 .. typeCount - 1:
    ratios[typeIndex] = nextInt(inputData, scanPos)
    ratioSum += int64(ratios[typeIndex])
  var eatenCounts = newSeq[int](typeCount)
  for sweetIndex in 0 .. eatenCount - 1:
    let sweetType = nextInt(inputData, scanPos) - 1
    eatenCounts[sweetType] += 1
  heapDeadlines.setLen(0)
  heapTypes.setLen(0)
  for typeIndex in 0 .. typeCount - 1:
    pushDeadline(deadlineFor(ratioSum, eatenCounts[typeIndex] + 1, ratios[typeIndex]), typeIndex)
  var currentSize = eatenCount
  var simulatedSteps: int64 = 0
  while simulatedSteps < ratioSum:
    var deadline: int64 = 0
    var sweetType = 0
    popDeadline(deadline, sweetType)
    if deadline < int64(currentSize + 1):
      currentSize = int(deadline) - 1
      break
    eatenCounts[sweetType] += 1
    pushDeadline(deadlineFor(ratioSum, eatenCounts[sweetType] + 1, ratios[sweetType]), sweetType)
    currentSize += 1
    simulatedSteps += 1
  let gained = currentSize - eatenCount
  if int64(gained) >= ratioSum:
    appendOutput("forever")
  else:
    appendOutput($gained)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
