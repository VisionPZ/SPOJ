const flushBlockBytes = 1 shl 17

type PointRecord = tuple[x: int, y: int, value: int, yIndex: int]
type QueryEvent = tuple[x: int, yBound: int, sign: int, queryIndex: int]

proc pointComesBefore(left, right: PointRecord): bool = left.x <= right.x
proc eventComesBefore(left, right: QueryEvent): bool = left.x <= right.x
proc valueComesBefore(left, right: int): bool = left <= right

proc mergeSort[T](data: var seq[T], temp: var seq[T], low: int, high: int, comesBefore: proc(left, right: T): bool) =
  if low >= high:
    return
  let mid = (low + high) div 2
  mergeSort(data, temp, low, mid, comesBefore)
  mergeSort(data, temp, mid + 1, high, comesBefore)
  var leftPos = low
  var rightPos = mid + 1
  var writePos = low
  while leftPos <= mid and rightPos <= high:
    if comesBefore(data[leftPos], data[rightPos]):
      temp[writePos] = data[leftPos]
      leftPos += 1
    else:
      temp[writePos] = data[rightPos]
      rightPos += 1
    writePos += 1
  while leftPos <= mid:
    temp[writePos] = data[leftPos]
    leftPos += 1
    writePos += 1
  while rightPos <= high:
    temp[writePos] = data[rightPos]
    rightPos += 1
    writePos += 1
  for indexValue in low .. high:
    data[indexValue] = temp[indexValue]

proc upperBound(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let mid = (low + high) div 2
    if values[mid] <= target:
      low = mid + 1
    else:
      high = mid
  return low

proc fenwickAdd(tree: var seq[int64], index: int, delta: int) =
  var position = index + 1
  while position < tree.len:
    tree[position] += int64(delta)
    position += position and (-position)

proc fenwickSum(tree: seq[int64], index: int): int64 =
  var position = index
  var total: int64 = 0
  while position > 0:
    total += tree[position]
    position -= position and (-position)
  return total

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let treeCount = nextInt(inputData, scanPos)
  var points = newSeq[PointRecord](treeCount)
  var yCoordinates = newSeq[int](treeCount)
  for pointIndex in 0 .. treeCount - 1:
    let treeX = nextInt(inputData, scanPos)
    let treeY = nextInt(inputData, scanPos)
    let treeValue = nextInt(inputData, scanPos)
    points[pointIndex] = (x: treeX, y: treeY, value: treeValue, yIndex: 0)
    yCoordinates[pointIndex] = treeY
  if treeCount > 0:
    var scratchY = newSeq[int](treeCount)
    mergeSort(yCoordinates, scratchY, 0, treeCount - 1, valueComesBefore)
  var uniqueY = newSeq[int]()
  for coordinateIndex in 0 .. treeCount - 1:
    if coordinateIndex == 0 or yCoordinates[coordinateIndex] != yCoordinates[coordinateIndex - 1]:
      uniqueY.add yCoordinates[coordinateIndex]
  for pointIndex in 0 .. treeCount - 1:
    points[pointIndex].yIndex = upperBound(uniqueY, points[pointIndex].y) - 1
  let queryCount = nextInt(inputData, scanPos)
  let eventCount = queryCount * 4
  var answers = newSeq[int64](queryCount)
  var events = newSeq[QueryEvent](eventCount)
  var eventIndex = 0
  for queryIndex in 0 .. queryCount - 1:
    let lowerX = nextInt(inputData, scanPos)
    let lowerY = nextInt(inputData, scanPos)
    let upperX = nextInt(inputData, scanPos)
    let upperY = nextInt(inputData, scanPos)
    events[eventIndex] = (x: upperX, yBound: upperY, sign: 1, queryIndex: queryIndex)
    eventIndex += 1
    events[eventIndex] = (x: lowerX - 1, yBound: upperY, sign: -1, queryIndex: queryIndex)
    eventIndex += 1
    events[eventIndex] = (x: upperX, yBound: lowerY - 1, sign: -1, queryIndex: queryIndex)
    eventIndex += 1
    events[eventIndex] = (x: lowerX - 1, yBound: lowerY - 1, sign: 1, queryIndex: queryIndex)
    eventIndex += 1
  if treeCount > 0:
    var scratchPoints = newSeq[PointRecord](treeCount)
    mergeSort(points, scratchPoints, 0, treeCount - 1, pointComesBefore)
  if eventCount > 0:
    var scratchEvents = newSeq[QueryEvent](eventCount)
    mergeSort(events, scratchEvents, 0, eventCount - 1, eventComesBefore)
  var fenwickTree = newSeq[int64](uniqueY.len + 2)
  var pointPosition = 0
  for eventPosition in 0 .. eventCount - 1:
    let currentEvent = events[eventPosition]
    while pointPosition < treeCount and points[pointPosition].x <= currentEvent.x:
      fenwickAdd(fenwickTree, points[pointPosition].yIndex, points[pointPosition].value)
      pointPosition += 1
    let boundIndex = upperBound(uniqueY, currentEvent.yBound)
    let prefixTotal = fenwickSum(fenwickTree, boundIndex)
    answers[currentEvent.queryIndex] += int64(currentEvent.sign) * prefixTotal
  for answerIndex in 0 .. queryCount - 1:
    appendOutput($answers[answerIndex])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
