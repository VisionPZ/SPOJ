const flushBlockBytes = 1 shl 17
const maxRowsToScan: int64 = 100000

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let matchCount: int64 = int64(nextInt(inputData, scanPos))
  var rowLimit: int64 = matchCount
  if rowLimit > maxRowsToScan:
    rowLimit = maxRowsToScan
  var bestRectangles: int64 = 0
  var rowCount: int64 = 1
  while rowCount <= rowLimit:
    let budgetAfterRows = matchCount - rowCount
    let denominator = 2 * rowCount + 1
    let baseLength = budgetAfterRows div denominator
    let leftover = budgetAfterRows mod denominator
    var extraRows: int64 = 0
    if leftover > 0:
      extraRows = (leftover - 1) div 2
      if extraRows >= rowCount:
        extraRows = rowCount - 1
    let triangularLength = baseLength * (baseLength + 1) div 2
    let triangularRows = rowCount * (rowCount + 1) div 2
    let baseRectangles = triangularLength * triangularRows
    let extraRectangles = (baseLength + 1) * extraRows * (extraRows + 1) div 2
    let totalRectangles = baseRectangles + extraRectangles
    if totalRectangles > bestRectangles:
      bestRectangles = totalRectangles
    if baseLength == 0:
      break
    rowCount += 1
  appendOutput($bestRectangles)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
