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

proc integerSquareRoot(value: int): int =
  var root = 0
  while (root + 1) * (root + 1) <= value:
    root += 1
  return root

proc pellSolution(value: int): tuple[xValue: int, yValue: int] =
  let wholePart = integerSquareRoot(value)
  var term = wholePart
  var numerator = 0
  var denominator = 1
  var periodLength = 0
  while true:
    numerator = denominator * term - numerator
    denominator = (value - numerator * numerator) div denominator
    term = (wholePart + numerator) div denominator
    periodLength += 1
    if term == 2 * wholePart:
      break
  var targetIndex = periodLength - 1
  if periodLength mod 2 == 1:
    targetIndex = 2 * periodLength - 1
  var previousNumerator = 1
  var currentNumerator = wholePart
  var previousDenominator = 0
  var currentDenominator = 1
  var convergentIndex = 1
  term = wholePart
  numerator = 0
  denominator = 1
  while convergentIndex <= targetIndex:
    numerator = denominator * term - numerator
    denominator = (value - numerator * numerator) div denominator
    term = (wholePart + numerator) div denominator
    let nextNumerator = term * currentNumerator + previousNumerator
    let nextDenominator = term * currentDenominator + previousDenominator
    previousNumerator = currentNumerator
    currentNumerator = nextNumerator
    previousDenominator = currentDenominator
    currentDenominator = nextDenominator
    convergentIndex += 1
  return (currentNumerator, currentDenominator)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let coefficient = nextInt(inputData, scanPos)
  let solution = pellSolution(coefficient)
  appendOutput($solution.xValue & " " & $solution.yValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
