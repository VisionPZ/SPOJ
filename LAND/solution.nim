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

proc integerRoot(value: int64): int64 =
  var root = int64(sqrt(float(value)))
  while (root + 1) * (root + 1) <= value:
    root += 1
  while root * root > value:
    root -= 1
  return root

proc pellSolution(doubledArea: int64): (int64, int64) =
  let rootArea = integerRoot(doubledArea)
  if rootArea * rootArea == doubledArea:
    return (rootArea, int64(1))
  var partialNumerator = int64(0)
  var partialDenominator = int64(1)
  var partialQuotient = rootArea
  var prevPrevNumerator = int64(0)
  var prevPrevDenominator = int64(1)
  var prevNumerator = int64(1)
  var prevDenominator = int64(0)
  var currentNumerator = rootArea
  var currentDenominator = int64(1)
  var periodLength = 0
  while true:
    partialNumerator = partialDenominator * partialQuotient - partialNumerator
    partialDenominator = (doubledArea - partialNumerator * partialNumerator) div partialDenominator
    partialQuotient = (rootArea + partialNumerator) div partialDenominator
    prevPrevNumerator = prevNumerator
    prevPrevDenominator = prevDenominator
    prevNumerator = currentNumerator
    prevDenominator = currentDenominator
    currentNumerator = partialQuotient * prevNumerator + prevPrevNumerator
    currentDenominator = partialQuotient * prevDenominator + prevPrevDenominator
    periodLength += 1
    if partialQuotient == 2 * rootArea:
      break
  if periodLength mod 2 == 0:
    return (prevNumerator, prevDenominator)
  for stepIndex in 1 .. periodLength - 1:
    partialNumerator = partialDenominator * partialQuotient - partialNumerator
    partialDenominator = (doubledArea - partialNumerator * partialNumerator) div partialDenominator
    partialQuotient = (rootArea + partialNumerator) div partialDenominator
    prevPrevNumerator = prevNumerator
    prevPrevDenominator = prevDenominator
    prevNumerator = currentNumerator
    prevDenominator = currentDenominator
    currentNumerator = partialQuotient * prevNumerator + prevPrevNumerator
    currentDenominator = partialQuotient * prevDenominator + prevPrevDenominator
  return (currentNumerator, currentDenominator)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseNumber = 1
while true:
  let blockCount = nextInt(inputData, scanPos)
  if blockCount == 0:
    break
  let doubledArea = int64(2 * blockCount)
  let answer = pellSolution(doubledArea)
  appendOutput("Case " & $caseNumber & ": " & $answer[0] & " " & $answer[1])
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
