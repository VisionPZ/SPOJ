const flushBlockBytes = 1 shl 17
const maxSequenceLength = 3000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int, value: var int64): bool =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return false
  var negative = false
  if data[pos] == '-':
    negative = true
    pos += 1
  var magnitude: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    magnitude = magnitude * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    value = -magnitude
  else:
    value = magnitude
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var seenDifferences = newSeq[bool](maxSequenceLength)
var sequenceValues = newSeq[int64](maxSequenceLength)

while true:
  var caseLengthValue: int64 = 0
  if not nextInt(inputData, scanPos, caseLengthValue):
    break
  if caseLengthValue == 0:
    break
  let caseLength = int(caseLengthValue)
  var allValuesRead = true
  for valueIndex in 0 .. caseLength - 1:
    if not nextInt(inputData, scanPos, sequenceValues[valueIndex]):
      allValuesRead = false
      break
  var isJolly = allValuesRead
  var distinctCount = 0
  for valueIndex in 0 .. caseLength - 2:
    var difference = sequenceValues[valueIndex + 1] - sequenceValues[valueIndex]
    if difference < 0:
      difference = -difference
    if difference < 1 or difference > int64(caseLength - 1) or seenDifferences[int(difference)]:
      isJolly = false
    else:
      seenDifferences[int(difference)] = true
      distinctCount += 1
  if distinctCount != caseLength - 1:
    isJolly = false
  if isJolly:
    appendOutput("Jolly\n")
  else:
    appendOutput("Not jolly\n")
  for differenceIndex in 1 .. caseLength - 1:
    seenDifferences[differenceIndex] = false

stdout.write outputBuffer
outputBuffer.setLen 0
