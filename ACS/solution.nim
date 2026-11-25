const rowCount = 1234
const columnCount = 5678
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ': pos += 1
  if pos >= data.len: return ""
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ': pos += 1
  return data[tokenStart ..< pos]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ': pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var rowAtPosition = newSeq[int](rowCount + 1)
var rowPositionOfOriginal = newSeq[int](rowCount + 1)
var columnAtPosition = newSeq[int](columnCount + 1)
var columnPositionOfOriginal = newSeq[int](columnCount + 1)
for index in 1 .. rowCount:
  rowAtPosition[index] = index
  rowPositionOfOriginal[index] = index
for index in 1 .. columnCount:
  columnAtPosition[index] = index
  columnPositionOfOriginal[index] = index

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let commandToken = nextToken(inputData, scanPos)
  if commandToken.len == 0: break
  let commandLetter = commandToken[0]
  if commandLetter == 'R':
    let firstRow = nextInt(inputData, scanPos)
    let secondRow = nextInt(inputData, scanPos)
    let originalFirstRow = rowAtPosition[firstRow]
    let originalSecondRow = rowAtPosition[secondRow]
    rowAtPosition[firstRow] = originalSecondRow
    rowAtPosition[secondRow] = originalFirstRow
    rowPositionOfOriginal[originalFirstRow] = secondRow
    rowPositionOfOriginal[originalSecondRow] = firstRow
  elif commandLetter == 'C':
    let firstColumn = nextInt(inputData, scanPos)
    let secondColumn = nextInt(inputData, scanPos)
    let originalFirstColumn = columnAtPosition[firstColumn]
    let originalSecondColumn = columnAtPosition[secondColumn]
    columnAtPosition[firstColumn] = originalSecondColumn
    columnAtPosition[secondColumn] = originalFirstColumn
    columnPositionOfOriginal[originalFirstColumn] = secondColumn
    columnPositionOfOriginal[originalSecondColumn] = firstColumn
  elif commandLetter == 'Q':
    let queryRow = nextInt(inputData, scanPos)
    let queryColumn = nextInt(inputData, scanPos)
    let storedValue = (rowAtPosition[queryRow] - 1) * columnCount + columnAtPosition[queryColumn]
    appendOutput($storedValue)
  elif commandLetter == 'W':
    let targetValue = nextInt(inputData, scanPos)
    let originalRow = (targetValue - 1) div columnCount + 1
    let originalColumn = (targetValue - 1) mod columnCount + 1
    let currentRow = rowPositionOfOriginal[originalRow]
    let currentColumn = columnPositionOfOriginal[originalColumn]
    appendOutput($(currentRow) & " " & $(currentColumn))

stdout.write outputBuffer
outputBuffer.setLen 0
