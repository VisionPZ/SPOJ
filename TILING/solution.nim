const flushBlockBytes = 1 shl 17

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

proc nextLetterRun(data: string, pos: var int, count: int): string =
  result = ""
  while result.len < count:
    while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
      pos += 1
    if pos >= data.len:
      break
    result.add data[pos]
    pos += 1

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
  let boardCells = nextLetterRun(inputData, scanPos, rowCount * columnCount)
  var rowDivisors: seq[int] = @[]
  var columnDivisors: seq[int] = @[]
  for candidate in 1 .. rowCount:
    if rowCount mod candidate == 0:
      rowDivisors.add candidate
  for candidate in 1 .. columnCount:
    if columnCount mod candidate == 0:
      columnDivisors.add candidate
  var bestArea = rowCount * columnCount
  for heightIndex in 0 .. rowDivisors.len - 1:
    let patternHeight = rowDivisors[heightIndex]
    for widthIndex in 0 .. columnDivisors.len - 1:
      let patternWidth = columnDivisors[widthIndex]
      let candidateArea = patternHeight * patternWidth
      if candidateArea >= bestArea:
        continue
      var tilesCleanly = true
      var rowIndex = 0
      while rowIndex < rowCount and tilesCleanly:
        let modelRow = rowIndex mod patternHeight
        var columnIndex = 0
        while columnIndex < columnCount:
          let modelColumn = columnIndex mod patternWidth
          if boardCells[rowIndex * columnCount + columnIndex] != boardCells[modelRow * columnCount + modelColumn]:
            tilesCleanly = false
            break
          columnIndex += 1
        rowIndex += 1
      if tilesCleanly:
        bestArea = candidateArea
  appendOutput($bestArea)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
