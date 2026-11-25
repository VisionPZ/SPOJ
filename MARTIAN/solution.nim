const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const unreachableScore = -1 shl 50

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

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  let prefixWidth = columnCount + 1
  var yPrefix = newSeq[int](rowCount * prefixWidth)
  for rowIndex in 0 .. rowCount - 1:
    let rowStart = rowIndex * prefixWidth
    for columnIndex in 0 .. columnCount - 1:
      let mineralAmount = nextInt(inputData, scanPos)
      yPrefix[rowStart + columnIndex + 1] = yPrefix[rowStart + columnIndex] + mineralAmount
  var previousBest = newSeq[int64](prefixWidth)
  var currentBest = newSeq[int64](prefixWidth)
  var prefixBest = newSeq[int64](prefixWidth)
  var bloggiumRow = newSeq[int](columnCount)
  var suffixTotals = newSeq[int](prefixWidth)
  previousBest[0] = 0
  for splitIndex in 1 .. columnCount:
    previousBest[splitIndex] = unreachableScore
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      bloggiumRow[columnIndex] = nextInt(inputData, scanPos)
    suffixTotals[columnCount] = 0
    for columnIndex in countdown(columnCount - 1, 0):
      suffixTotals[columnIndex] = suffixTotals[columnIndex + 1] + bloggiumRow[columnIndex]
    var runningBest: int64 = unreachableScore
    for splitIndex in 0 .. columnCount:
      if previousBest[splitIndex] > runningBest:
        runningBest = previousBest[splitIndex]
      prefixBest[splitIndex] = runningBest
    let rowStart = rowIndex * prefixWidth
    for splitIndex in 0 .. columnCount:
      currentBest[splitIndex] = prefixBest[splitIndex] +
        int64(yPrefix[rowStart + splitIndex]) + int64(suffixTotals[splitIndex])
    let swapBuffer = previousBest
    previousBest = currentBest
    currentBest = swapBuffer
  var bestMinerals: int64 = unreachableScore
  for splitIndex in 0 .. columnCount:
    if previousBest[splitIndex] > bestMinerals:
      bestMinerals = previousBest[splitIndex]
  appendOutput($bestMinerals)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
