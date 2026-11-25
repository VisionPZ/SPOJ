const flushBlockBytes = 1 shl 17
const fullDigitMask = 1022

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

var boardCells = newSeq[int](81)
var rowMasks = newSeq[int](9)
var columnMasks = newSeq[int](9)
var boxMasks = newSeq[int](9)
var recordedSolution = newSeq[int](81)
var solutionCount = 0

proc searchSolutions() =
  var bestCell = -1
  var bestMask = 0
  var bestOptions = 10
  for cellIndex in 0 .. 80:
    if boardCells[cellIndex] == 0:
      let rowIndex = cellIndex div 9
      let columnIndex = cellIndex mod 9
      let boxIndex = (rowIndex div 3) * 3 + columnIndex div 3
      let forbiddenMask = rowMasks[rowIndex] or columnMasks[columnIndex] or boxMasks[boxIndex]
      let candidateMask = fullDigitMask and (not forbiddenMask)
      var optionCount = 0
      for digitValue in 1 .. 9:
        if (candidateMask and (1 shl digitValue)) != 0:
          optionCount += 1
      if optionCount < bestOptions:
        bestOptions = optionCount
        bestCell = cellIndex
        bestMask = candidateMask
        if optionCount == 0:
          break
  if bestCell == -1:
    solutionCount += 1
    if solutionCount == 1:
      for cellIndex in 0 .. 80:
        recordedSolution[cellIndex] = boardCells[cellIndex]
    return
  if bestOptions == 0:
    return
  let rowIndex = bestCell div 9
  let columnIndex = bestCell mod 9
  let boxIndex = (rowIndex div 3) * 3 + columnIndex div 3
  for digitValue in 1 .. 9:
    let digitBit = 1 shl digitValue
    if (bestMask and digitBit) != 0:
      boardCells[bestCell] = digitValue
      rowMasks[rowIndex] = rowMasks[rowIndex] or digitBit
      columnMasks[columnIndex] = columnMasks[columnIndex] or digitBit
      boxMasks[boxIndex] = boxMasks[boxIndex] or digitBit
      searchSolutions()
      rowMasks[rowIndex] = rowMasks[rowIndex] and (not digitBit)
      columnMasks[columnIndex] = columnMasks[columnIndex] and (not digitBit)
      boxMasks[boxIndex] = boxMasks[boxIndex] and (not digitBit)
      boardCells[bestCell] = 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  for rowIndex in 0 .. 8:
    rowMasks[rowIndex] = 0
    columnMasks[rowIndex] = 0
    boxMasks[rowIndex] = 0
  for cellIndex in 0 .. 80:
    let givenValue = nextInt(inputData, scanPos)
    boardCells[cellIndex] = givenValue
    if givenValue != 0:
      let rowIndex = cellIndex div 9
      let columnIndex = cellIndex mod 9
      let boxIndex = (rowIndex div 3) * 3 + columnIndex div 3
      let digitBit = 1 shl givenValue
      rowMasks[rowIndex] = rowMasks[rowIndex] or digitBit
      columnMasks[columnIndex] = columnMasks[columnIndex] or digitBit
      boxMasks[boxIndex] = boxMasks[boxIndex] or digitBit
  solutionCount = 0
  searchSolutions()
  appendOutput($solutionCount)
  outputBuffer.add '\n'
  if solutionCount == 1:
    for rowIndex in 0 .. 8:
      for columnIndex in 0 .. 8:
        if columnIndex > 0:
          outputBuffer.add ' '
        outputBuffer.add char(48 + recordedSolution[rowIndex * 9 + columnIndex])
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
