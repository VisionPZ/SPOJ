const flushBlockBytes = 1 shl 17
const modulusValue = int64(98765431)

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

proc powerMod(baseValue, exponentValue: int64): int64 =
  var resultValue = int64(1)
  var currentBase = baseValue mod modulusValue
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1) == 1:
      resultValue = resultValue * currentBase mod modulusValue
    currentBase = currentBase * currentBase mod modulusValue
    remainingExponent = remainingExponent shr 1
  return resultValue

proc modularInverse(value: int64): int64 =
  var oldRemainder = value mod modulusValue
  var newRemainder = modulusValue
  var oldCoeff = int64(1)
  var newCoeff = int64(0)
  while newRemainder != 0:
    let quotient = oldRemainder div newRemainder
    let nextRemainder = oldRemainder - quotient * newRemainder
    oldRemainder = newRemainder
    newRemainder = nextRemainder
    let nextCoeff = oldCoeff - quotient * newCoeff
    oldCoeff = newCoeff
    newCoeff = nextCoeff
  return (oldCoeff mod modulusValue + modulusValue) mod modulusValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let cowCount = nextInt(inputData, scanPos)
let repeatCount = int64(nextInt(inputData, scanPos))
var cowValues = newSeq[int64](cowCount)
var initialTotal = int64(0)
for cowIndex in 0 .. cowCount - 1:
  cowValues[cowIndex] = int64(nextInt(inputData, scanPos)) mod modulusValue
  initialTotal = (initialTotal + cowValues[cowIndex]) mod modulusValue
let neighborBase = int64(cowCount - 1) mod modulusValue
let neighborPower = powerMod(neighborBase, repeatCount)
var signValue = int64(1)
if (repeatCount and 1) == 1:
  signValue = modulusValue - 1
let coefficient = ((neighborPower - signValue + modulusValue) mod modulusValue) *
    modularInverse(int64(cowCount)) mod modulusValue
for cowIndex in 0 .. cowCount - 1:
  let answerValue = (coefficient * initialTotal + signValue * cowValues[cowIndex]) mod modulusValue
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
