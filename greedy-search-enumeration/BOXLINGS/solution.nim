import algorithm

const flushBlockBytes = 1 shl 17
const addEvent = 0
const queryEvent = 1
const removeEvent = 2

type SweepEvent = object
  coord: int
  kind: int
  lowY: int
  highY: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareInts(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc compareEvents(left: SweepEvent, right: SweepEvent): int =
  if left.coord < right.coord:
    return -1
  if left.coord > right.coord:
    return 1
  if left.kind < right.kind:
    return -1
  if left.kind > right.kind:
    return 1
  return 0

proc findYIndex(values: openArray[int], target: int): int =
  var low = 0
  var high = values.len - 1
  while low <= high:
    let middle = (low + high) div 2
    if values[middle] == target:
      return middle
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle - 1
  return -1

let rectangleCount = nextInt(inputData, scanPos)
let pointCount = nextInt(inputData, scanPos)
var boxesXLow = newSeq[int](rectangleCount)
var boxesXHigh = newSeq[int](rectangleCount)
var boxesYLow = newSeq[int](rectangleCount)
var boxesYHigh = newSeq[int](rectangleCount)
var pointsX = newSeq[int](pointCount)
var pointsY = newSeq[int](pointCount)
var allY = newSeq[int]()

for rectangleIndex in 0 .. rectangleCount - 1:
  let firstX = nextInt(inputData, scanPos)
  let firstY = nextInt(inputData, scanPos)
  let secondX = nextInt(inputData, scanPos)
  let secondY = nextInt(inputData, scanPos)
  if firstX <= secondX:
    boxesXLow[rectangleIndex] = firstX
    boxesXHigh[rectangleIndex] = secondX
  else:
    boxesXLow[rectangleIndex] = secondX
    boxesXHigh[rectangleIndex] = firstX
  if firstY <= secondY:
    boxesYLow[rectangleIndex] = firstY
    boxesYHigh[rectangleIndex] = secondY
  else:
    boxesYLow[rectangleIndex] = secondY
    boxesYHigh[rectangleIndex] = firstY
  allY.add boxesYLow[rectangleIndex]
  allY.add boxesYHigh[rectangleIndex]

for pointIndex in 0 .. pointCount - 1:
  pointsX[pointIndex] = nextInt(inputData, scanPos)
  pointsY[pointIndex] = nextInt(inputData, scanPos)
  allY.add pointsY[pointIndex]

allY.sort(compareInts)
var yValues = newSeq[int]()
for value in allY:
  if yValues.len == 0 or yValues[yValues.len - 1] != value:
    yValues.add value

var coverage = newSeq[int](yValues.len * 4 + 5)
var lazyCount = newSeq[int](yValues.len * 4 + 5)

proc pushDown(node: int, low: int, high: int) =
  if lazyCount[node] == 0 or low == high:
    return
  let leftNode = node * 2
  let rightNode = node * 2 + 1
  coverage[leftNode] = coverage[leftNode] + lazyCount[node]
  lazyCount[leftNode] = lazyCount[leftNode] + lazyCount[node]
  coverage[rightNode] = coverage[rightNode] + lazyCount[node]
  lazyCount[rightNode] = lazyCount[rightNode] + lazyCount[node]
  lazyCount[node] = 0

proc changeRange(node: int, low: int, high: int, fromY: int, toY: int,
                 delta: int) =
  if fromY <= low and high <= toY:
    coverage[node] = coverage[node] + delta
    lazyCount[node] = lazyCount[node] + delta
    return
  pushDown(node, low, high)
  let middle = (low + high) div 2
  if fromY <= middle:
    changeRange(node * 2, low, middle, fromY, toY, delta)
  if toY > middle:
    changeRange(node * 2 + 1, middle + 1, high, fromY, toY, delta)
  coverage[node] = lazyCount[node] + max(coverage[node * 2],
                                         coverage[node * 2 + 1])

proc coveredAt(node: int, low: int, high: int, target: int): int =
  result = lazyCount[node]
  if low == high:
    return
  let middle = (low + high) div 2
  if target <= middle:
    result += coveredAt(node * 2, low, middle, target)
  else:
    result += coveredAt(node * 2 + 1, middle + 1, high, target)

var events = newSeq[SweepEvent]()
for rectangleIndex in 0 .. rectangleCount - 1:
  let lowIndex = findYIndex(yValues, boxesYLow[rectangleIndex])
  let highIndex = findYIndex(yValues, boxesYHigh[rectangleIndex])
  events.add SweepEvent(coord: boxesXLow[rectangleIndex], kind: addEvent,
                        lowY: lowIndex, highY: highIndex)
  events.add SweepEvent(coord: boxesXHigh[rectangleIndex], kind: removeEvent,
                        lowY: lowIndex, highY: highIndex)
for pointIndex in 0 .. pointCount - 1:
  events.add SweepEvent(coord: pointsX[pointIndex], kind: queryEvent,
                        lowY: findYIndex(yValues, pointsY[pointIndex]),
                        highY: 0)
events.sort(compareEvents)

var coveredPoints: int64 = 0
for event in events:
  if event.kind == addEvent:
    changeRange(1, 0, yValues.len - 1, event.lowY, event.highY, 1)
  elif event.kind == removeEvent:
    changeRange(1, 0, yValues.len - 1, event.lowY, event.highY, -1)
  else:
    if coveredAt(1, 0, yValues.len - 1, event.lowY) > 0:
      coveredPoints += 1

appendOutput($coveredPoints)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
