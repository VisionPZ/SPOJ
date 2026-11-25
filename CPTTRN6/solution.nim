const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
for caseIndex in 0 ..< caseCount:
  let lineCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let cellHeight = nextInt(inputData, scanPos)
  let cellWidth = nextInt(inputData, scanPos)
  let totalColumns = columnCount * (cellWidth + 1) + cellWidth
  for elementRow in 0 ..< lineCount:
    for insideRow in 0 ..< cellHeight:
      for columnIndex in 0 ..< totalColumns:
        if (columnIndex + 1) mod (cellWidth + 1) == 0:
          appendOutput("|")
        else:
          appendOutput(".")
      outputBuffer.add '\n'
    for columnIndex in 0 ..< totalColumns:
      if (columnIndex + 1) mod (cellWidth + 1) == 0:
        appendOutput("+")
      else:
        appendOutput("-")
    outputBuffer.add '\n'
  for insideRow in 0 ..< cellHeight:
    for columnIndex in 0 ..< totalColumns:
      if (columnIndex + 1) mod (cellWidth + 1) == 0:
        appendOutput("|")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
