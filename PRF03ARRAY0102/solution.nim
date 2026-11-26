import algorithm

const flushBlockBytes = 1 shl 17
const countPrompt = "How many element of numeric array:"
const valuePromptPrefix = "The value of a["
const valuePromptSuffix = "] is:"
const orderLabel = "ASC:"
const listHeadingSuffix = " element of numeric array:"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and ((data[pos] < '0' or data[pos] > '9') and data[pos] != '-'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let elementCount = nextInt(inputData, scanPos)
appendOutput(countPrompt)
var arrayValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  appendOutput(valuePromptPrefix)
  appendOutput($(elementIndex + 1))
  appendOutput(valuePromptSuffix)
  arrayValues[elementIndex] = nextInt(inputData, scanPos)
outputBuffer.add '\n'
outputBuffer.add '\n'
appendOutput(orderLabel)
outputBuffer.add '\n'
appendOutput($elementCount)
appendOutput(listHeadingSuffix)
outputBuffer.add '\n'
sort(arrayValues, cmp)
for elementIndex in 0 .. elementCount - 1:
  appendOutput(valuePromptPrefix)
  appendOutput($(elementIndex + 1))
  appendOutput(valuePromptSuffix)
  appendOutput($arrayValues[elementIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
