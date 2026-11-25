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

let rowCount = nextInt(inputData, scanPos)
let colCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
let stride = colCount + 1
var fenwick = newSeq[int64](stride * (rowCount + 1))

for row in 1..rowCount:
  let base = row * stride
  for col in 1..colCount:
    let hiveSize = nextInt(inputData, scanPos)
    fenwick[base + col] += int64(hiveSize)
    let parent = col + (col and -col)
    if parent <= colCount:
      fenwick[base + parent] += fenwick[base + col]

for row in 1..rowCount:
  let parent = row + (row and -row)
  if parent <= rowCount:
    let base = row * stride
    let parentBase = parent * stride
    for col in 1..colCount:
      fenwick[parentBase + col] += fenwick[base + col]

proc addHive(rowPos: int, colPos: int, delta: int64) =
  var row = rowPos
  while row <= rowCount:
    let base = row * stride
    var col = colPos
    while col <= colCount:
      fenwick[base + col] += delta
      col += col and -col
    row += row and -row

proc prefixSum(rowPos: int, colPos: int): int64 =
  var total: int64 = 0
  var row = rowPos
  while row > 0:
    let base = row * stride
    var col = colPos
    while col > 0:
      total += fenwick[base + col]
      col -= col and -col
    row -= row and -row
  return total

proc rectangleSum(firstRow: int, firstCol: int, lastRow: int, lastCol: int): int64 =
  return prefixSum(lastRow, lastCol) - prefixSum(firstRow - 1, lastCol) -
         prefixSum(lastRow, firstCol - 1) + prefixSum(firstRow - 1, firstCol - 1)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for q in 0..<queryCount:
  let queryType = nextInt(inputData, scanPos)
  if queryType == 1:
    let rowPos = nextInt(inputData, scanPos)
    let colPos = nextInt(inputData, scanPos)
    let bornBees = nextInt(inputData, scanPos)
    addHive(rowPos, colPos, int64(bornBees))
  else:
    let firstRow = nextInt(inputData, scanPos)
    let firstCol = nextInt(inputData, scanPos)
    let lastRow = nextInt(inputData, scanPos)
    let lastCol = nextInt(inputData, scanPos)
    appendOutput($(rectangleSum(firstRow, firstCol, lastRow, lastCol)))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
