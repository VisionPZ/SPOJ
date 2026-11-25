const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSide = 10
const maxSideSquared = 100
const viewCount = 6
const cubeCapacity = 1000
const rayCapacity = 6000
const emptyMark = '.'
const unknownMark = '#'

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc nextToken(inputData: string, scanPos: var int): string =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  let tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos += 1
  return inputData[tokenStart .. scanPos - 1]

proc viewCell(viewIndex, viewRow, viewCol, viewDepth, cubeSize: int): tuple[x, y, z: int] =
  case viewIndex
  of 0: result = (viewCol, cubeSize - 1 - viewRow, viewDepth)
  of 1: result = (viewDepth, cubeSize - 1 - viewRow, cubeSize - 1 - viewCol)
  of 2: result = (cubeSize - 1 - viewCol, cubeSize - 1 - viewRow, cubeSize - 1 - viewDepth)
  of 3: result = (cubeSize - 1 - viewDepth, cubeSize - 1 - viewRow, viewCol)
  of 4: result = (viewCol, cubeSize - 1 - viewDepth, cubeSize - 1 - viewRow)
  else: result = (viewCol, viewDepth, viewRow)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

proc appendAnswer(answerValue: int) =
  outputBuffer.add $answerValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var viewGrid: array[0 .. viewCount - 1, array[0 .. maxSide - 1, string]]
var cubeStates: array[0 .. cubeCapacity - 1, char]
var rayCellIndices: array[0 .. rayCapacity - 1, int]

for caseIndex in 0 ..< caseCount:
  let cubeSize = nextInt(inputData, scanPos)
  for viewRow in 0 ..< cubeSize:
    for viewIndex in 0 ..< viewCount:
      viewGrid[viewIndex][viewRow] = nextToken(inputData, scanPos)

  for cellX in 0 ..< cubeSize:
    for cellY in 0 ..< cubeSize:
      for cellZ in 0 ..< cubeSize:
        cubeStates[(cellX * cubeSize + cellY) * cubeSize + cellZ] = unknownMark

  for viewIndex in 0 ..< viewCount:
    for viewRow in 0 ..< cubeSize:
      for viewCol in 0 ..< cubeSize:
        let rayBase = (viewIndex * maxSideSquared + viewRow * cubeSize + viewCol) * cubeSize
        for viewDepth in 0 ..< cubeSize:
          let cellCoords = viewCell(viewIndex, viewRow, viewCol, viewDepth, cubeSize)
          let cellPosition = (cellCoords.x * cubeSize + cellCoords.y) * cubeSize + cellCoords.z
          rayCellIndices[rayBase + viewDepth] = cellPosition
          if viewGrid[viewIndex][viewRow][viewCol] == emptyMark:
            cubeStates[cellPosition] = emptyMark

  var changeDetected = true
  while changeDetected:
    changeDetected = false
    for viewIndex in 0 ..< viewCount:
      for viewRow in 0 ..< cubeSize:
        for viewCol in 0 ..< cubeSize:
          let expectedColor = viewGrid[viewIndex][viewRow][viewCol]
          if expectedColor == emptyMark:
            continue
          let rayBase = (viewIndex * maxSideSquared + viewRow * cubeSize + viewCol) * cubeSize
          for viewDepth in 0 ..< cubeSize:
            let cellPosition = rayCellIndices[rayBase + viewDepth]
            let currentState = cubeStates[cellPosition]
            if currentState == emptyMark:
              continue
            if currentState == unknownMark:
              cubeStates[cellPosition] = expectedColor
              changeDetected = true
              break
            if currentState == expectedColor:
              break
            cubeStates[cellPosition] = emptyMark
            changeDetected = true

  var remainingBlocks = 0
  for cellX in 0 ..< cubeSize:
    for cellY in 0 ..< cubeSize:
      for cellZ in 0 ..< cubeSize:
        let cellPosition = (cellX * cubeSize + cellY) * cubeSize + cellZ
        if cubeStates[cellPosition] != emptyMark:
          remainingBlocks += 1
  appendAnswer(remainingBlocks)

stdout.write outputBuffer
outputBuffer.setLen 0
