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

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
for rowIndex in 0 .. rowCount - 1:
  var rowText = ""
  for columnIndex in 0 .. columnCount - 1:
    let cellValue = nextInt(inputData, scanPos)
    if columnIndex > 0:
      rowText.add '\t'
    rowText.add $cellValue
  appendOutput(rowText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
