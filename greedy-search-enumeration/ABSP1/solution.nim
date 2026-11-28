const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const pairCoefficientFactor = 2

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int64](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    values[elementIndex] = int64(nextInt(inputData, scanPos))
  var pairTotal: int64 = 0
  for elementIndex in 0 .. elementCount - 1:
    let coefficient = pairCoefficientFactor * elementIndex - elementCount + 1
    pairTotal = pairTotal + values[elementIndex] * int64(coefficient)
  appendOutput($pairTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
