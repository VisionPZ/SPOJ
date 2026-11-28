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
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var rowCount = nextInt(inputData, scanPos)
  var columnCount = nextInt(inputData, scanPos)
  var matrix = newSeq[int](rowCount * columnCount)
  for cellIndex in 0 .. rowCount * columnCount - 1:
    matrix[cellIndex] = nextInt(inputData, scanPos)
  if rowCount > columnCount:
    var transposed = newSeq[int](rowCount * columnCount)
    for originalRow in 0 .. rowCount - 1:
      for originalColumn in 0 .. columnCount - 1:
        transposed[originalColumn * rowCount + originalRow] = matrix[originalRow * columnCount + originalColumn]
    let previousRows = rowCount
    rowCount = columnCount
    columnCount = previousRows
    matrix = transposed
  var bestArea: int64 = 0
  for topRow in 0 .. rowCount - 1:
    var columnUp = newSeq[bool](columnCount)
    var rowRightAll = newSeq[bool](columnCount)
    for columnIndex in 0 .. columnCount - 1:
      columnUp[columnIndex] = true
      if columnIndex == 0:
        rowRightAll[columnIndex] = true
      else:
        rowRightAll[columnIndex] = matrix[topRow * columnCount + columnIndex] > matrix[topRow * columnCount + columnIndex - 1]
    for bottomRow in topRow .. rowCount - 1:
      if bottomRow > topRow:
        for columnIndex in 0 .. columnCount - 1:
          let currentValue = matrix[bottomRow * columnCount + columnIndex]
          columnUp[columnIndex] = columnUp[columnIndex] and (currentValue > matrix[(bottomRow - 1) * columnCount + columnIndex])
          if columnIndex > 0:
            rowRightAll[columnIndex] = rowRightAll[columnIndex] and (currentValue > matrix[bottomRow * columnCount + columnIndex - 1])
      let height = bottomRow - topRow + 1
      var currentRun = 0
      for columnIndex in 0 .. columnCount - 1:
        if columnUp[columnIndex] and rowRightAll[columnIndex]:
          currentRun += 1
        else:
          currentRun = 0
        var width = 0
        if columnUp[columnIndex]:
          width = 1
        if currentRun > 0:
          let startColumn = columnIndex - currentRun
          var candidateWidth = currentRun
          if startColumn >= 0:
            if columnUp[startColumn]:
              candidateWidth = currentRun + 1
          if candidateWidth > width:
            width = candidateWidth
        let area = int64(height) * int64(width)
        if area > bestArea:
          bestArea = area
  appendOutput($bestArea)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
