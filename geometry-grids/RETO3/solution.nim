const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInteger(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos += 1
  var parsedValue = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return signValue * parsedValue

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let gridOrder = int(nextInteger(inputData, scanPos))
let cellCount = gridOrder * gridOrder
var cellValues = newSeq[int64](cellCount)
var emptyRow = -1
var emptyColumn = -1
var cellIndex = 0
for rowIndex in 0 ..< gridOrder:
  for columnIndex in 0 ..< gridOrder:
    let currentValue = nextInteger(inputData, scanPos)
    cellValues[cellIndex] = currentValue
    if currentValue == 0:
      emptyRow = rowIndex
      emptyColumn = columnIndex
    cellIndex += 1

var rowTotals = newSeq[int64](gridOrder)
var columnTotals = newSeq[int64](gridOrder)
var mainDiagonalTotal = 0'i64
var otherDiagonalTotal = 0'i64
cellIndex = 0
for rowIndex in 0 ..< gridOrder:
  for columnIndex in 0 ..< gridOrder:
    let currentValue = cellValues[cellIndex]
    rowTotals[rowIndex] += currentValue
    columnTotals[columnIndex] += currentValue
    if rowIndex == columnIndex:
      mainDiagonalTotal += currentValue
    if rowIndex + columnIndex == gridOrder - 1:
      otherDiagonalTotal += currentValue
    cellIndex += 1

if gridOrder == 1:
  appendOutput("1\n")
else:
  let referenceRow = if emptyRow == 0: 1 else: 0
  let targetTotal = rowTotals[referenceRow]
  let candidateValue = targetTotal - rowTotals[emptyRow]
  var isMagic = candidateValue >= 1'i64
  if isMagic:
    for rowIndex in 0 ..< gridOrder:
      let completedTotal = rowTotals[rowIndex] + (if rowIndex == emptyRow: candidateValue else: 0'i64)
      if completedTotal != targetTotal:
        isMagic = false
    for columnIndex in 0 ..< gridOrder:
      let completedTotal = columnTotals[columnIndex] + (if columnIndex == emptyColumn: candidateValue else: 0'i64)
      if completedTotal != targetTotal:
        isMagic = false
    let mainCompleted = mainDiagonalTotal + (if emptyRow == emptyColumn: candidateValue else: 0'i64)
    let otherCompleted = otherDiagonalTotal + (if emptyRow + emptyColumn == gridOrder - 1: candidateValue else: 0'i64)
    if mainCompleted != targetTotal or otherCompleted != targetTotal:
      isMagic = false
  if isMagic:
    appendOutput($candidateValue)
    outputBuffer.add '\n'
  else:
    appendOutput("-1\n")

stdout.write outputBuffer
