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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc rowLength(gridSize: int, rowIndex: int): int =
  let distanceFromEdge = rowIndex
  let distanceFromBottom = 2 * gridSize - 2 - rowIndex
  if distanceFromEdge < distanceFromBottom:
    return gridSize + distanceFromEdge
  return gridSize + distanceFromBottom

proc multiplyMatrices(leftMatrix: seq[seq[int64]], rightMatrix: seq[seq[int64]], modulus: int64, sizeValue: int): seq[seq[int64]] =
  var resultMatrix = newSeq[seq[int64]](sizeValue)
  for rowIndex in 0 .. sizeValue - 1:
    resultMatrix[rowIndex] = newSeq[int64](sizeValue)
  for rowIndex in 0 .. sizeValue - 1:
    for midIndex in 0 .. sizeValue - 1:
      let leftValue = leftMatrix[rowIndex][midIndex]
      if leftValue == 0:
        continue
      for columnIndex in 0 .. sizeValue - 1:
        let rightValue = rightMatrix[midIndex][columnIndex]
        if rightValue == 0:
          continue
        resultMatrix[rowIndex][columnIndex] = (resultMatrix[rowIndex][columnIndex] + leftValue * rightValue) mod modulus
  return resultMatrix

proc applyVector(vectorValue: seq[int64], matrixValue: seq[seq[int64]], modulus: int64, sizeValue: int): seq[int64] =
  var resultVector = newSeq[int64](sizeValue)
  for midIndex in 0 .. sizeValue - 1:
    let sourceValue = vectorValue[midIndex]
    if sourceValue == 0:
      continue
    for columnIndex in 0 .. sizeValue - 1:
      let factorValue = matrixValue[midIndex][columnIndex]
      if factorValue == 0:
        continue
      resultVector[columnIndex] = (resultVector[columnIndex] + sourceValue * factorValue) mod modulus
  return resultVector

proc totalViruses(gridSize: int, modulus: int64, periods: int64, initialValues: seq[int64]): int64 =
  let lastRow = 2 * gridSize - 2
  var cellIndices = newSeq[seq[int]](lastRow + 1)
  var cellCount = 0
  for rowIndex in 0 .. lastRow:
    let width = rowLength(gridSize, rowIndex)
    cellIndices[rowIndex] = newSeq[int](width)
    for columnIndex in 0 .. width - 1:
      cellIndices[rowIndex][columnIndex] = cellCount
      cellCount += 1
  var transition = newSeq[seq[int64]](cellCount)
  for rowIndex in 0 .. cellCount - 1:
    transition[rowIndex] = newSeq[int64](cellCount)
  for rowIndex in 0 .. lastRow:
    let width = rowLength(gridSize, rowIndex)
    for columnIndex in 0 .. width - 1:
      let targetIndex = cellIndices[rowIndex][columnIndex]
      transition[targetIndex][targetIndex] = (transition[targetIndex][targetIndex] + 1) mod modulus
      var sourceIndices = newSeq[int]()
      if columnIndex > 0:
        sourceIndices.add cellIndices[rowIndex][columnIndex - 1]
      if columnIndex + 1 < width:
        sourceIndices.add cellIndices[rowIndex][columnIndex + 1]
      if rowIndex > 0:
        let aboveWidth = rowLength(gridSize, rowIndex - 1)
        if aboveWidth == width + 1:
          sourceIndices.add cellIndices[rowIndex - 1][columnIndex]
          if columnIndex + 1 < aboveWidth:
            sourceIndices.add cellIndices[rowIndex - 1][columnIndex + 1]
        else:
          if columnIndex > 0:
            sourceIndices.add cellIndices[rowIndex - 1][columnIndex - 1]
          if columnIndex < aboveWidth:
            sourceIndices.add cellIndices[rowIndex - 1][columnIndex]
      if rowIndex < lastRow:
        let belowWidth = rowLength(gridSize, rowIndex + 1)
        if belowWidth == width + 1:
          sourceIndices.add cellIndices[rowIndex + 1][columnIndex]
          if columnIndex + 1 < belowWidth:
            sourceIndices.add cellIndices[rowIndex + 1][columnIndex + 1]
        else:
          if columnIndex > 0:
            sourceIndices.add cellIndices[rowIndex + 1][columnIndex - 1]
          if columnIndex < belowWidth:
            sourceIndices.add cellIndices[rowIndex + 1][columnIndex]
      for sourceIndex in sourceIndices:
        transition[targetIndex][sourceIndex] = (transition[targetIndex][sourceIndex] + 1) mod modulus
  var stateVector = newSeq[int64](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    stateVector[cellIndex] = initialValues[cellIndex] mod modulus
  var exponentLeft = periods
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      stateVector = applyVector(stateVector, transition, modulus, cellCount)
    exponentLeft = exponentLeft div 2
    if exponentLeft > 0:
      transition = multiplyMatrices(transition, transition, modulus, cellCount)
  var answerValue: int64 = 0
  for cellIndex in 0 .. cellCount - 1:
    answerValue = answerValue + stateVector[cellIndex]
  return answerValue

var caseNumber = 1
while true:
  let gridSize = nextInt(inputData, scanPos)
  let modulusValue = int64(nextInt(inputData, scanPos))
  let periods = int64(nextInt(inputData, scanPos))
  if gridSize == 0 and modulusValue == 0 and periods == 0:
    break
  let lastRow = 2 * gridSize - 2
  var initialValues = newSeq[int64]()
  for rowIndex in 0 .. lastRow:
    let width = rowLength(gridSize, rowIndex)
    for columnIndex in 0 .. width - 1:
      initialValues.add int64(nextInt(inputData, scanPos))
  let answer = totalViruses(gridSize, modulusValue, periods, initialValues)
  appendOutput("Case " & $caseNumber & ": " & $answer)
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
