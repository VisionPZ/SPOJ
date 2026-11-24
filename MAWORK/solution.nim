const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const cycleLength = 5040
const maxGridSize = 25
const maxCellCount = maxGridSize * maxGridSize
const maxStateCount = maxCellCount * cycleLength
const stayDirection = 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  let tokenStart = position
  while position < data.len and data[position] > ' ':
    position += 1
  return data[tokenStart .. position - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var initialOpen = newSeq[bool](maxCellCount)
var periodLength = newSeq[int](maxCellCount)
var seenGeneration = newSeq[int](maxStateCount)
var stateQueue = newSeq[int](maxStateCount)
var generation = 0

proc isCellOpen(cellIndex: int, arrivalTime: int): bool =
  let duration = periodLength[cellIndex]
  if duration == 0:
    return initialOpen[cellIndex]
  let phaseIndex = (arrivalTime mod cycleLength) div duration
  if phaseIndex mod 2 == 1:
    return not initialOpen[cellIndex]
  return initialOpen[cellIndex]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let gridSize = nextInt(inputData, scanPos)
  let cellCount = gridSize * gridSize
  for rowIndex in 0..<gridSize:
    let gridLine = nextToken(inputData, scanPos)
    for columnIndex in 0..<gridSize:
      let cellIndex = rowIndex * gridSize + columnIndex
      initialOpen[cellIndex] = gridLine[columnIndex] == '.'
  for rowIndex in 0..<gridSize:
    let scheduleLine = nextToken(inputData, scanPos)
    for columnIndex in 0..<gridSize:
      let cellIndex = rowIndex * gridSize + columnIndex
      periodLength[cellIndex] = int(scheduleLine[columnIndex]) - firstDigitValue
  generation += 1
  let targetCell = cellCount - 1
  var answer = -1
  if isCellOpen(0, 0):
    var head = 0
    var tail = 0
    stateQueue[tail] = 0
    tail += 1
    seenGeneration[0] = generation
    var currentTime = 0
    while head < tail and answer < 0:
      let levelEnd = tail
      while head < levelEnd and answer < 0:
        let currentState = stateQueue[head]
        head += 1
        let cellIndex = currentState div cycleLength
        let rowIndex = cellIndex div gridSize
        let columnIndex = cellIndex mod gridSize
        let arrivalTime = currentTime + 1
        for direction in 0..stayDirection:
          var nextRow = rowIndex
          var nextColumn = columnIndex
          if direction == 0:
            nextRow -= 1
          elif direction == 1:
            nextRow += 1
          elif direction == 2:
            nextColumn -= 1
          elif direction == 3:
            nextColumn += 1
          if nextRow < 0 or nextRow >= gridSize or nextColumn < 0 or nextColumn >= gridSize:
            continue
          let nextCell = nextRow * gridSize + nextColumn
          if not isCellOpen(nextCell, arrivalTime):
            continue
          if nextCell == targetCell:
            answer = arrivalTime
            break
          let nextState = nextCell * cycleLength + (arrivalTime mod cycleLength)
          if seenGeneration[nextState] != generation:
            seenGeneration[nextState] = generation
            stateQueue[tail] = nextState
            tail += 1
      currentTime += 1
  if answer < 0:
    appendOutput("NO")
  else:
    appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
