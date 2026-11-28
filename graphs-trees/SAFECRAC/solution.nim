const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007

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

let testCount = nextInt(inputData, scanPos)
var requestedLengths = newSeq[int](testCount)
var largestLength = 0
for caseIndex in 0 .. testCount - 1:
  let requestedLength = nextInt(inputData, scanPos)
  requestedLengths[caseIndex] = requestedLength
  if requestedLength > largestLength:
    largestLength = requestedLength

var neighborDigits = newSeq[seq[int]](10)
neighborDigits[0] = @[7]
neighborDigits[1] = @[2, 4]
neighborDigits[2] = @[1, 3, 5]
neighborDigits[3] = @[2, 6]
neighborDigits[4] = @[1, 5, 7]
neighborDigits[5] = @[2, 4, 6, 8]
neighborDigits[6] = @[3, 5, 9]
neighborDigits[7] = @[4, 8, 0]
neighborDigits[8] = @[5, 7, 9]
neighborDigits[9] = @[6, 8]

var countsByDigit = newSeq[int](10)
for digit in 0 .. 9:
  countsByDigit[digit] = 1
var answersByLength = newSeq[int](largestLength + 1)
if largestLength >= 1:
  answersByLength[1] = 10
if largestLength >= 2:
  for lengthIndex in 2 .. largestLength:
    var nextCounts = newSeq[int](10)
    for digit in 0 .. 9:
      var totalCount: int64 = 0
      for previousDigit in neighborDigits[digit]:
        totalCount += int64(countsByDigit[previousDigit])
      nextCounts[digit] = int(totalCount mod int64(answerModulus))
    var lengthTotal: int64 = 0
    for digit in 0 .. 9:
      lengthTotal += int64(nextCounts[digit])
    answersByLength[lengthIndex] = int(lengthTotal mod int64(answerModulus))
    countsByDigit = nextCounts

for caseIndex in 0 .. testCount - 1:
  appendOutput($answersByLength[requestedLengths[caseIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
