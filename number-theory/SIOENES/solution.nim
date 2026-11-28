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
var queries = newSeq[int](caseCount)
var limitNumber = 0
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > limitNumber:
    limitNumber = queries[caseIndex]

var isPrime = newSeq[bool](limitNumber + 1)
for numberValue in 0 .. limitNumber:
  isPrime[numberValue] = true
if limitNumber >= 0:
  isPrime[0] = false
if limitNumber >= 1:
  isPrime[1] = false
var primeCandidate = 2
while primeCandidate * primeCandidate <= limitNumber:
  if isPrime[primeCandidate]:
    var multipleValue = primeCandidate * primeCandidate
    while multipleValue <= limitNumber:
      isPrime[multipleValue] = false
      multipleValue = multipleValue + primeCandidate
  primeCandidate += 1

var primeCounts = newSeq[int](limitNumber + 1)
for numberValue in 1 .. limitNumber:
  primeCounts[numberValue] = primeCounts[numberValue - 1]
  if isPrime[numberValue]:
    primeCounts[numberValue] += 1
for caseIndex in 0 .. caseCount - 1:
  appendOutput($primeCounts[queries[caseIndex]])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
