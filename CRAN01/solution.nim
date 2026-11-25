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
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let initialRow = nextInt(inputData, scanPos)
  let initialColumn = nextInt(inputData, scanPos)
  let rowsAbove = initialRow - 1
  let rowsBelow = rowCount - initialRow
  let columnsLeft = initialColumn - 1
  let columnsRight = columnCount - initialColumn
  var farthestRows = rowsAbove
  if rowsBelow > farthestRows:
    farthestRows = rowsBelow
  var farthestColumns = columnsLeft
  if columnsRight > farthestColumns:
    farthestColumns = columnsRight
  appendOutput($(farthestRows + farthestColumns))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
