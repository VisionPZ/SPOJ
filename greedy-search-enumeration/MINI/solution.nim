const flushBlockBytes = 1 shl 17
const modulusValue = int64(1000000009)
const exponentModulus = int64(1000000008)

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

var parsedBaseResidue = int64(0)
var parsedPowerResidue = int64(0)

proc nextOrderResidues(data: string, pos: var int) =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  parsedBaseResidue = 0
  parsedPowerResidue = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    let digitValue = int64(int(data[pos]) - 48)
    parsedBaseResidue = (parsedBaseResidue * 10 + digitValue) mod modulusValue
    parsedPowerResidue = (parsedPowerResidue * 10 + digitValue) mod exponentModulus
    pos += 1

proc powerModulo(baseValue, exponentValue: int64): int64 =
  var resultValue = int64(1)
  var factorValue = baseValue mod modulusValue
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1) == 1:
      resultValue = (resultValue * factorValue) mod modulusValue
    factorValue = (factorValue * factorValue) mod modulusValue
    remainingExponent = remainingExponent div 2
  return resultValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  nextOrderResidues(inputData, scanPos)
  let reducedOrder = if parsedPowerResidue == 0:
                       exponentModulus - 1
                     else:
                       parsedPowerResidue - 1
  let exponentValue = (reducedOrder * reducedOrder) mod exponentModulus
  appendOutput($powerModulo(parsedBaseResidue, exponentValue))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
