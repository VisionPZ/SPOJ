const flushBlockBytes = 1 shl 17
const maxMoveValue = 20
const dpLimit = 2000
const pairWidth = 21

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

var preperiodTable = newSeq[int]((maxMoveValue + 1) * pairWidth)
var periodTable = newSeq[int]((maxMoveValue + 1) * pairWidth)
var patternTable = newSeq[string]((maxMoveValue + 1) * pairWidth)
var seenState = newSeq[int](1 shl maxMoveValue)
for stateCode in 0 .. seenState.len - 1:
  seenState[stateCode] = -1

for firstMove in 1 .. maxMoveValue:
  for secondMove in 1 .. maxMoveValue:
    var moveList = newSeq[int]()
    moveList.add 1
    if firstMove != 1:
      moveList.add firstMove
    if secondMove != 1 and secondMove != firstMove:
      moveList.add secondMove
    var maxMove = 1
    if firstMove > maxMove:
      maxMove = firstMove
    if secondMove > maxMove:
      maxMove = secondMove
    var winArray = newSeq[bool](dpLimit + 1)
    winArray[0] = false
    for position in 1 .. dpLimit:
      winArray[position] = false
      for moveValue in moveList:
        if moveValue <= position and not winArray[position - moveValue]:
          winArray[position] = true
          break
    var preperiod = 0
    var period = dpLimit - maxMove
    var usedStates = newSeq[int]()
    for startPos in 0 .. dpLimit - maxMove:
      var stateCode = 0
      for offset in 0 .. maxMove - 1:
        if winArray[startPos + offset]:
          stateCode = stateCode or (1 shl offset)
      let previousPos = seenState[stateCode]
      if previousPos >= 0:
        preperiod = previousPos
        period = startPos - previousPos
        break
      seenState[stateCode] = startPos
      usedStates.add stateCode
    for stateCode in usedStates:
      seenState[stateCode] = -1
    var pattern = ""
    for position in 0 .. preperiod + period - 1:
      if winArray[position]:
        pattern.add '1'
      else:
        pattern.add '0'
    let tableIndex = firstMove * pairWidth + secondMove
    preperiodTable[tableIndex] = preperiod
    periodTable[tableIndex] = period
    patternTable[tableIndex] = pattern

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstMove = nextInt(inputData, scanPos)
  let secondMove = nextInt(inputData, scanPos)
  let pileSize = nextInt(inputData, scanPos)
  let tableIndex = firstMove * pairWidth + secondMove
  let preperiod = preperiodTable[tableIndex]
  let period = periodTable[tableIndex]
  var patternPos = pileSize
  if patternPos >= preperiod:
    patternPos = preperiod + (patternPos - preperiod) mod period
  if patternTable[tableIndex][patternPos] == '1':
    appendOutput("Alice\n")
  else:
    appendOutput("Bob\n")

stdout.write outputBuffer
outputBuffer.setLen 0
