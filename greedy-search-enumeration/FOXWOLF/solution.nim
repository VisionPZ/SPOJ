const flushBlockBytes = 1 shl 17
const invalidDistance = -1

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

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let chatDuration = nextInt(inputData, scanPos)
let burrDuration = nextInt(inputData, scanPos)
let cellCount = rowCount * columnCount
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var grid = newSeq[char](cellCount)
var foxStart = -1
var wolfStart = -1
var foxHome = -1
var wolfHome = -1
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cell = rowIndex * columnCount + columnIndex
    let cellChar = inputData[scanPos]
    scanPos += 1
    grid[cell] = cellChar
    if cellChar == 'f': foxStart = cell
    elif cellChar == 'w': wolfStart = cell
    elif cellChar == 'F': foxHome = cell
    elif cellChar == 'W': wolfHome = cell
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1

if foxStart == -1 or wolfStart == -1 or foxHome == -1 or wolfHome == -1:
  appendOutput("-1\n")
else:
  var isBurr = newSeq[bool](cellCount)
  var isMeadow = newSeq[bool](cellCount)
  for cell in 0 .. cellCount - 1:
    isBurr[cell] = grid[cell] == 'B'
    isMeadow[cell] = grid[cell] == '.'

  var foxMoveStart = newSeq[int](cellCount)
  var wolfMoveStart = newSeq[int](cellCount)
  var foxMoveCount = newSeq[int](cellCount)
  var wolfMoveCount = newSeq[int](cellCount)
  var foxMoves = newSeq[int](cellCount * 5)
  var wolfMoves = newSeq[int](cellCount * 5)
  var foxMoveTotal = 0
  var wolfMoveTotal = 0
  for cell in 0 .. cellCount - 1:
    foxMoveStart[cell] = foxMoveTotal
    wolfMoveStart[cell] = wolfMoveTotal
    foxMoves[foxMoveTotal] = cell
    wolfMoves[wolfMoveTotal] = cell
    foxMoveTotal += 1
    wolfMoveTotal += 1
    foxMoveCount[cell] = 1
    wolfMoveCount[cell] = 1
    let rowIndex = cell div columnCount
    let columnIndex = cell mod columnCount
    for deltaRow in -1 .. 1:
      for deltaColumn in -1 .. 1:
        if (deltaRow == 0 and deltaColumn == 0) or (deltaRow != 0 and deltaColumn != 0):
          continue
        let nextRow = rowIndex + deltaRow
        let nextColumn = columnIndex + deltaColumn
        if nextRow < 0 or nextRow >= rowCount or nextColumn < 0 or nextColumn >= columnCount:
          continue
        let neighbor = nextRow * columnCount + nextColumn
        let neighborChar = grid[neighbor]
        if neighborChar == 'T':
          continue
        if neighborChar != 'W':
          foxMoves[foxMoveTotal] = neighbor
          foxMoveTotal += 1
          foxMoveCount[cell] += 1
        if neighborChar != 'F':
          wolfMoves[wolfMoveTotal] = neighbor
          wolfMoveTotal += 1
          wolfMoveCount[cell] += 1

  let timerBase = max(burrDuration, chatDuration) + 1
  let stateCount = cellCount * cellCount * timerBase * timerBase * 2
  var distance = newSeq[int32](stateCount)
  for index in 0 .. stateCount - 1:
    distance[index] = invalidDistance
  var queue = newSeq[int32](stateCount)
  var queueHead = 0
  var queueTail = 0

  proc encodeState(foxCell: int, wolfCell: int, foxBusy: int, wolfBusy: int, chatted: int): int =
    return (((foxCell * cellCount + wolfCell) * timerBase + foxBusy) * timerBase + wolfBusy) * 2 + chatted

  proc burrPenalty(fromCell: int, toCell: int): int =
    if isBurr[fromCell] and isMeadow[toCell]:
      return burrDuration
    return 0

  let startState = encodeState(foxStart, wolfStart, 0, 0, 0)
  distance[startState] = 0
  queue[queueTail] = int32(startState)
  queueTail += 1
  var answer = -1

  while queueHead < queueTail:
    let state = int(queue[queueHead])
    queueHead += 1
    let chatted = state mod 2
    let afterChat = state div 2
    let wolfBusy = afterChat mod timerBase
    let afterWolf = afterChat div timerBase
    let foxBusy = afterWolf mod timerBase
    let afterFox = afterWolf div timerBase
    let wolfCell = afterFox mod cellCount
    let foxCell = afterFox div cellCount
    let reached = distance[state]
    if foxCell == foxHome and wolfCell == wolfHome:
      answer = int(reached)
      break

    if foxBusy > 0 and wolfBusy > 0:
      let nextState = encodeState(foxCell, wolfCell, foxBusy - 1, wolfBusy - 1, chatted)
      if distance[nextState] == invalidDistance:
        distance[nextState] = reached + 1
        queue[queueTail] = int32(nextState)
        queueTail += 1
    elif foxBusy > 0:
      let wolfBegin = wolfMoveStart[wolfCell]
      let wolfEnd = wolfBegin + wolfMoveCount[wolfCell] - 1
      for wolfIndex in wolfBegin .. wolfEnd:
        let nextWolf = wolfMoves[wolfIndex]
        let penalty = burrPenalty(wolfCell, nextWolf)
        let meeting = foxCell == nextWolf
        var nextFoxBusy = foxBusy - 1
        var nextWolfBusy = penalty
        var nextChatted = chatted
        if meeting and chatted == 0:
          nextFoxBusy = max(nextFoxBusy, chatDuration)
          nextWolfBusy = max(penalty, chatDuration)
          nextChatted = 1
        let nextState = encodeState(foxCell, nextWolf, nextFoxBusy, nextWolfBusy, nextChatted)
        if distance[nextState] == invalidDistance:
          distance[nextState] = reached + 1
          queue[queueTail] = int32(nextState)
          queueTail += 1
    elif wolfBusy > 0:
      let foxBegin = foxMoveStart[foxCell]
      let foxEnd = foxBegin + foxMoveCount[foxCell] - 1
      for foxIndex in foxBegin .. foxEnd:
        let nextFox = foxMoves[foxIndex]
        let penalty = burrPenalty(foxCell, nextFox)
        let meeting = nextFox == wolfCell
        var nextFoxBusy = penalty
        var nextWolfBusy = wolfBusy - 1
        var nextChatted = chatted
        if meeting and chatted == 0:
          nextFoxBusy = max(penalty, chatDuration)
          nextWolfBusy = max(nextWolfBusy, chatDuration)
          nextChatted = 1
        let nextState = encodeState(nextFox, wolfCell, nextFoxBusy, nextWolfBusy, nextChatted)
        if distance[nextState] == invalidDistance:
          distance[nextState] = reached + 1
          queue[queueTail] = int32(nextState)
          queueTail += 1
    else:
      let foxBegin = foxMoveStart[foxCell]
      let foxEnd = foxBegin + foxMoveCount[foxCell] - 1
      let wolfBegin = wolfMoveStart[wolfCell]
      let wolfEnd = wolfBegin + wolfMoveCount[wolfCell] - 1
      for foxIndex in foxBegin .. foxEnd:
        let nextFox = foxMoves[foxIndex]
        let foxPenalty = burrPenalty(foxCell, nextFox)
        for wolfIndex in wolfBegin .. wolfEnd:
          let nextWolf = wolfMoves[wolfIndex]
          let wolfPenalty = burrPenalty(wolfCell, nextWolf)
          let meeting = (nextFox == nextWolf) or (nextFox == wolfCell and nextWolf == foxCell)
          var nextFoxBusy = foxPenalty
          var nextWolfBusy = wolfPenalty
          var nextChatted = chatted
          if meeting and chatted == 0:
            let delay = max(foxPenalty, max(wolfPenalty, chatDuration))
            nextFoxBusy = delay
            nextWolfBusy = delay
            nextChatted = 1
          let nextState = encodeState(nextFox, nextWolf, nextFoxBusy, nextWolfBusy, nextChatted)
          if distance[nextState] == invalidDistance:
            distance[nextState] = reached + 1
            queue[queueTail] = int32(nextState)
            queueTail += 1

  appendOutput($answer & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
