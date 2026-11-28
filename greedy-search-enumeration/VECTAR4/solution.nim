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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc integerSquareRoot(value: int64): int64 =
  var lowValue: int64 = 0
  var highValue: int64 = 1000000000
  while lowValue <= highValue:
    let middleValue = (lowValue + highValue) div 2
    if middleValue * middleValue <= value:
      lowValue = middleValue + 1
    else:
      highValue = middleValue - 1
  return highValue

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let enemyCount = int64(nextInt(inputData, scanPos))
  let rootValue = integerSquareRoot(enemyCount)
  let remainderValue = enemyCount - rootValue * rootValue
  var dayCount: int64 = 0
  if remainderValue == 0:
    dayCount = 2 * rootValue - 1
  elif remainderValue <= rootValue:
    dayCount = 2 * rootValue
  else:
    dayCount = 2 * rootValue + 1
  appendOutput($dayCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
