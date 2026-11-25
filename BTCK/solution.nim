const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc minimalTailSum(coefficients: seq[int], available: seq[bool], position: int): int =
  if position >= 9:
    return 0
  var tailCoefficients = newSeq[int](9 - position)
  for index in position + 1 .. 9:
    tailCoefficients[index - position - 1] = coefficients[index]
  for outerIndex in 1 ..< tailCoefficients.len:
    let heldValue = tailCoefficients[outerIndex]
    var innerIndex = outerIndex - 1
    while innerIndex >= 0 and tailCoefficients[innerIndex] < heldValue:
      tailCoefficients[innerIndex + 1] = tailCoefficients[innerIndex]
      innerIndex -= 1
    tailCoefficients[innerIndex + 1] = heldValue
  var digitIndex = 0
  var total = 0
  for digit in 0 .. 9:
    if available[digit]:
      total += digit * tailCoefficients[digitIndex]
      digitIndex += 1
  return total

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  var coefficients = newSeq[int](10)
  for coeffIndex in 0 .. 9:
    coefficients[coeffIndex] = nextInt(inputData, scanPos)
  let limitValue = nextInt(inputData, scanPos)
  var available = newSeq[bool](10)
  for digit in 0 .. 9:
    available[digit] = true
  var answer = newSeq[int](10)
  var possible = true
  var spentSoFar = 0
  for position in 0 .. 9:
    var chosenDigit = -1
    for digit in 0 .. 9:
      if not available[digit]:
        continue
      available[digit] = false
      let candidateTotal = spentSoFar + coefficients[position] * digit + minimalTailSum(coefficients, available, position)
      if candidateTotal <= limitValue:
        chosenDigit = digit
        break
      available[digit] = true
    if chosenDigit < 0:
      possible = false
      break
    spentSoFar += coefficients[position] * chosenDigit
    answer[position] = chosenDigit
  if not possible:
    appendOutput("-1\n")
  else:
    for position in 0 .. 9:
      if position > 0:
        appendOutput(" ")
      appendOutput($answer[position])
    appendOutput("\n")
stdout.write outputBuffer
