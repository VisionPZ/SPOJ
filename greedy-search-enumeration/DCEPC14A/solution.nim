const flushBlockBytes = 1 shl 17
const maxCellValue = 100000

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

var rowCount = 0
var columnCount = 0
var bitGrid = newSeq[int]()

proc addCell(rowIndex: int, columnIndex: int) =
  var bitRow = rowIndex + 1
  while bitRow <= rowCount:
    var bitColumn = columnIndex + 1
    while bitColumn <= columnCount:
      let bitIndex = bitRow * (columnCount + 1) + bitColumn
      bitGrid[bitIndex] = bitGrid[bitIndex] + 1
      bitColumn = bitColumn + (bitColumn and -bitColumn)
    bitRow = bitRow + (bitRow and -bitRow)

proc countAboveLeft(rowIndex: int, columnIndex: int): int =
  var total = 0
  var bitRow = rowIndex + 1
  while bitRow > 0:
    var bitColumn = columnIndex + 1
    while bitColumn > 0:
      let bitIndex = bitRow * (columnCount + 1) + bitColumn
      total = total + bitGrid[bitIndex]
      bitColumn = bitColumn - (bitColumn and -bitColumn)
    bitRow = bitRow - (bitRow and -bitRow)
  return total

rowCount = nextInt(inputData, scanPos)
columnCount = nextInt(inputData, scanPos)
bitGrid = newSeq[int]((rowCount + 1) * (columnCount + 1))
var buckets = newSeq[seq[int]](maxCellValue + 1)
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cellValue = nextInt(inputData, scanPos)
    buckets[cellValue].add(rowIndex * columnCount + columnIndex)

var pairTotal: int64 = 0
var cellValue = maxCellValue
while cellValue >= 1:
  for cellIndex in buckets[cellValue]:
    let cellRow = cellIndex div columnCount
    let cellColumn = cellIndex mod columnCount
    pairTotal = pairTotal + int64(countAboveLeft(cellRow, cellColumn))
  for cellIndex in buckets[cellValue]:
    let cellRow = cellIndex div columnCount
    let cellColumn = cellIndex mod columnCount
    addCell(cellRow, cellColumn)
  cellValue -= 1

appendOutput($pairTotal)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
