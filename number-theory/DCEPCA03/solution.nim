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

let caseCount = nextInt(inputData, scanPos)
var queryValues = newSeq[int](caseCount)
var largestQuery = 0
for caseIndex in 0 .. caseCount - 1:
  queryValues[caseIndex] = nextInt(inputData, scanPos)
  if queryValues[caseIndex] > largestQuery:
    largestQuery = queryValues[caseIndex]

var totients = newSeq[int](largestQuery + 1)
for numberValue in 0 .. largestQuery:
  totients[numberValue] = numberValue
for primeCandidate in 2 .. largestQuery:
  if totients[primeCandidate] == primeCandidate:
    var multiple = primeCandidate
    while multiple <= largestQuery:
      totients[multiple] = totients[multiple] div primeCandidate * (primeCandidate - 1)
      multiple += primeCandidate

var prefixTotients = newSeq[int64](largestQuery + 1)
for numberValue in 1 .. largestQuery:
  prefixTotients[numberValue] = prefixTotients[numberValue - 1] + int64(totients[numberValue])

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  let totientSum = prefixTotients[queryValues[caseIndex]]
  appendOutput($(totientSum * totientSum))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
