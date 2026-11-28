const flushBlockBytes = 1 shl 17

type
  SegmentEvent = object
    coord: float
    kind: int
    yIndex: int
    lowerIndex: int
    upperIndex: int

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

proc nextFloat(data: string, pos: var int): float =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.' and data[pos] != '-':
    pos += 1
  var sign = 1.0
  if pos < data.len and data[pos] == '-':
    sign = -1.0
    pos += 1
  var whole = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    whole = whole * 10.0 + float(int(data[pos]) - 48)
    pos += 1
  var fraction = 0.0
  var scale = 1.0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fraction = fraction * 10.0 + float(int(data[pos]) - 48)
      scale = scale * 10.0
      pos += 1
  return sign * (whole + fraction / scale)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc sortFloats(values: var seq[float], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  var leftCursor = lowIndex
  var rightCursor = highIndex
  let pivot = values[lowIndex + (highIndex - lowIndex) div 2]
  while leftCursor <= rightCursor:
    while values[leftCursor] < pivot:
      leftCursor += 1
    while values[rightCursor] > pivot:
      rightCursor -= 1
    if leftCursor <= rightCursor:
      swap values[leftCursor], values[rightCursor]
      leftCursor += 1
      rightCursor -= 1
  sortFloats(values, lowIndex, rightCursor)
  sortFloats(values, leftCursor, highIndex)

proc eventLess(left: SegmentEvent, right: SegmentEvent): bool =
  if left.coord < right.coord:
    return true
  if left.coord > right.coord:
    return false
  return left.kind < right.kind

proc sortEvents(items: var seq[SegmentEvent], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  let pivotIndex = lowIndex + (highIndex - lowIndex) div 2
  swap items[lowIndex], items[pivotIndex]
  let pivot = items[lowIndex]
  var lessEnd = lowIndex
  var cursor = lowIndex + 1
  var greaterStart = highIndex
  while cursor <= greaterStart:
    if eventLess(items[cursor], pivot):
      swap items[lessEnd], items[cursor]
      lessEnd += 1
      cursor += 1
    elif eventLess(pivot, items[cursor]):
      swap items[cursor], items[greaterStart]
      greaterStart -= 1
    else:
      cursor += 1
  sortEvents(items, lowIndex, lessEnd - 1)
  sortEvents(items, greaterStart + 1, highIndex)

proc lowerBound(values: seq[float], target: float): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middle = (lowIndex + highIndex) div 2
    if values[middle] < target:
      lowIndex = middle + 1
    else:
      highIndex = middle
  return lowIndex

proc upperBound(values: seq[float], target: float): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middle = (lowIndex + highIndex) div 2
    if target < values[middle]:
      highIndex = middle
    else:
      lowIndex = middle + 1
  return lowIndex

let segmentCount = nextInt(inputData, scanPos)
var horizontalLowXs = newSeq[float](segmentCount)
var horizontalHighXs = newSeq[float](segmentCount)
var horizontalYs = newSeq[float](segmentCount)
var verticalXs = newSeq[float](segmentCount)
var verticalLowYs = newSeq[float](segmentCount)
var verticalHighYs = newSeq[float](segmentCount)

for segmentIndex in 0 .. segmentCount - 1:
  let firstX = nextFloat(inputData, scanPos)
  let secondX = nextFloat(inputData, scanPos)
  let level = nextFloat(inputData, scanPos)
  if firstX < secondX:
    horizontalLowXs[segmentIndex] = firstX
    horizontalHighXs[segmentIndex] = secondX
  else:
    horizontalLowXs[segmentIndex] = secondX
    horizontalHighXs[segmentIndex] = firstX
  horizontalYs[segmentIndex] = level

for segmentIndex in 0 .. segmentCount - 1:
  let firstY = nextFloat(inputData, scanPos)
  let secondY = nextFloat(inputData, scanPos)
  let positionX = nextFloat(inputData, scanPos)
  if firstY < secondY:
    verticalLowYs[segmentIndex] = firstY
    verticalHighYs[segmentIndex] = secondY
  else:
    verticalLowYs[segmentIndex] = secondY
    verticalHighYs[segmentIndex] = firstY
  verticalXs[segmentIndex] = positionX

var sortedYs = newSeq[float](segmentCount)
for segmentIndex in 0 .. segmentCount - 1:
  sortedYs[segmentIndex] = horizontalYs[segmentIndex]
if segmentCount > 0:
  sortFloats(sortedYs, 0, segmentCount - 1)

var levelValues = newSeq[float]()
for segmentIndex in 0 .. segmentCount - 1:
  if segmentIndex == 0 or sortedYs[segmentIndex] != sortedYs[segmentIndex - 1]:
    levelValues.add sortedYs[segmentIndex]

var events = newSeq[SegmentEvent]()
for segmentIndex in 0 .. segmentCount - 1:
  var newEvent: SegmentEvent
  newEvent.yIndex = lowerBound(levelValues, horizontalYs[segmentIndex]) + 1
  newEvent.lowerIndex = 0
  newEvent.upperIndex = 0
  newEvent.coord = horizontalLowXs[segmentIndex]
  newEvent.kind = 0
  events.add newEvent
  newEvent.coord = horizontalHighXs[segmentIndex]
  newEvent.kind = 2
  events.add newEvent

for segmentIndex in 0 .. segmentCount - 1:
  let firstIndex = lowerBound(levelValues, verticalLowYs[segmentIndex]) + 1
  let lastIndex = upperBound(levelValues, verticalHighYs[segmentIndex])
  if firstIndex <= lastIndex:
    var newEvent: SegmentEvent
    newEvent.coord = verticalXs[segmentIndex]
    newEvent.kind = 1
    newEvent.yIndex = 0
    newEvent.lowerIndex = firstIndex
    newEvent.upperIndex = lastIndex
    events.add newEvent

if events.len > 0:
  sortEvents(events, 0, events.len - 1)

var fenwick = newSeq[int](levelValues.len + 1)

proc addFenwick(index: int, delta: int) =
  var position = index
  while position <= levelValues.len:
    fenwick[position] = fenwick[position] + delta
    position = position + (position and (-position))

proc prefixTotal(index: int): int =
  var total = 0
  var position = index
  while position > 0:
    total = total + fenwick[position]
    position = position - (position and (-position))
  return total

var intersectionCount: int64 = 0
for event in events:
  if event.kind == 0:
    addFenwick(event.yIndex, 1)
  elif event.kind == 1:
    intersectionCount = intersectionCount + int64(prefixTotal(event.upperIndex) - prefixTotal(event.lowerIndex - 1))
  else:
    addFenwick(event.yIndex, -1)

appendOutput($intersectionCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
