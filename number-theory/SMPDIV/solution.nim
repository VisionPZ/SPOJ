const firstDigitValue = 48
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
var caseIndex = 0
while caseIndex < caseCount:
  let limitValue = nextInt(inputData, scanPos)
  let divisor = nextInt(inputData, scanPos)
  let excludedDivisor = nextInt(inputData, scanPos)
  var candidate = (1 + divisor) div divisor * divisor
  var hasPrevious = false
  while candidate < limitValue:
    if candidate > 1 and candidate mod excludedDivisor != 0:
      if hasPrevious:
        appendOutput(" ")
      appendOutput($(candidate))
      hasPrevious = true
    candidate += divisor
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
