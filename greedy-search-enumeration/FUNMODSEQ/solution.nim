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

proc modularInverse(value: int64, modulusValue: int64): int64 =
  var oldRemainder = value
  var newRemainder = modulusValue
  var oldCoefficient: int64 = 1
  var newCoefficient: int64 = 0
  while newRemainder != 0:
    let quotient = oldRemainder div newRemainder
    let nextRemainder = oldRemainder - quotient * newRemainder
    oldRemainder = newRemainder
    newRemainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * newCoefficient
    oldCoefficient = newCoefficient
    newCoefficient = nextCoefficient
  if oldRemainder != 1:
    return -1
  var inverseValue = oldCoefficient mod modulusValue
  if inverseValue < 0:
    inverseValue += modulusValue
  return inverseValue

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let firstValue = nextInt(inputData, scanPos)
  let modulusValue = nextInt(inputData, scanPos)
  let termCount = nextInt(inputData, scanPos)
  let inverseValue = modularInverse(int64(firstValue), int64(modulusValue))
  if inverseValue < 0:
    appendOutput("-1")
  else:
    let pairSum = int64(firstValue) + inverseValue
    let pairCount = int64(termCount) div 2
    var totalSum = pairCount * pairSum
    if termCount mod 2 == 1:
      totalSum += int64(firstValue)
    appendOutput($totalSum)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
