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

proc fibPair(indexValue: int64, modulusValue: int64): (int64, int64) =
  if indexValue == 0:
    return (int64(0), int64(1))
  let halfPair = fibPair(indexValue div 2, modulusValue)
  let firstPart = halfPair[0]
  let secondPart = halfPair[1]
  var innerValue = (2 * secondPart - firstPart) mod modulusValue
  if innerValue < 0:
    innerValue = innerValue + modulusValue
  let middle = (firstPart * innerValue) mod modulusValue
  let last = (firstPart * firstPart + secondPart * secondPart) mod modulusValue
  if (indexValue and 1) == 0:
    return (middle, last)
  return (last, (middle + last) mod modulusValue)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let calculationCount = nextInt(inputData, scanPos)
for calculationIndex in 0 .. calculationCount - 1:
  let monthCount = int64(nextInt(inputData, scanPos))
  let boxExponent = nextInt(inputData, scanPos)
  let boxCapacity = int64(1) shl boxExponent
  let rabbitPair = fibPair(monthCount + 1, boxCapacity)
  let unboxedCouples = rabbitPair[0]
  appendOutput($unboxedCouples)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
