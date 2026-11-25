import algorithm

const flushBlockBytes = 1 shl 17
const loopPrefix = "for (int i = "
const loopMiddle = "; i <= "
const loopSuffix = "; i++) cout << i << \" \";\n"

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

proc compareNumbers(firstValue: int, secondValue: int): int =
  if firstValue < secondValue:
    return -1
  if firstValue > secondValue:
    return 1
  return 0

var numberList: seq[int] = @[]
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  numberList.add nextInt(inputData, scanPos)

numberList.sort(compareNumbers)

var runStart = 0
while runStart < numberList.len:
  var runEnd = runStart
  while runEnd + 1 < numberList.len and numberList[runEnd + 1] == numberList[runEnd] + 1:
    runEnd += 1
  appendOutput(loopPrefix & $numberList[runStart] & loopMiddle & $numberList[runEnd] & loopSuffix)
  runStart = runEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0
