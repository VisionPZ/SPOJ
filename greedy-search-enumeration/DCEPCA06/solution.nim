const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const digitCount = 10
const maximumBit = 30

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

proc absoluteDifference(firstDigit, secondDigit: int): int =
  if firstDigit >= secondDigit:
    return firstDigit - secondDigit
  return secondDigit - firstDigit

proc multiplyMatrices(leftMatrix: seq[seq[int64]], rightMatrix: seq[seq[int64]]): seq[seq[int64]] =
  result = newSeq[seq[int64]](digitCount)
  for rowIndex in 0 .. digitCount - 1:
    result[rowIndex] = newSeq[int64](digitCount)
    for columnIndex in 0 .. digitCount - 1:
      var total: int64 = 0
      for innerIndex in 0 .. digitCount - 1:
        total = (total + leftMatrix[rowIndex][innerIndex] * rightMatrix[innerIndex][columnIndex]) mod modulusValue
      result[rowIndex][columnIndex] = total

var transitionPowers = newSeq[seq[seq[seq[int64]]]](digitCount)
for gapValue in 0 .. digitCount - 1:
  var baseMatrix = newSeq[seq[int64]](digitCount)
  for previousDigit in 0 .. digitCount - 1:
    baseMatrix[previousDigit] = newSeq[int64](digitCount)
    for nextDigit in 0 .. digitCount - 1:
      if absoluteDifference(previousDigit, nextDigit) >= gapValue:
        baseMatrix[previousDigit][nextDigit] = 1
  transitionPowers[gapValue] = newSeq[seq[seq[int64]]](maximumBit)
  transitionPowers[gapValue][0] = baseMatrix
  for bitIndex in 1 .. maximumBit - 1:
    transitionPowers[gapValue][bitIndex] = multiplyMatrices(
      transitionPowers[gapValue][bitIndex - 1], transitionPowers[gapValue][bitIndex - 1])

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberLength = nextInt(inputData, scanPos)
  let gapValue = nextInt(inputData, scanPos)
  var state = newSeq[int64](digitCount)
  for leadingDigit in 1 .. digitCount - 1:
    state[leadingDigit] = 1
  var remainingSteps = numberLength - 1
  var bitIndex = 0
  while remainingSteps > 0:
    if (remainingSteps and 1) == 1:
      var updated = newSeq[int64](digitCount)
      for previousDigit in 0 .. digitCount - 1:
        for nextDigit in 0 .. digitCount - 1:
          updated[nextDigit] = (updated[nextDigit] + state[previousDigit] *
            transitionPowers[gapValue][bitIndex][previousDigit][nextDigit]) mod modulusValue
      state = updated
    remainingSteps = remainingSteps shr 1
    bitIndex += 1
  var answer: int64 = 0
  for lastDigit in 0 .. digitCount - 1:
    answer = (answer + state[lastDigit]) mod modulusValue
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
