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
for caseIndex in 0 .. caseCount - 1:
  let sideLength = nextInt(inputData, scanPos)
  var borderRow = ""
  for columnIndex in 1 .. sideLength:
    borderRow.add '#'
  var innerRow = "#"
  for columnIndex in 2 .. sideLength - 1:
    innerRow.add '.'
  if sideLength >= 2:
    innerRow.add '#'
  appendOutput(borderRow)
  outputBuffer.add '\n'
  for rowIndex in 2 .. sideLength - 1:
    appendOutput(innerRow)
    outputBuffer.add '\n'
  if sideLength >= 2:
    appendOutput(borderRow)
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
