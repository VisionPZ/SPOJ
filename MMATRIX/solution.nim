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
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

proc hasMoreNumbers(data: string, pos: int): bool =
  var index = pos
  while index < data.len:
    if data[index] >= '0' and data[index] <= '9':
      return true
    index += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var matrixSize = 0
var rotatedValues: seq[seq[seq[int]]]
var columnSums: seq[int]
var bestColumnMax = 0

proc evaluateRemainingRows(rowIndex: int) =
  if rowIndex == matrixSize:
    var currentMax = columnSums[0]
    for colIndex in 1 .. matrixSize - 1:
      if columnSums[colIndex] > currentMax:
        currentMax = columnSums[colIndex]
    if currentMax < bestColumnMax:
      bestColumnMax = currentMax
    return
  for shiftAmount in 0 .. matrixSize - 1:
    for colIndex in 0 .. matrixSize - 1:
      columnSums[colIndex] += rotatedValues[rowIndex][shiftAmount][colIndex]
    evaluateRemainingRows(rowIndex + 1)
    for colIndex in 0 .. matrixSize - 1:
      columnSums[colIndex] -= rotatedValues[rowIndex][shiftAmount][colIndex]

while hasMoreNumbers(inputData, scanPos):
  matrixSize = nextInt(inputData, scanPos)
  if matrixSize == -1:
    break
  var matrixRows = newSeq[seq[int]](matrixSize)
  for rowIndex in 0 .. matrixSize - 1:
    matrixRows[rowIndex] = newSeq[int](matrixSize)
    for colIndex in 0 .. matrixSize - 1:
      matrixRows[rowIndex][colIndex] = nextInt(inputData, scanPos)
  rotatedValues = newSeq[seq[seq[int]]](matrixSize)
  for rowIndex in 0 .. matrixSize - 1:
    rotatedValues[rowIndex] = newSeq[seq[int]](matrixSize)
    for shiftAmount in 0 .. matrixSize - 1:
      rotatedValues[rowIndex][shiftAmount] = newSeq[int](matrixSize)
      for colIndex in 0 .. matrixSize - 1:
        rotatedValues[rowIndex][shiftAmount][colIndex] =
          matrixRows[rowIndex][(colIndex + shiftAmount) mod matrixSize]
  columnSums = newSeq[int](matrixSize)
  for colIndex in 0 .. matrixSize - 1:
    columnSums[colIndex] = rotatedValues[0][0][colIndex]
  bestColumnMax = 1 shl 50
  evaluateRemainingRows(1)
  appendOutput($(bestColumnMax))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
