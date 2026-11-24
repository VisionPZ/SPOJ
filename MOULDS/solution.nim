import sequtils

const cuboidSize = 250
const maxPenetration = 30
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc scanSigned(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var sign = 1
  if i < inputData.len and inputData[i] == '-':
    sign = -1
    i = i + 1
  elif i < inputData.len and inputData[i] == '+':
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i = i + 1
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
var i = 0
var caseCount = scanSigned(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var tokenStart = i
  while i < inputData.len and inputData[i] > ' ': i = i + 1
  var tokenEnd = i
  var k = tokenStart
  var bladeDepth = -1
  var bladeRow = 0
  var bladeCol = 0
  while k < tokenEnd:
    var commandChar = inputData[k]
    if commandChar == '^':
      k = k + 1
      var liftDistance = scanSigned(inputData, k)
      bladeDepth = bladeDepth + liftDistance
      if bladeDepth > maxPenetration: bladeDepth = maxPenetration
      cutCell(hollowDepth, bladeRow, bladeCol, bladeDepth)
    elif commandChar == '@':
      k = k + 1
      var shiftDirection = inputData[k]
      k = k + 1
      var shiftDistance = scanSigned(inputData, k)
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
        for i in rowLow .. rowHigh:
          cutCell(hollowDepth, i, bladeCol, penetration)
      else:
        var colLow = max(0, min(colFrom, colTo))
        var colHigh = min(cuboidSize - 1, max(colFrom, colTo))
        var penetration = bladeDepth
        if penetration > maxPenetration: penetration = maxPenetration
        for i in colLow .. colHigh:
          cutCell(hollowDepth, bladeRow, i, penetration)
      bladeRow = rowTo
      bladeCol = colTo
    else:
      k = k + 1
  var volume = 0
  for cellDepth in hollowDepth: volume = volume + cellDepth
  outputBuffer.add $volume
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  for cellIndex in 0 .. (cuboidSize * cuboidSize - 1): hollowDepth[cellIndex] = 0
stdout.write outputBuffer
