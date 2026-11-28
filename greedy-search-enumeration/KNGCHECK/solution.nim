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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var boardCells = newSeq[string](64)
  for cellIndex in 0 .. 63:
    boardCells[cellIndex] = nextToken(inputData, scanPos)
  var kingRow = -1
  var kingCol = -1
  for cellIndex in 0 .. 63:
    if boardCells[cellIndex] == "BK":
      kingRow = cellIndex div 8
      kingCol = cellIndex mod 8
  var attacked = false
  for cellIndex in 0 .. 63:
    let piece = boardCells[cellIndex]
    if piece == "-":
      continue
    let pieceRow = cellIndex div 8
    let pieceCol = cellIndex mod 8
    let rowGap = abs(kingRow - pieceRow)
    let colGap = abs(kingCol - pieceCol)
    if piece == "WH":
      if (rowGap == 1 and colGap == 2) or (rowGap == 2 and colGap == 1):
        attacked = true
    elif piece == "WP":
      if pieceRow - kingRow == 1 and colGap == 1:
        attacked = true
    elif piece == "WK":
      if rowGap <= 1 and colGap <= 1:
        attacked = true
  appendOutput("Case #" & $(caseIndex + 1) & ": ")
  if attacked:
    appendOutput("Check")
  else:
    appendOutput("Not Check")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
