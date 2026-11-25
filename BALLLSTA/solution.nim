const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var rowCount = nextInt(inputData, scanPos)
while rowCount != 0:
  var rowOffsets = newSeq[int](rowCount + 1)
  for rowIndex in 0 .. rowCount:
    rowOffsets[rowIndex] = rowIndex * (rowIndex + 1) div 2
  var ballValues = newSeq[int64](rowOffsets[rowCount])
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. rowIndex:
      ballValues[rowOffsets[rowIndex] + columnIndex] = int64(nextInt(inputData, scanPos))
  var previousBest = newSeq[int64](rowCount + 2)
  var prefixSums = newSeq[int64](rowCount + 2)
  var bestPrize: int64 = 0
  var columnIndex = 0
  while columnIndex < rowCount:
    let columnLength = rowCount - columnIndex
    var runningTotal: int64 = 0
    for ballPosition in 1 .. columnLength:
      let sourceRow = columnIndex + ballPosition - 1
      runningTotal = runningTotal + ballValues[rowOffsets[sourceRow] + columnIndex]
      prefixSums[ballPosition] = runningTotal
    var currentBest = newSeq[int64](columnLength + 2)
    currentBest[columnLength + 1] = -(int64(1) shl 60)
    var ballPosition = columnLength
    while ballPosition >= 1:
      let takeThroughHere = previousBest[ballPosition] + prefixSums[ballPosition]
      if takeThroughHere > currentBest[ballPosition + 1]:
        currentBest[ballPosition] = takeThroughHere
      else:
        currentBest[ballPosition] = currentBest[ballPosition + 1]
      if currentBest[ballPosition] > bestPrize:
        bestPrize = currentBest[ballPosition]
      ballPosition -= 1
    previousBest = currentBest
    columnIndex += 1
  appendOutput($bestPrize)
  outputBuffer.add '\n'
  rowCount = nextInt(inputData, scanPos)
stdout.write outputBuffer
outputBuffer.setLen 0
