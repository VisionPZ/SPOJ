const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007'i64
const inverseOfTwo = 500000004'i64

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var powerResult = 1'i64
  var baseCopy = baseValue mod answerModulus
  var exponentCopy = exponentValue
  while exponentCopy > 0:
    if (exponentCopy and 1'i64) != 0:
      powerResult = (powerResult * baseCopy) mod answerModulus
    baseCopy = (baseCopy * baseCopy) mod answerModulus
    exponentCopy = exponentCopy shr 1
  return powerResult

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let primeValue = int64(nextInt(inputData, scanPos))
  let exponentValue = int64(nextInt(inputData, scanPos))
  let primeResidue = primeValue mod answerModulus
  let primePower = powerMod(primeResidue, exponentValue)
  var geometricSum = 0'i64
  if primeResidue == 1:
    geometricSum = exponentValue mod answerModulus
  else:
    let denominatorResidue = (primeValue - 1) mod answerModulus
    let denominatorInverse = powerMod(denominatorResidue, answerModulus - 2)
    geometricSum = ((primePower - 1 + answerModulus) mod answerModulus) * denominatorInverse mod answerModulus
  let exponentResidue = exponentValue mod answerModulus
  let difference = (geometricSum - exponentResidue + answerModulus) mod answerModulus
  let doubledPart = primePower * difference mod answerModulus
  let answer = (doubledPart * inverseOfTwo + geometricSum) mod answerModulus
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
