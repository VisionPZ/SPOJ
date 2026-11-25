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

let caseCount = nextInt(inputData, scanPos)
for _ in 0 ..< caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let diamondSize = nextInt(inputData, scanPos)
  let tileSide = 2 * diamondSize
  let slashSum = diamondSize - 1
  let totalRows = rowCount * tileSide
  let totalColumns = columnCount * tileSide
  for rowIndex in 0 ..< totalRows:
    let localRow = rowIndex mod tileSide
    for columnIndex in 0 ..< totalColumns:
      let localColumn = columnIndex mod tileSide
      let diagonalSum = localRow + localColumn
      let diagonalGap = abs(localRow - localColumn)
      if diagonalSum mod tileSide == slashSum:
        appendOutput("/")
      elif diagonalGap == diamondSize:
        appendOutput("\\")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
