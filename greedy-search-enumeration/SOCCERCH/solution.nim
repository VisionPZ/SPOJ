const flushBlockBytes = 1 shl 17
const unreachableDistance = 1000000000

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

proc nextFieldWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] notin {'I', 'X', 'O'}:
    pos += 1
  var word = ""
  while pos < data.len and data[pos] in {'I', 'X', 'O'}:
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc solveForCorner(field: seq[string], cornerRow, cornerCol: int): int =
  let fieldRows = field.len
  let fieldCols = field[0].len
  var interestingRows: seq[int] = @[]
  var interestingCols: seq[int] = @[]
  var wantedMask = 0
  for rowIndex in 0 .. fieldRows - 1:
    for colIndex in 0 .. fieldCols - 1:
      if field[rowIndex][colIndex] != 'O':
        let bitIndex = interestingRows.len
        interestingRows.add rowIndex
        interestingCols.add colIndex
        if field[rowIndex][colIndex] == 'I':
          wantedMask = wantedMask or (1 shl bitIndex)
  let interestingCount = interestingRows.len
  let maskCount = 1 shl interestingCount
  let vertexCols = fieldCols + 1
  let vertexCount = (fieldRows + 1) * vertexCols
  var flipMasks = newSeq[seq[int]](fieldRows)
  for rowIndex in 0 .. fieldRows - 1:
    flipMasks[rowIndex] = newSeq[int](fieldCols + 1)
    for colIndex in 0 .. fieldCols:
      var flipMask = 0
      for bitIndex in 0 .. interestingCount - 1:
        if interestingRows[bitIndex] == rowIndex and interestingCols[bitIndex] < colIndex:
          flipMask = flipMask or (1 shl bitIndex)
      flipMasks[rowIndex][colIndex] = flipMask
  let stateCount = vertexCount * maskCount
  var distances = newSeq[int](stateCount)
  var queue = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    distances[stateIndex] = unreachableDistance
  let startVertex = cornerRow * vertexCols + cornerCol
  let goalState = startVertex * maskCount + wantedMask
  let startState = startVertex * maskCount
  distances[startState] = 0
  var queueHead = 0
  var queueTail = 0
  queue[queueTail] = startState
  queueTail += 1
  while queueHead < queueTail:
    let stateIndex = queue[queueHead]
    queueHead += 1
    let currentDistance = distances[stateIndex]
    let currentMask = stateIndex mod maskCount
    let currentVertex = stateIndex div maskCount
    if stateIndex == goalState:
      return currentDistance
    let currentRow = currentVertex div vertexCols
    let currentCol = currentVertex mod vertexCols
    if currentRow > 0:
      let nextVertex = currentVertex - vertexCols
      let nextMask = currentMask xor flipMasks[currentRow - 1][currentCol]
      let nextState = nextVertex * maskCount + nextMask
      if distances[nextState] > currentDistance + 1:
        distances[nextState] = currentDistance + 1
        queue[queueTail] = nextState
        queueTail += 1
    if currentRow < fieldRows:
      let nextVertex = currentVertex + vertexCols
      let nextMask = currentMask xor flipMasks[currentRow][currentCol]
      let nextState = nextVertex * maskCount + nextMask
      if distances[nextState] > currentDistance + 1:
        distances[nextState] = currentDistance + 1
        queue[queueTail] = nextState
        queueTail += 1
    if currentCol > 0:
      let nextVertex = currentVertex - 1
      let nextState = nextVertex * maskCount + currentMask
      if distances[nextState] > currentDistance + 1:
        distances[nextState] = currentDistance + 1
        queue[queueTail] = nextState
        queueTail += 1
    if currentCol < fieldCols:
      let nextVertex = currentVertex + 1
      let nextState = nextVertex * maskCount + currentMask
      if distances[nextState] > currentDistance + 1:
        distances[nextState] = currentDistance + 1
        queue[queueTail] = nextState
        queueTail += 1
  return unreachableDistance

while true:
  let fieldRows = nextInt(inputData, scanPos)
  let fieldCols = nextInt(inputData, scanPos)
  if fieldRows == 0 and fieldCols == 0:
    break
  var field: seq[string] = @[]
  for rowIndex in 0 .. fieldRows - 1:
    field.add nextFieldWord(inputData, scanPos)
  let fernandoLength = solveForCorner(field, 0, 0)
  let martinLength = solveForCorner(field, fieldRows, fieldCols)
  if fernandoLength < martinLength:
    appendOutput("Fernando ")
    appendOutput($fernandoLength)
  elif martinLength < fernandoLength:
    appendOutput("Martin ")
    appendOutput($martinLength)
  else:
    appendOutput("Tie ")
    appendOutput($fernandoLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
