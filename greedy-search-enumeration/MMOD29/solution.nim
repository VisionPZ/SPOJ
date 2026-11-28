const flushBlockBytes = 1 shl 17
const modulusValue = 29
const exponentOffset = 1
const exponentSkip = 2

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

proc powerMod(baseNumber: int, exponentValue: int, modulusNumber: int): int =
  var resultValue = 1
  var currentBase = baseNumber mod modulusNumber
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1) == 1:
      resultValue = (resultValue * currentBase) mod modulusNumber
    currentBase = (currentBase * currentBase) mod modulusNumber
    remainingExponent = remainingExponent shr 1
  return resultValue

proc inverseMod(valueNumber: int, modulusNumber: int): int =
  return powerMod(valueNumber, modulusNumber - exponentSkip, modulusNumber)

proc divisorSumModulo(exponentCount: int, primeBase: int): int =
  let powerValue = powerMod(primeBase, exponentCount + exponentOffset, modulusValue)
  let numeratorValue = (powerValue - 1 + modulusValue) mod modulusValue
  let denominatorValue = (primeBase - 1) mod modulusValue
  let inverseValue = inverseMod(denominatorValue, modulusValue)
  return (numeratorValue * inverseValue) mod modulusValue

proc solveCase(exponentValue: int): int =
  let firstPart = divisorSumModulo(exponentValue * exponentSkip, 2)
  let secondPart = divisorSumModulo(exponentValue, 3)
  let thirdPart = divisorSumModulo(exponentValue, 167)
  return (firstPart * secondPart mod modulusValue) * thirdPart mod modulusValue

while true:
  let exponentValue = nextInt(inputData, scanPos)
  if exponentValue == 0:
    break
  let answerValue = solveCase(exponentValue)
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
