const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const exponentModulus = 1000000006

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

proc multiplyMatrices(leftMatrix: array[4, int64], rightMatrix: array[4, int64]): array[4, int64] =
  result[0] = (leftMatrix[0] * rightMatrix[0] + leftMatrix[1] * rightMatrix[2]) mod exponentModulus
  result[1] = (leftMatrix[0] * rightMatrix[1] + leftMatrix[1] * rightMatrix[3]) mod exponentModulus
  result[2] = (leftMatrix[2] * rightMatrix[0] + leftMatrix[3] * rightMatrix[2]) mod exponentModulus
  result[3] = (leftMatrix[2] * rightMatrix[1] + leftMatrix[3] * rightMatrix[3]) mod exponentModulus

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var baseLeft = baseValue mod modulusValue
  var exponentLeft = exponentValue
  result = 1
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      result = (result * baseLeft) mod modulusValue
    baseLeft = (baseLeft * baseLeft) mod modulusValue
    exponentLeft = exponentLeft shr 1

let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let firstSeed = int64(nextInt(inputData, scanPos))
  let secondSeed = int64(nextInt(inputData, scanPos))
  let termIndex = int64(nextInt(inputData, scanPos))
  let exponentFactor = int64(nextInt(inputData, scanPos))
  var answer: int64 = 0
  if termIndex == 0:
    answer = firstSeed mod modulusValue
  elif termIndex == 1:
    answer = secondSeed mod modulusValue
  elif exponentFactor == 0:
    answer = 1
  else:
    var stepMatrix = [exponentFactor mod exponentModulus, exponentFactor mod exponentModulus, int64(1), int64(0)]
    var productMatrix = [int64(1), int64(0), int64(0), int64(1)]
    var remainingSteps = termIndex - 1
    while remainingSteps > 0:
      if (remainingSteps and 1) == 1:
        productMatrix = multiplyMatrices(productMatrix, stepMatrix)
      stepMatrix = multiplyMatrices(stepMatrix, stepMatrix)
      remainingSteps = remainingSteps shr 1
    let firstExponent = productMatrix[1]
    let secondExponent = productMatrix[0]
    let firstBase = firstSeed mod modulusValue
    let secondBase = secondSeed mod modulusValue
    if firstBase == 0 or secondBase == 0:
      answer = 0
    else:
      answer = (powerMod(firstBase, firstExponent) * powerMod(secondBase, secondExponent)) mod modulusValue
  appendOutput($answer)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
