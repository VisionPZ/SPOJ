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

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let cellChar = data[pos]
  pos += 1
  return cellChar

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let stride = columnCount + 1
  var cumulative = newSeq[int]((rowCount + 1) * stride)
  for rowIndex in 0 ..< rowCount:
    var rowTotal = 0
    for columnIndex in 0 ..< columnCount:
      let cellChar = nextCell(inputData, scanPos)
      var cellValue = 0
      if cellChar == 'B':
        cellValue = 1
      elif cellChar == 'T':
        cellValue = -1
      rowTotal = rowTotal + cellValue
      cumulative[(rowIndex + 1) * stride + columnIndex + 1] = cumulative[rowIndex * stride + columnIndex + 1] + rowTotal
  var bestTotal = 0
  for topRow in 0 ..< rowCount:
    for leftColumn in 0 ..< columnCount:
      let largestSide = min(rowCount - topRow, columnCount - leftColumn)
      for sideLength in 1 .. largestSide:
        let bottomRight = (topRow + sideLength) * stride + leftColumn + sideLength
        let topRight = topRow * stride + leftColumn + sideLength
        let bottomLeft = (topRow + sideLength) * stride + leftColumn
        let topLeft = topRow * stride + leftColumn
        let squareTotal = cumulative[bottomRight] - cumulative[topRight] - cumulative[bottomLeft] + cumulative[topLeft]
        if squareTotal > bestTotal:
          bestTotal = squareTotal
  appendOutput("Case " & $caseIndex & ": " & $bestTotal & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
