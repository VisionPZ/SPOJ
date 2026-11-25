const flushBlockBytes = 1 shl 17
const initialSentinel = 1000000000

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
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var prefixMinimum = newSeq[int](elementCount)
  var runningMinimum = initialSentinel
  for elementIndex in 0 .. elementCount - 1:
    let currentValue = nextInt(inputData, scanPos)
    if currentValue < runningMinimum:
      runningMinimum = currentValue
    prefixMinimum[elementIndex] = runningMinimum
  for queryIndex in 0 .. queryCount - 1:
    let rangeEnd = nextInt(inputData, scanPos)
    appendOutput($prefixMinimum[rangeEnd - 1])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
