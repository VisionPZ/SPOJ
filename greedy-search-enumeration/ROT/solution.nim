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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let columnCount = nextInt(inputData, scanPos)
  let rowCount = nextInt(inputData, scanPos)
  let timeCount = nextInt(inputData, scanPos)
  let layerSize = rowCount * columnCount
  let stateCount = timeCount * layerSize
  var cellChars = newSeq[char](stateCount)
  var startState = -1
  var targetRow = -1
  var targetColumn = -1
  for timeIndex in 0 .. timeCount - 1:
    for rowIndex in 0 .. rowCount - 1:
      let rowToken = nextToken(inputData, scanPos)
      for columnIndex in 0 .. columnCount - 1:
        var cellChar = 's'
        if columnIndex < rowToken.len:
          cellChar = rowToken[columnIndex]
        let stateIndex = timeIndex * layerSize + rowIndex * columnCount + columnIndex
        cellChars[stateIndex] = cellChar
        if cellChar == 'X' and startState < 0:
          startState = stateIndex
        if cellChar == 'O' and targetRow < 0:
          targetRow = rowIndex
          targetColumn = columnIndex
  var distanceByState = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    distanceByState[stateIndex] = -1
  var queueStates = newSeq[int](stateCount)
  var queueHead = 0
  var queueTail = 0
  if startState >= 0:
    distanceByState[startState] = 0
    queueStates[queueTail] = startState
    queueTail += 1
  var answer = -1
  while queueHead < queueTail and answer < 0:
    let currentState = queueStates[queueHead]
    queueHead += 1
    let currentDistance = distanceByState[currentState]
    let currentLayer = currentState div layerSize
    let withinLayer = currentState mod layerSize
    let currentRow = withinLayer div columnCount
    let currentColumn = withinLayer mod columnCount
    if currentRow == targetRow and currentColumn == targetColumn:
      answer = currentDistance
      break
    for directionIndex in 0 .. 3:
      var neighborRow = currentRow
      var neighborColumn = currentColumn
      case directionIndex
      of 0: neighborRow += 1
      of 1: neighborRow -= 1
      of 2: neighborColumn += 1
      else: neighborColumn -= 1
      if neighborRow < 0 or neighborRow >= rowCount:
        continue
      if neighborColumn < 0 or neighborColumn >= columnCount:
        continue
      var timeShift = -1
      while timeShift <= 1:
        let neighborLayer = currentLayer + timeShift
        if neighborLayer >= 0 and neighborLayer < timeCount:
          let neighborState = neighborLayer * layerSize + neighborRow * columnCount + neighborColumn
          let neighborChar = cellChars[neighborState]
          if neighborChar != '#' and neighborChar != '!' and distanceByState[neighborState] < 0:
            distanceByState[neighborState] = currentDistance + 1
            queueStates[queueTail] = neighborState
            queueTail += 1
        timeShift += 1
  if answer >= 0:
    appendOutput($answer)
  else:
    appendOutput("Hostage is death, destroy the bunker")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
