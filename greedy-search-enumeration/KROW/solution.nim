const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const directionCount = 4
const rowStepValues = [0, 1, 1, 1]
const columnStepValues = [1, 0, 1, -1]

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let firstCharPos = pos
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    pos += 1
  return data[firstCharPos ..< pos]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let gameCount = nextInt(inputData, scanPos)
var hanselWins = 0
var gretelWins = 0
for gameIndex in 0 ..< gameCount:
  let columnCount = nextInt(inputData, scanPos)
  let rowCount = nextInt(inputData, scanPos)
  let requiredLength = nextInt(inputData, scanPos)
  var board = newSeq[string](rowCount)
  for rowIndex in 0 ..< rowCount:
    board[rowIndex] = nextWord(inputData, scanPos)
  var winnerMark = '.'
  for rowIndex in 0 ..< rowCount:
    for columnIndex in 0 ..< columnCount:
      let markChar = board[rowIndex][columnIndex]
      if markChar == '.':
        continue
      for directionIndex in 0 ..< directionCount:
        let rowStep = rowStepValues[directionIndex]
        let columnStep = columnStepValues[directionIndex]
        let previousRow = rowIndex - rowStep
        let previousColumn = columnIndex - columnStep
        if previousRow >= 0 and previousRow < rowCount and previousColumn >= 0 and previousColumn < columnCount and board[previousRow][previousColumn] == markChar:
          continue
        var runLength = 0
        var scanRow = rowIndex
        var scanColumn = columnIndex
        while scanRow >= 0 and scanRow < rowCount and scanColumn >= 0 and scanColumn < columnCount and board[scanRow][scanColumn] == markChar:
          runLength += 1
          scanRow += rowStep
          scanColumn += columnStep
        if runLength >= requiredLength:
          winnerMark = markChar
  if winnerMark == 'x':
    hanselWins += 1
  elif winnerMark == 'o':
    gretelWins += 1
appendOutput($hanselWins & ":" & $gretelWins)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
