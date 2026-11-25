const flushBlockBytes = 1 shl 17
const dieFaces = 6
const equationScale = 6.0
const decimalPlaces = 1000

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

proc hasMoreData(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

proc floatAbs(value: float): float =
  if value < 0.0:
    return -value
  return value

proc formatFixed3(value: float): string =
  let scaled = int(value * float(decimalPlaces) + 0.5)
  let wholePart = scaled div decimalPlaces
  let fractionPart = scaled mod decimalPlaces
  var fractionText = "000"
  fractionText[0] = char(48 + fractionPart div 100)
  fractionText[1] = char(48 + (fractionPart div 10) mod 10)
  fractionText[2] = char(48 + fractionPart mod 10)
  return $wholePart & "." & fractionText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreData(inputData, scanPos):
  let boardRows = nextInt(inputData, scanPos)
  let boardColumns = nextInt(inputData, scanPos)
  let snakeCount = nextInt(inputData, scanPos)
  let ladderCount = nextInt(inputData, scanPos)
  let topSquare = boardRows * boardColumns
  var destination = newSeq[int](topSquare + 1)
  for snakeIndex in 0 ..< snakeCount:
    let snakeHead = nextInt(inputData, scanPos)
    let snakeTail = nextInt(inputData, scanPos)
    destination[snakeHead] = snakeTail
  for ladderIndex in 0 ..< ladderCount:
    let ladderBottom = nextInt(inputData, scanPos)
    let ladderTop = nextInt(inputData, scanPos)
    destination[ladderBottom] = ladderTop
  var finalSquare = newSeq[int](topSquare + 1)
  for square in 1 .. topSquare:
    if finalSquare[square] != 0:
      continue
    var path: seq[int] = @[]
    var current = square
    var steps = 0
    while steps <= topSquare:
      if finalSquare[current] != 0 or destination[current] == 0:
        break
      path.add current
      current = destination[current]
      steps += 1
    var baseSquare = current
    if finalSquare[current] != 0:
      baseSquare = finalSquare[current]
    for node in path:
      finalSquare[node] = baseSquare
    finalSquare[square] = baseSquare
  let stateCount = topSquare
  var matrix = newSeq[seq[float]](stateCount)
  for row in 0 ..< stateCount:
    matrix[row] = newSeq[float](stateCount + 1)
    for col in 0 .. stateCount:
      matrix[row][col] = 0.0
  for state in 0 ..< stateCount:
    matrix[state][stateCount] = equationScale
    var overshootCount = 0
    for dieFace in 1 .. dieFaces:
      let rawSquare = state + dieFace
      if rawSquare > topSquare:
        overshootCount += 1
      else:
        let landing = finalSquare[rawSquare]
        if landing < topSquare:
          matrix[state][landing] -= 1.0
    matrix[state][state] += equationScale - float(overshootCount)
  for pivotCol in 0 ..< stateCount:
    var pivotRow = pivotCol
    for row in pivotCol + 1 ..< stateCount:
      if floatAbs(matrix[row][pivotCol]) > floatAbs(matrix[pivotRow][pivotCol]):
        pivotRow = row
    if pivotRow != pivotCol:
      for col in pivotCol .. stateCount:
        swap matrix[pivotCol][col], matrix[pivotRow][col]
    let pivotValue = matrix[pivotCol][pivotCol]
    if floatAbs(pivotValue) < 1e-12:
      continue
    for col in pivotCol .. stateCount:
      matrix[pivotCol][col] /= pivotValue
    for row in 0 ..< stateCount:
      if row == pivotCol:
        continue
      let factor = matrix[row][pivotCol]
      if floatAbs(factor) < 1e-12:
        continue
      for col in pivotCol .. stateCount:
        matrix[row][col] -= factor * matrix[pivotCol][col]
  appendOutput(formatFixed3(matrix[0][stateCount]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
