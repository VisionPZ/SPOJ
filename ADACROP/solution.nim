import algorithm

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

proc compareValues(firstValue: int64, secondValue: int64): int =
  if firstValue < secondValue:
    return -1
  elif firstValue > secondValue:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var eventValueId = newSeq[int](0)
var eventRawValue = newSeq[int64](0)
var eventPosition = newSeq[int](0)
var eventTime = newSeq[int](0)
var eventDelta = newSeq[int](0)
var eventKind = newSeq[int](0)
var eventQueryId = newSeq[int](0)

proc compareEvents(leftEvent: int, rightEvent: int): int =
  if eventValueId[leftEvent] != eventValueId[rightEvent]:
    return eventValueId[leftEvent] - eventValueId[rightEvent]
  if eventPosition[leftEvent] != eventPosition[rightEvent]:
    return eventPosition[leftEvent] - eventPosition[rightEvent]
  if eventKind[leftEvent] != eventKind[rightEvent]:
    return eventKind[leftEvent] - eventKind[rightEvent]
  return eventTime[leftEvent] - eventTime[rightEvent]

var bitStamp = newSeq[int](0)
var bitCount = newSeq[int](0)
var currentStamp = 0

proc bitAdd(index: int, delta: int) =
  var position = index
  while position < bitCount.len:
    if bitStamp[position] != currentStamp:
      bitStamp[position] = currentStamp
      bitCount[position] = 0
    bitCount[position] = bitCount[position] + delta
    position = position + (position and (-position))

proc bitPrefix(index: int): int =
  var position = index
  var total = 0
  while position > 0:
    if bitStamp[position] == currentStamp:
      total = total + bitCount[position]
    position = position - (position and (-position))
  return total

proc findValueId(value: int64, distinctValues: seq[int64]): int =
  var lowIndex = 0
  var highIndex = distinctValues.len - 1
  while lowIndex <= highIndex:
    let middleIndex = lowIndex + (highIndex - lowIndex) div 2
    if distinctValues[middleIndex] < value:
      lowIndex = middleIndex + 1
    elif distinctValues[middleIndex] > value:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return lowIndex

proc addEvent(value: int64, position: int, time: int, delta: int,
              kind: int, queryId: int) =
  eventRawValue.add value
  eventPosition.add position
  eventTime.add time
  eventDelta.add delta
  eventKind.add kind
  eventQueryId.add queryId
  eventValueId.add 0

let fieldLength = nextInt(inputData, scanPos)
let harvestCount = nextInt(inputData, scanPos)
var currentPlant = newSeq[int64](fieldLength)
var allValues = newSeq[int64](fieldLength)
for position in 0 .. fieldLength - 1:
  let plantKind = int64(nextInt(inputData, scanPos))
  currentPlant[position] = plantKind
  allValues[position] = plantKind
  addEvent(plantKind, position, -1, 1, 1, -1)

for harvestIndex in 0 .. harvestCount - 1:
  let harvestedIndex = nextInt(inputData, scanPos)
  let plantedKind = int64(nextInt(inputData, scanPos))
  let oldKind = currentPlant[harvestedIndex]
  currentPlant[harvestedIndex] = plantedKind
  allValues.add plantedKind
  addEvent(oldKind, harvestedIndex, harvestIndex, -1, 1, -1)
  addEvent(plantedKind, harvestedIndex, harvestIndex, 1, 1, -1)
  addEvent(plantedKind, harvestedIndex, harvestIndex, 0, 0, harvestIndex)

allValues.sort(compareValues)
var distinctValues = newSeq[int64](0)
for value in allValues:
  if distinctValues.len == 0 or distinctValues[distinctValues.len - 1] != value:
    distinctValues.add value

for eventIndex in 0 .. eventValueId.high:
  eventValueId[eventIndex] = findValueId(eventRawValue[eventIndex], distinctValues)

var answerList = newSeq[int](harvestCount)
bitStamp = newSeq[int](harvestCount + 3)
bitCount = newSeq[int](harvestCount + 3)

var eventOrder = newSeq[int](eventValueId.len)
for eventIndex in 0 .. eventOrder.high:
  eventOrder[eventIndex] = eventIndex
eventOrder.sort(compareEvents)

var orderIndex = 0
while orderIndex < eventOrder.len:
  let groupValue = eventValueId[eventOrder[orderIndex]]
  currentStamp += 1
  var groupIndex = orderIndex
  while groupIndex < eventOrder.len and eventValueId[eventOrder[groupIndex]] == groupValue:
    let eventIndex = eventOrder[groupIndex]
    if eventKind[eventIndex] == 1:
      bitAdd(eventTime[eventIndex] + 2, eventDelta[eventIndex])
    else:
      answerList[eventQueryId[eventIndex]] = bitPrefix(eventTime[eventIndex] + 2)
    groupIndex += 1
  orderIndex = groupIndex

for harvestIndex in 0 .. harvestCount - 1:
  appendOutput($answerList[harvestIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
