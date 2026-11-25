import math

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

proc fixedSix(value: float): string =
  var scaled: int64 = int64(value * 1000000.0 + 0.5)
  var whole = scaled div 1000000
  var fraction = scaled mod 1000000
  result = $whole
  result.add '.'
  var divisor: int64 = 100000
  while divisor > 0:
    result.add char(48 + int(fraction div divisor))
    fraction = fraction mod divisor
    divisor = divisor div 10

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let radiusOne = float(nextInt(inputData, scanPos))
  let radiusTwo = float(nextInt(inputData, scanPos))
  let radiusThree = float(nextInt(inputData, scanPos))
  let curvatureSum = 1.0 / radiusOne + 1.0 / radiusTwo + 1.0 / radiusThree
  let crossSum = 1.0 / (radiusOne * radiusTwo) + 1.0 / (radiusTwo * radiusThree) + 1.0 / (radiusThree * radiusOne)
  let innerRadius = 1.0 / (curvatureSum + 2.0 * sqrt(crossSum))
  appendOutput(fixedSix(innerRadius))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
