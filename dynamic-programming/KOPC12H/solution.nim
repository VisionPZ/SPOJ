const flushBlockBytes = 1 shl 17
const maximumDigits = 10
const differenceOffset = 100
const differenceRange = 201

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

proc digitContribution(digitValue: int): int =
  if (digitValue mod 2) == 0:
    return digitValue
  return -digitValue

var ways = newSeq[seq[int]](maximumDigits + 1)
for remainingIndex in 0 .. maximumDigits:
  ways[remainingIndex] = newSeq[int](differenceRange)
for differenceIndex in 0 .. differenceRange - 1:
  if differenceIndex - differenceOffset > 0:
    ways[0][differenceIndex] = 1
for remainingCount in 1 .. maximumDigits:
  for differenceIndex in 0 .. differenceRange - 1:
    let currentDifference = differenceIndex - differenceOffset
    var completionCount = 0
    for digitValue in 0 .. 9:
      let nextDifference = currentDifference + digitContribution(digitValue)
      if nextDifference >= -differenceOffset and nextDifference <= differenceOffset:
        completionCount += ways[remainingCount - 1][nextDifference + differenceOffset]
    ways[remainingCount][differenceIndex] = completionCount

proc countUpTo(limitValue: int): int =
  if limitValue <= 0:
    return 0
  var digits = newSeq[int]()
  var remainingValue = limitValue
  while remainingValue > 0:
    digits.add(remainingValue mod 10)
    remainingValue = remainingValue div 10
  var answerTotal = 0
  var runningDifference = 0
  var position = digits.len - 1
  while position >= 0:
    let currentDigit = digits[position]
    let remainingCount = position
    for smallerDigit in 0 .. currentDigit - 1:
      let nextDifference = runningDifference + digitContribution(smallerDigit)
      if nextDifference >= -differenceOffset and nextDifference <= differenceOffset:
        answerTotal += ways[remainingCount][nextDifference + differenceOffset]
    runningDifference += digitContribution(currentDigit)
    position -= 1
  if runningDifference > 0:
    answerTotal += 1
  return answerTotal

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let lowerBound = nextInt(inputData, scanPos)
  let upperBound = nextInt(inputData, scanPos)
  let answerValue = countUpTo(upperBound) - countUpTo(lowerBound - 1)
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
