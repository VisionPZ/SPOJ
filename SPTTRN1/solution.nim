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

proc buildPattern(size: int): seq[string] =
  var rows = newSeq[string](size)
  for rowIndex in 0 ..< size:
    var line = ""
    for columnIndex in 0 ..< size:
      line.add '.'
    rows[rowIndex] = line
  var layer = 0
  while true:
    let topRow = 2 * layer
    let bottomRow = size - 1 - 2 * layer
    let leftCol = 2 * layer
    let rightCol = size - 1 - 2 * layer
    if topRow > bottomRow or leftCol > rightCol:
      break
    var startCol = 2 * layer - 2
    if startCol < 0:
      startCol = 0
    var columnIndex = startCol
    while columnIndex <= rightCol:
      rows[topRow][columnIndex] = '*'
      columnIndex += 1
    var rowIndex = topRow
    while rowIndex <= bottomRow:
      rows[rowIndex][rightCol] = '*'
      rowIndex += 1
    if topRow + 2 <= bottomRow:
      columnIndex = leftCol
      while columnIndex <= rightCol:
        rows[bottomRow][columnIndex] = '*'
        columnIndex += 1
    else:
      rows[bottomRow][rightCol] = '*'
    rowIndex = topRow + 2
    while rowIndex <= bottomRow:
      rows[rowIndex][leftCol] = '*'
      rowIndex += 1
    layer += 1
  return rows

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let size = nextInt(inputData, scanPos)
  let rows = buildPattern(size)
  for rowIndex in 0 ..< size:
    appendOutput(rows[rowIndex])
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
