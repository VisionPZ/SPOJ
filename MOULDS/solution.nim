import sequtils

const cuboidSize = 250
const maxPenetration = 30
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc scanSigned(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var sign = 1
  if scanPos < inputData.len and inputData[scanPos] == '-':
    sign = -1
    scanPos = scanPos + 1
  elif scanPos < inputData.len and inputData[scanPos] == '+':
    scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos = scanPos + 1
  return sign * value

proc cutCell(hollowDepth: var seq[int], cellRow, cellCol, cutDepth: int) =
  if cutDepth > 0 and cellRow >= 0 and cellRow < cuboidSize and cellCol >= 0 and cellCol < cuboidSize:
    var cellIndex = cellRow * cuboidSize + cellCol
    if cutDepth > hollowDepth[cellIndex]:
      hollowDepth[cellIndex] = cutDepth

var hollowDepth = repeat(0, cuboidSize * cuboidSize)
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var scanPos = 0
var caseCount = scanSigned(inputData, scanPos)
var outputBuffer: string
for caseIndex in 1 .. caseCount:
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ': scanPos = scanPos + 1
  var tokenEnd = scanPos
  var commandPos = tokenStart
  var bladeDepth = -1
  var bladeRow = 0
  var bladeCol = 0
  while commandPos < tokenEnd:
    var commandChar = inputData[commandPos]
    if commandChar == '^':
      commandPos = commandPos + 1
      var liftDistance = scanSigned(inputData, commandPos)
      bladeDepth = bladeDepth + liftDistance
      if bladeDepth > maxPenetration: bladeDepth = maxPenetration
      cutCell(hollowDepth, bladeRow, bladeCol, bladeDepth)
    elif commandChar == '@':
      commandPos = commandPos + 1
      var shiftDirection = inputData[commandPos]
      commandPos = commandPos + 1
      var shiftDistance = scanSigned(inputData, commandPos)
      var rowFrom = bladeRow
      var colFrom = bladeCol
      var rowTo = bladeRow
      var colTo = bladeCol
      if shiftDirection == 'N': rowTo = bladeRow - shiftDistance
      elif shiftDirection == 'S': rowTo = bladeRow + shiftDistance
      elif shiftDirection == 'W': colTo = bladeCol - shiftDistance
      elif shiftDirection == 'E': colTo = bladeCol + shiftDistance
      if rowTo != rowFrom:
        var rowLow = max(0, min(rowFrom, rowTo))
        var rowHigh = min(cuboidSize - 1, max(rowFrom, rowTo))
        var penetration = bladeDepth
        if penetration > maxPenetration: penetration = maxPenetration
        for sweepRow in rowLow .. rowHigh:
          cutCell(hollowDepth, sweepRow, bladeCol, penetration)
      else:
        var colLow = max(0, min(colFrom, colTo))
        var colHigh = min(cuboidSize - 1, max(colFrom, colTo))
        var penetration = bladeDepth
        if penetration > maxPenetration: penetration = maxPenetration
        for sweepCol in colLow .. colHigh:
          cutCell(hollowDepth, bladeRow, sweepCol, penetration)
      bladeRow = rowTo
      bladeCol = colTo
    else:
      commandPos = commandPos + 1
  var volume = 0
  for cellDepth in hollowDepth: volume = volume + cellDepth
  outputBuffer.add $volume
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  for cellIndex in 0 .. (cuboidSize * cuboidSize - 1): hollowDepth[cellIndex] = 0
stdout.write outputBuffer
