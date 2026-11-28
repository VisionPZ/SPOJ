const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infiniteCost = 1000000000
const carriedRows = [0, 1, 1, 2, 2]
const stateCount = 5

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc addMove(extraList: var array[0 .. 6, int], stateList: var array[0 .. 6, int],
             startList: var array[0 .. 6, int], moveCount: var int,
             extraBarns: int, nextState: int, startRows: int) =
  extraList[moveCount] = extraBarns
  stateList[moveCount] = nextState
  startList[moveCount] = startRows
  moveCount += 1

proc movesFor(state: int, cowMask: int, extraList: var array[0 .. 6, int],
              stateList: var array[0 .. 6, int], startList: var array[0 .. 6, int]): int =
  var moveCount = 0
  if state == 0:
    if cowMask == 1:
      addMove(extraList, stateList, startList, moveCount, 1, 1, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 4, 2)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 1)
    elif cowMask == 2:
      addMove(extraList, stateList, startList, moveCount, 1, 2, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 4, 2)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 1)
    else:
      addMove(extraList, stateList, startList, moveCount, 1, 4, 2)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 2)
      addMove(extraList, stateList, startList, moveCount, 2, 3, 2)
      addMove(extraList, stateList, startList, moveCount, 2, 1, 2)
      addMove(extraList, stateList, startList, moveCount, 2, 2, 2)
      addMove(extraList, stateList, startList, moveCount, 2, 0, 2)
  elif state == 1:
    if (cowMask and 2) != 0:
      addMove(extraList, stateList, startList, moveCount, 1, 3, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 1, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 2, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 1)
    else:
      addMove(extraList, stateList, startList, moveCount, 0, 1, 0)
      addMove(extraList, stateList, startList, moveCount, 0, 0, 0)
  elif state == 2:
    if (cowMask and 1) != 0:
      addMove(extraList, stateList, startList, moveCount, 1, 3, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 2, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 1, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 1)
    else:
      addMove(extraList, stateList, startList, moveCount, 0, 2, 0)
      addMove(extraList, stateList, startList, moveCount, 0, 0, 0)
  elif state == 3:
    addMove(extraList, stateList, startList, moveCount, 0, 3, 0)
    addMove(extraList, stateList, startList, moveCount, 0, 1, 0)
    addMove(extraList, stateList, startList, moveCount, 0, 2, 0)
    addMove(extraList, stateList, startList, moveCount, 0, 0, 0)
  else:
    addMove(extraList, stateList, startList, moveCount, 0, 4, 0)
    addMove(extraList, stateList, startList, moveCount, 0, 0, 0)
  return moveCount

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

var extraOptions: array[0 .. 6, int]
var stateOptions: array[0 .. 6, int]
var startOptions: array[0 .. 6, int]

for caseIndex in 0 ..< caseCount:
  let cowCount = nextInt(inputData, scanPos)
  let barnTarget = nextInt(inputData, scanPos)
  discard nextInt(inputData, scanPos)

  var cowColumns = newSeq[int](cowCount)
  var cowRowBits = newSeq[int](cowCount)
  for cowIndex in 0 ..< cowCount:
    let cowRow = nextInt(inputData, scanPos)
    let cowColumn = nextInt(inputData, scanPos)
    cowColumns[cowIndex] = cowColumn
    if cowRow == 1:
      cowRowBits[cowIndex] = 1
    else:
      cowRowBits[cowIndex] = 2

  for sortIndex in 1 ..< cowCount:
    var cursor = sortIndex
    while cursor > 0 and cowColumns[cursor] < cowColumns[cursor - 1]:
      swap cowColumns[cursor], cowColumns[cursor - 1]
      swap cowRowBits[cursor], cowRowBits[cursor - 1]
      cursor -= 1

  var groupColumns = newSeq[int](cowCount)
  var groupMasks = newSeq[int](cowCount)
  var groupCount = 0
  for cowIndex in 0 ..< cowCount:
    if groupCount > 0 and cowColumns[cowIndex] == groupColumns[groupCount - 1]:
      groupMasks[groupCount - 1] = groupMasks[groupCount - 1] or cowRowBits[cowIndex]
    else:
      groupColumns[groupCount] = cowColumns[cowIndex]
      groupMasks[groupCount] = cowRowBits[cowIndex]
      groupCount += 1

  let stride = barnTarget + 1
  var currentCosts = newSeq[int](stateCount * stride)
  var nextCosts = newSeq[int](stateCount * stride)
  for costIndex in 0 ..< currentCosts.len:
    currentCosts[costIndex] = infiniteCost
  currentCosts[0] = 0
  var previousColumn = 0

  for groupIndex in 0 ..< groupCount:
    let currentColumn = groupColumns[groupIndex]
    let currentCowMask = groupMasks[groupIndex]
    let gapWidth = currentColumn - previousColumn
    for costIndex in 0 ..< nextCosts.len:
      nextCosts[costIndex] = infiniteCost

    for barnsUsed in 0 .. barnTarget:
      for state in 0 ..< stateCount:
        let oldCost = currentCosts[state * stride + barnsUsed]
        if oldCost >= infiniteCost:
          continue
        let baseCost = oldCost + carriedRows[state] * gapWidth
        let moveCount = movesFor(state, currentCowMask, extraOptions, stateOptions, startOptions)
        for moveIndex in 0 ..< moveCount:
          let newBarnCount = barnsUsed + extraOptions[moveIndex]
          if newBarnCount > barnTarget:
            continue
          let candidate = baseCost + startOptions[moveIndex]
          let targetIndex = stateOptions[moveIndex] * stride + newBarnCount
          if candidate < nextCosts[targetIndex]:
            nextCosts[targetIndex] = candidate

    swap currentCosts, nextCosts
    previousColumn = currentColumn

  var minimumArea = infiniteCost
  for finalState in 0 ..< stateCount:
    let candidate = currentCosts[finalState * stride + barnTarget]
    if candidate < minimumArea:
      minimumArea = candidate

  outputBuffer.add $minimumArea
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
