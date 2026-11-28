const flushBlockBytes = 1 shl 17
const boardSize = 8
const squareCount = 64
const figureCount = 5
const unreachableCost = 1000000000
const knightRowSteps = [-2, -2, -1, -1, 1, 1, 2, 2]
const knightColSteps = [-1, 1, -2, 2, -2, 2, -1, 1]
const slideRowSteps = [1, -1, 0, 0, 1, 1, -1, -1]
const slideColSteps = [0, 0, 1, -1, 1, -1, 1, -1]

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

proc addNeighbor(neighbors: var seq[int], targetRow: int, targetCol: int) =
  if targetRow >= 0 and targetRow < boardSize and targetCol >= 0 and targetCol < boardSize:
    neighbors.add targetRow * boardSize + targetCol

var adjacencyByFigure: array[figureCount, seq[seq[int]]]
for figureIndex in 0 .. figureCount - 1:
  adjacencyByFigure[figureIndex] = newSeq[seq[int]](squareCount)
  for sourceSquare in 0 .. squareCount - 1:
    var neighbors = newSeq[int](0)
    let sourceRow = sourceSquare div boardSize
    let sourceCol = sourceSquare mod boardSize
    if figureIndex == 0:
      for rowStep in -1 .. 1:
        for colStep in -1 .. 1:
          if rowStep != 0 or colStep != 0:
            addNeighbor(neighbors, sourceRow + rowStep, sourceCol + colStep)
    elif figureIndex == 1:
      for offsetIndex in 0 .. 7:
        addNeighbor(neighbors, sourceRow + knightRowSteps[offsetIndex], sourceCol + knightColSteps[offsetIndex])
    else:
      let firstDirection = if figureIndex == 3: 0 elif figureIndex == 4: 4 else: 0
      let lastDirection = if figureIndex == 3: 3 else: 7
      for directionIndex in firstDirection .. lastDirection:
        var stepLength = 1
        while true:
          let targetRow = sourceRow + stepLength * slideRowSteps[directionIndex]
          let targetCol = sourceCol + stepLength * slideColSteps[directionIndex]
          if targetRow < 0 or targetRow >= boardSize or targetCol < 0 or targetCol >= boardSize:
            break
          neighbors.add targetRow * boardSize + targetCol
          stepLength += 1
    adjacencyByFigure[figureIndex][sourceSquare] = neighbors

var distanceTable: array[figureCount, array[squareCount, array[squareCount, int]]]
for figureIndex in 0 .. figureCount - 1:
  for sourceSquare in 0 .. squareCount - 1:
    var distances = newSeq[int](squareCount)
    for targetSquare in 0 .. squareCount - 1:
      distances[targetSquare] = unreachableCost
    var queue = newSeq[int](squareCount)
    var queueHead = 0
    var queueTail = 0
    distances[sourceSquare] = 0
    queue[queueTail] = sourceSquare
    queueTail += 1
    while queueHead < queueTail:
      let currentSquare = queue[queueHead]
      queueHead += 1
      for neighborSquare in adjacencyByFigure[figureIndex][currentSquare]:
        if distances[neighborSquare] == unreachableCost:
          distances[neighborSquare] = distances[currentSquare] + 1
          queue[queueTail] = neighborSquare
          queueTail += 1
    for targetSquare in 0 .. squareCount - 1:
      distanceTable[figureIndex][sourceSquare][targetSquare] = distances[targetSquare]

var answerTable: array[figureCount, array[squareCount, array[figureCount, array[squareCount, int]]]]
for firstFigure in 0 .. figureCount - 1:
  for firstSquare in 0 .. squareCount - 1:
    for secondFigure in 0 .. figureCount - 1:
      for secondSquare in 0 .. squareCount - 1:
        var bestMoves = unreachableCost
        for meetingSquare in 0 .. squareCount - 1:
          let totalMoves = distanceTable[firstFigure][firstSquare][meetingSquare] + distanceTable[secondFigure][secondSquare][meetingSquare]
          if totalMoves < bestMoves:
            bestMoves = totalMoves
        answerTable[firstFigure][firstSquare][secondFigure][secondSquare] = bestMoves

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let firstFigure = nextInt(inputData, scanPos)
  let firstRow = nextInt(inputData, scanPos)
  let firstCol = nextInt(inputData, scanPos)
  let secondFigure = nextInt(inputData, scanPos)
  let secondRow = nextInt(inputData, scanPos)
  let secondCol = nextInt(inputData, scanPos)
  let bestMoves = answerTable[firstFigure][firstRow * boardSize + firstCol][secondFigure][secondRow * boardSize + secondCol]
  if bestMoves >= unreachableCost:
    appendOutput("INF")
  else:
    appendOutput($bestMoves)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
