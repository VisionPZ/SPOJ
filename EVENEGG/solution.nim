const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const baseDoorHeight = 7

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

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

var scanPos = 0

while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let initialHeight = nextInt(inputData, scanPos)
  let targetDay = nextInt(inputData, scanPos)
  let dailyGrowth = nextInt(inputData, scanPos)
  let columnHeight = nextInt(inputData, scanPos)
  let dragonHeight = initialHeight + targetDay * dailyGrowth
  var columnCount = (dragonHeight - baseDoorHeight) div columnHeight
  if columnCount < 0:
    columnCount = 0
  if baseDoorHeight + columnCount * columnHeight <= dragonHeight:
    columnCount += 1
  let doorHeight = baseDoorHeight + columnCount * columnHeight
  appendOutput($(doorHeight))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
