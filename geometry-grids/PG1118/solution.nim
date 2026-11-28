const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInteger(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

let order = nextInteger(inputData, scanPos)
let magicConstant = order * (order * order + 1) div 2
appendOutput($(magicConstant))
appendOutput("\n")

var cells = newSeq[int](order * order)
var currentRow = order div 2
var currentCol = order - 1
for placedValue in 1..(order * order):
  cells[currentRow * order + currentCol] = placedValue
  var nextRow = currentRow - 1
  if nextRow < 0:
    nextRow = order - 1
  var nextCol = currentCol + 1
  if nextCol == order:
    nextCol = 0
  if cells[nextRow * order + nextCol] != 0:
    currentCol = currentCol - 1
    if currentCol < 0:
      currentCol = order - 1
  else:
    currentRow = nextRow
    currentCol = nextCol

for rowIndex in 0..<order:
  for colIndex in 0..<order:
    if colIndex > 0:
      appendOutput(" ")
    appendOutput($(cells[rowIndex * order + colIndex]))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
