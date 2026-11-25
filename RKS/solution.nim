const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let messageLength = nextInt(inputData, scanPos)
let upperBound = nextInt(inputData, scanPos)
var distinctValues = newSeq[int](0)
var frequencies = newSeq[int](0)
var firstPositions = newSeq[int](0)
for valueIndex in 0 .. messageLength - 1:
  let currentValue = nextInt(inputData, scanPos)
  var matchIndex = -1
  for distinctIndex in 0 .. distinctValues.len - 1:
    if distinctValues[distinctIndex] == currentValue:
      matchIndex = distinctIndex
      break
  if matchIndex < 0:
    distinctValues.add currentValue
    frequencies.add 1
    firstPositions.add valueIndex
  else:
    frequencies[matchIndex] += 1

var sortOrder = newSeq[int](distinctValues.len)
for orderIndex in 0 .. sortOrder.len - 1:
  sortOrder[orderIndex] = orderIndex
for rightIndex in 1 .. sortOrder.len - 1:
  let movingIndex = sortOrder[rightIndex]
  var leftIndex = rightIndex - 1
  while leftIndex >= 0 and (frequencies[sortOrder[leftIndex]] < frequencies[movingIndex] or (frequencies[sortOrder[leftIndex]] == frequencies[movingIndex] and firstPositions[sortOrder[leftIndex]] > firstPositions[movingIndex])):
    sortOrder[leftIndex + 1] = sortOrder[leftIndex]
    leftIndex -= 1
  sortOrder[leftIndex + 1] = movingIndex

var writtenAny = false
for orderIndex in 0 .. sortOrder.len - 1:
  let valueIndex = sortOrder[orderIndex]
  for repeatIndex in 0 .. frequencies[valueIndex] - 1:
    if writtenAny:
      appendOutput " "
    appendOutput($distinctValues[valueIndex])
    writtenAny = true
appendOutput "\n"
stdout.write outputBuffer
outputBuffer.setLen 0
