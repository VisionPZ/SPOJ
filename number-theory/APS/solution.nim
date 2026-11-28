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

let caseCount = nextInt(inputData, scanPos)
var requestedValues = newSeq[int](caseCount)
var largestValue = 0
for caseIndex in 0 .. caseCount - 1:
  let requestedValue = nextInt(inputData, scanPos)
  requestedValues[caseIndex] = requestedValue
  if requestedValue > largestValue:
    largestValue = requestedValue

var smallestPrimeFactor = newSeq[int32](largestValue + 1)
if largestValue >= 2:
  for primeCandidate in 2 .. largestValue:
    if smallestPrimeFactor[primeCandidate] == 0:
      smallestPrimeFactor[primeCandidate] = int32(primeCandidate)
      if int64(primeCandidate) * int64(primeCandidate) <= int64(largestValue):
        var multiple = primeCandidate * primeCandidate
        while multiple <= largestValue:
          if smallestPrimeFactor[multiple] == 0:
            smallestPrimeFactor[multiple] = int32(primeCandidate)
          multiple += primeCandidate

var sequenceValues = newSeq[int64](largestValue + 1)
if largestValue >= 2:
  for valueIndex in 2 .. largestValue:
    sequenceValues[valueIndex] = sequenceValues[valueIndex - 1] + int64(smallestPrimeFactor[valueIndex])

for caseIndex in 0 .. caseCount - 1:
  appendOutput($sequenceValues[requestedValues[caseIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
