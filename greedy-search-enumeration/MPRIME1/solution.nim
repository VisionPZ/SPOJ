const flushBlockBytes = 1 shl 17
const maxQueryValue = 11000

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

var isComposite = newSeq[bool](maxQueryValue + 1)
var baseValue = 2
while baseValue * baseValue <= maxQueryValue:
  if not isComposite[baseValue]:
    var multipleValue = baseValue * baseValue
    while multipleValue <= maxQueryValue:
      isComposite[multipleValue] = true
      multipleValue += baseValue
  baseValue += 1

var primeNumbers = newSeq[int](0)
for candidateValue in 2 .. maxQueryValue:
  if not isComposite[candidateValue]:
    primeNumbers.add candidateValue

var representationCounts = newSeq[int](maxQueryValue + 1)
for startIndex in 0 .. primeNumbers.len - 1:
  var runningTotal = 0
  for endIndex in startIndex .. primeNumbers.len - 1:
    runningTotal += primeNumbers[endIndex]
    if runningTotal > maxQueryValue:
      break
    representationCounts[runningTotal] += 1

while true:
  let queryValue = nextInt(inputData, scanPos)
  if queryValue == 0:
    break
  appendOutput($(representationCounts[queryValue]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
