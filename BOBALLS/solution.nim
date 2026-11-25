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

proc nextField(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var field = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    field.add data[pos]
    pos += 1
  return field

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var grid = newSeq[string](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    grid[rowIndex] = nextField(inputData, scanPos)
  let cellCount = rowCount * columnCount
  var cellValues = newSeq[int](cellCount)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let cellChar = grid[rowIndex][columnIndex]
      if cellChar != 'P':
        cellValues[rowIndex * columnCount + columnIndex] = int(cellChar) - 48
  var cellProbability = newSeq[float](cellCount * columnCount)
  var singleExpected = newSeq[float](columnCount)
  for startColumn in 0 .. columnCount - 1:
    var currentProb = newSeq[float](columnCount)
    currentProb[startColumn] = 1.0
    for rowIndex in 0 .. rowCount - 1:
      var nextProb = newSeq[float](columnCount)
      for columnIndex in 0 .. columnCount - 1:
        let probability = currentProb[columnIndex]
        if probability == 0.0:
          continue
        let cellIndex = rowIndex * columnCount + columnIndex
        cellProbability[cellIndex * columnCount + startColumn] += probability
        singleExpected[startColumn] += probability * float(cellValues[cellIndex])
        if rowIndex == rowCount - 1:
          continue
        if grid[rowIndex + 1][columnIndex] != 'P':
          nextProb[columnIndex] += probability
        else:
          for directionIndex in 0 .. 1:
            var directionSign = 1
            if directionIndex == 0:
              directionSign = -1
            var stepColumn = columnIndex + directionSign
            while stepColumn >= 0 and stepColumn < columnCount and grid[rowIndex + 1][stepColumn] == 'P':
              let stepCell = rowIndex * columnCount + stepColumn
              cellProbability[stepCell * columnCount + startColumn] += probability * 0.5
              singleExpected[startColumn] += probability * 0.5 * float(cellValues[stepCell])
              stepColumn += directionSign
            let exitCell = rowIndex * columnCount + stepColumn
            cellProbability[exitCell * columnCount + startColumn] += probability * 0.5
            singleExpected[startColumn] += probability * 0.5 * float(cellValues[exitCell])
            nextProb[stepColumn] += probability * 0.5
      currentProb = nextProb

  var overlap = newSeq[float](columnCount * columnCount)
  for cellIndex in 0 .. cellCount - 1:
    let cellValue = float(cellValues[cellIndex])
    if cellValue == 0.0:
      continue
    let cellOffset = cellIndex * columnCount
    for firstColumn in 0 .. columnCount - 1:
      let firstProbability = cellProbability[cellOffset + firstColumn]
      if firstProbability == 0.0:
        continue
      for secondColumn in firstColumn .. columnCount - 1:
        let secondProbability = cellProbability[cellOffset + secondColumn]
        if secondProbability == 0.0:
          continue
        let overlapIndex = firstColumn * columnCount + secondColumn
        overlap[overlapIndex] += cellValue * firstProbability * secondProbability

  var bestExpected = 0.0
  for firstColumn in 0 .. columnCount - 1:
    for secondColumn in firstColumn .. columnCount - 1:
      let candidate = singleExpected[firstColumn] + singleExpected[secondColumn] - overlap[firstColumn * columnCount + secondColumn]
      if candidate > bestExpected:
        bestExpected = candidate
  let scaledScore = int(bestExpected * 10000.0 + 0.5)
  let wholePart = scaledScore div 10000
  let fractionPart = scaledScore mod 10000
  var fractionText = $(fractionPart)
  while fractionText.len < 4:
    fractionText = "0" & fractionText
  appendOutput($(wholePart) & "." & fractionText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
