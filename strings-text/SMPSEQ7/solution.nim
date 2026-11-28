const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sequenceLength = nextInt(inputData, scanPos)
var values = newSeq[int](sequenceLength)
var positionIndex = 0
while positionIndex < sequenceLength:
  values[positionIndex] = nextInt(inputData, scanPos)
  positionIndex += 1

var prefixLength = 1
while prefixLength < sequenceLength and values[prefixLength] < values[prefixLength - 1]:
  prefixLength += 1
var suffixLength = 1
while suffixLength < sequenceLength and values[sequenceLength - suffixLength - 1] < values[sequenceLength - suffixLength]:
  suffixLength += 1

var splitIndex = sequenceLength - suffixLength
if splitIndex < 1:
  splitIndex = 1
if splitIndex <= prefixLength:
  appendOutput("Yes")
else:
  appendOutput("No")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
