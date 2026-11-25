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

proc nextRawLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  let rawText = data[pos .. lineEnd - 1]
  pos = lineEnd + 1
  return rawText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
discard nextRawLine(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let fieldWidth = nextInt(inputData, scanPos)
  discard nextRawLine(inputData, scanPos)
  let textLine = nextRawLine(inputData, scanPos)
  let totalPadding = fieldWidth - textLine.len
  let leftPadding = (totalPadding + 1) div 2
  let rightPadding = totalPadding div 2
  var starIndex = 0
  while starIndex < leftPadding:
    appendOutput("*")
    starIndex += 1
  appendOutput(textLine)
  starIndex = 0
  while starIndex < rightPadding:
    appendOutput("*")
    starIndex += 1
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
