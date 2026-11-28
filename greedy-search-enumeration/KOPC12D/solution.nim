const flushBlockBytes = 1 shl 17
const digitKinds = 8
const subsetCount = 256

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

proc greatestCommonDivisor(firstValue: int, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainderValue = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainderValue
  return leftValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var digitCounts = newSeq[int](digitKinds)
  var totalInstances = 0
  for digitIndex in 0 .. digitKinds - 1:
    digitCounts[digitIndex] = nextInt(inputData, scanPos)
    totalInstances += digitCounts[digitIndex]
  var bestLength = 1
  let searchLimit = 2 * totalInstances + 16
  for subsetMask in 1 .. subsetCount - 1:
    var requiredPositions = 0
    var forbiddenPeriod = 1
    for digitIndex in 0 .. digitKinds - 1:
      if (subsetMask and (1 shl digitIndex)) != 0:
        requiredPositions += digitCounts[digitIndex]
        let digitValue = digitIndex + 2
        forbiddenPeriod = forbiddenPeriod div
          greatestCommonDivisor(forbiddenPeriod, digitValue) * digitValue
    if requiredPositions == 0:
      continue
    var lengthCandidate = 1
    while lengthCandidate - lengthCandidate div forbiddenPeriod < requiredPositions:
      lengthCandidate += 1
      if lengthCandidate > searchLimit:
        break
    if lengthCandidate > bestLength:
      bestLength = lengthCandidate
  appendOutput($bestLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
