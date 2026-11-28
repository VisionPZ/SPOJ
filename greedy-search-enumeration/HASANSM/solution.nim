const flushBlockBytes = 1 shl 17
const packsPerKitkatType = 7

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc minModStep(modulusValue, stepValue, startValue, stepLimit: int64): int64 =
  var currentModulus = modulusValue
  var currentStep = stepValue mod currentModulus
  var currentStart = startValue mod currentModulus
  var currentLimit = stepLimit
  var bestValue = currentStart
  while currentLimit > 0 and currentStep != 0:
    let shrink = currentModulus mod currentStep
    let blockCount = (currentStart + currentLimit * currentStep) div currentModulus
    if blockCount == 0:
      return bestValue
    let nextStart = (currentStart - shrink + currentStep) mod currentStep
    let nextStep = (currentStep - shrink) mod currentStep
    if nextStart < bestValue:
      bestValue = nextStart
    currentModulus = currentStep
    currentStep = nextStep
    currentStart = nextStart
    currentLimit = blockCount - 1
  return bestValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var caseIndex: int64 = 0
while caseIndex < caseCount:
  let budget = nextInt(inputData, scanPos)
  let milkPrice = nextInt(inputData, scanPos)
  let kitkatPrice = nextInt(inputData, scanPos)
  let kitkatCost = packsPerKitkatType * kitkatPrice
  let stepValue = (milkPrice - kitkatCost mod milkPrice) mod milkPrice
  let startValue = budget mod milkPrice
  let stepLimit = budget div kitkatCost
  let leftover = minModStep(milkPrice, stepValue, startValue, stepLimit)
  appendOutput($leftover)
  outputBuffer.add '\n'
  caseIndex += 1

stdout.write outputBuffer
outputBuffer.setLen 0
