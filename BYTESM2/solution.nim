const flushBlockBytes = 1 shl 17

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var previousRow = newSeq[int](columnCount)
  var currentRow = newSeq[int](columnCount)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let stoneCount = nextInt(inputData, scanPos)
      var bestAbove = previousRow[columnIndex]
      if columnIndex > 0 and previousRow[columnIndex - 1] > bestAbove:
        bestAbove = previousRow[columnIndex - 1]
      if columnIndex + 1 < columnCount and previousRow[columnIndex + 1] > bestAbove:
        bestAbove = previousRow[columnIndex + 1]
      currentRow[columnIndex] = stoneCount + bestAbove
    swap previousRow, currentRow
  var bestHarvest = previousRow[0]
  for columnIndex in 1 .. columnCount - 1:
    if previousRow[columnIndex] > bestHarvest:
      bestHarvest = previousRow[columnIndex]
  appendOutput($bestHarvest)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
