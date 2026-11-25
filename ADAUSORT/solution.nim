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

proc hasMoreNumbers(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and (data[scanIndex] < '0' or data[scanIndex] > '9'):
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type IndexedValue = object
  value: int
  originalIndex: int

proc compareIndexed(leftItem: IndexedValue, rightItem: IndexedValue): int =
  if leftItem.value != rightItem.value:
    leftItem.value - rightItem.value
  else:
    rightItem.originalIndex - leftItem.originalIndex

while hasMoreNumbers(inputData, scanPos):
  let elementCount = nextInt(inputData, scanPos)
  var indexedValues = newSeq[IndexedValue](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    indexedValues[elementIndex].value = nextInt(inputData, scanPos)
    indexedValues[elementIndex].originalIndex = elementIndex + 1
  indexedValues.sort(compareIndexed)
  for itemIndex in 0 .. elementCount - 1:
    if itemIndex > 0:
      outputBuffer.add ' '
    appendOutput($(indexedValues[itemIndex].originalIndex))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
