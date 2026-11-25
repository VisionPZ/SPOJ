const flushBlockBytes = 1 shl 17
const cellCount = 27
const tableBits = 24
const tableSize = 1 shl tableBits
const tableMask = tableSize - 1
const shiftPerMask = 27

proc cellIndex(firstCoord, secondCoord, thirdCoord: int): int =
  return firstCoord * 9 + secondCoord * 3 + thirdCoord

var winningLines = newSeq[int64]()
var linesThroughCell = newSeq[seq[int64]](cellCount)

for firstCoord in 0 .. 2:
  for secondCoord in 0 .. 2:
    var lineMask = 0'i64
    for thirdCoord in 0 .. 2:
      lineMask = lineMask or (1'i64 shl cellIndex(firstCoord, secondCoord, thirdCoord))
    winningLines.add lineMask
    lineMask = 0'i64
    for thirdCoord in 0 .. 2:
      lineMask = lineMask or (1'i64 shl cellIndex(firstCoord, thirdCoord, secondCoord))
    winningLines.add lineMask
    lineMask = 0'i64
    for thirdCoord in 0 .. 2:
      lineMask = lineMask or (1'i64 shl cellIndex(thirdCoord, firstCoord, secondCoord))
    winningLines.add lineMask
for fixedCoord in 0 .. 2:
  var lineMask = 0'i64
  lineMask = lineMask or (1'i64 shl cellIndex(fixedCoord, 0, 0))
  lineMask = lineMask or (1'i64 shl cellIndex(fixedCoord, 1, 1))
  lineMask = lineMask or (1'i64 shl cellIndex(fixedCoord, 2, 2))
  winningLines.add lineMask
  lineMask = 0'i64
  lineMask = lineMask or (1'i64 shl cellIndex(fixedCoord, 0, 2))
  lineMask = lineMask or (1'i64 shl cellIndex(fixedCoord, 1, 1))
  lineMask = lineMask or (1'i64 shl cellIndex(fixedCoord, 2, 0))
  winningLines.add lineMask
  lineMask = 0'i64
  lineMask = lineMask or (1'i64 shl cellIndex(0, fixedCoord, 0))
  lineMask = lineMask or (1'i64 shl cellIndex(1, fixedCoord, 1))
  lineMask = lineMask or (1'i64 shl cellIndex(2, fixedCoord, 2))
  winningLines.add lineMask
  lineMask = 0'i64
  lineMask = lineMask or (1'i64 shl cellIndex(0, fixedCoord, 2))
  lineMask = lineMask or (1'i64 shl cellIndex(1, fixedCoord, 1))
  lineMask = lineMask or (1'i64 shl cellIndex(2, fixedCoord, 0))
  winningLines.add lineMask
  lineMask = 0'i64
  lineMask = lineMask or (1'i64 shl cellIndex(0, 0, fixedCoord))
  lineMask = lineMask or (1'i64 shl cellIndex(1, 1, fixedCoord))
  lineMask = lineMask or (1'i64 shl cellIndex(2, 2, fixedCoord))
  winningLines.add lineMask
  lineMask = 0'i64
  lineMask = lineMask or (1'i64 shl cellIndex(0, 2, fixedCoord))
  lineMask = lineMask or (1'i64 shl cellIndex(1, 1, fixedCoord))
  lineMask = lineMask or (1'i64 shl cellIndex(2, 0, fixedCoord))
  winningLines.add lineMask
for firstDiagonal in [0, 2]:
  for secondDiagonal in [0, 2]:
    var lineMask = 0'i64
    lineMask = lineMask or (1'i64 shl cellIndex(0, firstDiagonal, secondDiagonal))
    lineMask = lineMask or (1'i64 shl cellIndex(1, 1, 1))
    lineMask = lineMask or (1'i64 shl cellIndex(2, 2 - firstDiagonal, 2 - secondDiagonal))
    winningLines.add lineMask
for cellNumber in 0 .. cellCount - 1:
  linesThroughCell[cellNumber] = newSeq[int64]()
for lineMask in winningLines:
  for cellNumber in 0 .. cellCount - 1:
    if (lineMask and (1'i64 shl cellNumber)) != 0:
      linesThroughCell[cellNumber].add lineMask

var moveOrder = newSeq[int]()
for cellNumber in 0 .. cellCount - 1:
  moveOrder.add cellNumber
var orderIndex = 1
while orderIndex < moveOrder.len:
  let heldCell = moveOrder[orderIndex]
  let heldPriority = linesThroughCell[heldCell].len
  var compareIndex = orderIndex - 1
  while compareIndex >= 0 and linesThroughCell[moveOrder[compareIndex]].len < heldPriority:
    moveOrder[compareIndex + 1] = moveOrder[compareIndex]
    compareIndex -= 1
  moveOrder[compareIndex + 1] = heldCell
  orderIndex += 1

var transpositionKeys = newSeq[int64](tableSize)
var transpositionValues = newSeq[int8](tableSize)
var transpositionFlags = newSeq[int8](tableSize)

proc searchPosition(crossMask: int64, circleMask: int64, crossToMove: bool, alphaInput, betaInput: int): int =
  let stateKey = crossMask or (circleMask shl shiftPerMask)
  let slotIndex = int(stateKey and int64(tableMask))
  let storedKey = transpositionKeys[slotIndex]
  if storedKey != 0:
    if storedKey == stateKey + 1:
      let storedValue = int(transpositionValues[slotIndex]) - 1
      let storedFlag = transpositionFlags[slotIndex]
      if storedFlag == 0:
        return storedValue
      if storedFlag == 1 and storedValue >= betaInput:
        return storedValue
      if storedFlag == 2 and storedValue <= alphaInput:
        return storedValue
  var alphaValue = alphaInput
  var betaValue = betaInput
  var bestScore = -2
  let occupiedMask = crossMask or circleMask
  let moverMask = if crossToMove: crossMask else: circleMask
  let rivalMask = if crossToMove: circleMask else: crossMask
  var winningCells = 0'i64
  var blockingCells = 0'i64
  for lineMask in winningLines:
    let ownMissing = lineMask and not moverMask
    if ownMissing != 0 and (ownMissing and (ownMissing - 1)) == 0 and (lineMask and not occupiedMask) != 0:
      winningCells = winningCells or (lineMask and not occupiedMask)
    let rivalMissing = lineMask and not rivalMask
    if rivalMissing != 0 and (rivalMissing and (rivalMissing - 1)) == 0 and (lineMask and not occupiedMask) != 0:
      blockingCells = blockingCells or (lineMask and not occupiedMask)
  if winningCells != 0:
    bestScore = 1
  elif blockingCells != 0 and (blockingCells and (blockingCells - 1)) != 0:
    bestScore = -1
  else:
    for cellNumber in moveOrder:
      let cellBit = 1'i64 shl cellNumber
      if (occupiedMask and cellBit) != 0 or (blockingCells and cellBit) == 0:
        continue
      let nextCrossMask = crossMask or (if crossToMove: cellBit else: 0'i64)
      let nextCircleMask = circleMask or (if crossToMove: 0'i64 else: cellBit)
      let moveScore = -searchPosition(nextCrossMask, nextCircleMask, not crossToMove, -betaValue, -alphaValue)
      if moveScore > bestScore:
        bestScore = moveScore
      if bestScore > alphaValue:
        alphaValue = bestScore
      if alphaValue >= betaValue:
        break
    if blockingCells == 0:
      for cellNumber in moveOrder:
        let cellBit = 1'i64 shl cellNumber
        if (occupiedMask and cellBit) != 0:
          continue
        let nextCrossMask = crossMask or (if crossToMove: cellBit else: 0'i64)
        let nextCircleMask = circleMask or (if crossToMove: 0'i64 else: cellBit)
        let moverAfterMove = if crossToMove: nextCrossMask else: nextCircleMask
        var createsLine = false
        for lineMask in linesThroughCell[cellNumber]:
          if (moverAfterMove and lineMask) == lineMask:
            createsLine = true
            break
        let moveScore = if createsLine: 1 else: -searchPosition(nextCrossMask, nextCircleMask, not crossToMove, -betaValue, -alphaValue)
        if moveScore > bestScore:
          bestScore = moveScore
        if bestScore > alphaValue:
          alphaValue = bestScore
        if alphaValue >= betaValue:
          break
  if bestScore == -2:
    bestScore = 0
  var storedFlag = 0'i8
  if bestScore <= alphaInput:
    storedFlag = 2
  elif bestScore >= betaInput:
    storedFlag = 1
  transpositionKeys[slotIndex] = stateKey + 1
  transpositionValues[slotIndex] = int8(bestScore + 1)
  transpositionFlags[slotIndex] = storedFlag
  return bestScore

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

proc nextBoardChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'x' and data[pos] != 'o' and data[pos] != '.':
    pos += 1
  result = data[pos]
  pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  var crossMask = 0'i64
  var circleMask = 0'i64
  var crossCount = 0
  var circleCount = 0
  for cellNumber in 0 .. cellCount - 1:
    let boardChar = nextBoardChar(inputData, scanPos)
    if boardChar == 'x':
      crossMask = crossMask or (1'i64 shl cellNumber)
      crossCount += 1
    elif boardChar == 'o':
      circleMask = circleMask or (1'i64 shl cellNumber)
      circleCount += 1
  let crossToMove = crossCount == circleCount
  var adaWins = false
  if crossMask == 0 and circleMask == 0:
    adaWins = true
  else:
    let outcome = searchPosition(crossMask, circleMask, crossToMove, -2, 2)
    if outcome == 0:
      adaWins = true
    elif outcome == 1:
      adaWins = crossToMove
    else:
      adaWins = not crossToMove
  if adaWins:
    appendOutput("Ada\n")
  else:
    appendOutput("Vinit\n")
stdout.write outputBuffer
outputBuffer.setLen 0
