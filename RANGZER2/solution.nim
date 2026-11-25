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

proc countZerosUpTo(limit: int64): int64 =
  var zeroTotal: int64 = 0
  var placeValue: int64 = 1
  while placeValue <= limit:
    let higherPart = limit div (placeValue * 10)
    let currentDigit = (limit div placeValue) mod 10
    let lowerPart = limit mod placeValue
    if higherPart > 0:
      if currentDigit == 0:
        zeroTotal = zeroTotal + (higherPart - 1) * placeValue + lowerPart + 1
      else:
        zeroTotal = zeroTotal + higherPart * placeValue
    placeValue = placeValue * 10
  return zeroTotal

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rangeStart = int64(nextInt(inputData, scanPos))
  let rangeEnd = int64(nextInt(inputData, scanPos))
  let rangeZeros = countZerosUpTo(rangeEnd) - countZerosUpTo(rangeStart - 1)
  appendOutput($rangeZeros)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
