import algorithm

const flushBlockBytes = 1 shl 17
const blockedBeginning = true

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

proc compareDescending(leftValue: int64, rightValue: int64): int =
  if leftValue > rightValue:
    return -1
  if leftValue < rightValue:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let blockedCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0 and blockedCount == 0:
    break
  var isBlocked = newSeq[bool](rowCount)
  for blockIndex in 0 .. blockedCount - 1:
    let blockedRow = nextInt(inputData, scanPos) - 1
    if blockedRow >= 0 and blockedRow < rowCount:
      isBlocked[blockedRow] = blockedBeginning
  var boardValues = newSeq[int](rowCount * columnCount)
  var totalScore: int64 = 0
  for cellIndex in 0 .. boardValues.len - 1:
    boardValues[cellIndex] = nextInt(inputData, scanPos)
    totalScore = totalScore + int64(boardValues[cellIndex])
  let totalCells = rowCount * columnCount
  let globalSign = if totalCells mod 2 == 0: int64(1) else: int64(-1)
  var advantage: int64 = 0
  var remainingValues = newSeq[int64](0)
  for rowIndex in 0 .. rowCount - 1:
    var fusedStack = newSeq[int64](0)
    if isBlocked[rowIndex]:
      var columnIndex = columnCount - 1
      while columnIndex >= 0:
        let cellValue = int64(boardValues[rowIndex * columnCount + columnIndex])
        fusedStack.add cellValue
        while fusedStack.len >= 3 and fusedStack[fusedStack.len - 3] <= fusedStack[fusedStack.len - 2] and fusedStack[fusedStack.len - 2] >= fusedStack[fusedStack.len - 1]:
          let leftValue = fusedStack[fusedStack.len - 3]
          let middleValue = fusedStack[fusedStack.len - 2]
          let rightValue = fusedStack[fusedStack.len - 1]
          fusedStack[fusedStack.len - 3] = leftValue - middleValue + rightValue
          fusedStack.setLen(fusedStack.len - 2)
        columnIndex -= 1
      while fusedStack.len >= 2 and fusedStack[fusedStack.len - 2] <= fusedStack[fusedStack.len - 1]:
        let leftValue = fusedStack[fusedStack.len - 2]
        let rightValue = fusedStack[fusedStack.len - 1]
        advantage = advantage + globalSign * (leftValue - rightValue)
        fusedStack.setLen(fusedStack.len - 2)
    else:
      for columnIndex in 0 .. columnCount - 1:
        let cellValue = int64(boardValues[rowIndex * columnCount + columnIndex])
        fusedStack.add cellValue
        while fusedStack.len >= 3 and fusedStack[fusedStack.len - 3] <= fusedStack[fusedStack.len - 2] and fusedStack[fusedStack.len - 2] >= fusedStack[fusedStack.len - 1]:
          let leftValue = fusedStack[fusedStack.len - 3]
          let middleValue = fusedStack[fusedStack.len - 2]
          let rightValue = fusedStack[fusedStack.len - 1]
          fusedStack[fusedStack.len - 3] = leftValue - middleValue + rightValue
          fusedStack.setLen(fusedStack.len - 2)
    for fusedValue in fusedStack:
      remainingValues.add fusedValue
  remainingValues.sort(compareDescending)
  var currentSign: int64 = 1
  for remainingValue in remainingValues:
    advantage = advantage + currentSign * remainingValue
    currentSign = -currentSign
  let advantageSize = if advantage < 0: -advantage else: advantage
  let winnerScore = (totalScore + advantageSize) div 2
  if advantage > 0:
    appendOutput("first ")
  else:
    appendOutput("second ")
  appendOutput($winnerScore)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
