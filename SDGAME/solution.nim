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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let turnCount = nextInt(inputData, scanPos)
let diceCount = nextInt(inputData, scanPos)
let trackCells = int64(nextInt(inputData, scanPos))

proc powerMod(baseValue: int64, exponent: int, modulusValue: int64): int64 =
  var resultValue: int64 = 1 mod modulusValue
  var runningPower = baseValue mod modulusValue
  var remaining = exponent
  while remaining > 0:
    if (remaining and 1) == 1:
      resultValue = (resultValue * runningPower) mod modulusValue
    runningPower = (runningPower * runningPower) mod modulusValue
    remaining = remaining shr 1
  return resultValue

proc applyMultiplier(nodeIndex: int, factor: int64, segmentLength: int,
                     segmentTree: var seq[int64],
                     pendingFactor: var seq[int64], modulusValue: int64) =
  let productFactor = powerMod(factor, segmentLength, modulusValue)
  segmentTree[nodeIndex] = (segmentTree[nodeIndex] * productFactor) mod modulusValue
  pendingFactor[nodeIndex] = (pendingFactor[nodeIndex] * factor) mod modulusValue

proc pushPending(nodeIndex: int, leftBound: int, rightBound: int,
                 segmentTree: var seq[int64],
                 pendingFactor: var seq[int64], modulusValue: int64) =
  let factor = pendingFactor[nodeIndex]
  if factor != 1:
    let middle = (leftBound + rightBound) div 2
    applyMultiplier(nodeIndex * 2, factor, middle - leftBound + 1,
                    segmentTree, pendingFactor, modulusValue)
    applyMultiplier(nodeIndex * 2 + 1, factor, rightBound - middle,
                    segmentTree, pendingFactor, modulusValue)
    pendingFactor[nodeIndex] = 1

proc buildTree(nodeIndex: int, leftBound: int, rightBound: int,
               segmentTree: var seq[int64], modulusValue: int64) =
  if leftBound == rightBound:
    segmentTree[nodeIndex] = 1 mod modulusValue
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle, segmentTree, modulusValue)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound, segmentTree, modulusValue)
  segmentTree[nodeIndex] = (segmentTree[nodeIndex * 2] *
                            segmentTree[nodeIndex * 2 + 1]) mod modulusValue

proc setDie(nodeIndex: int, leftBound: int, rightBound: int, targetDie: int,
            newValue: int64, segmentTree: var seq[int64],
            pendingFactor: var seq[int64], modulusValue: int64) =
  if leftBound == rightBound:
    segmentTree[nodeIndex] = newValue mod modulusValue
    pendingFactor[nodeIndex] = 1
    return
  pushPending(nodeIndex, leftBound, rightBound, segmentTree, pendingFactor, modulusValue)
  let middle = (leftBound + rightBound) div 2
  if targetDie <= middle:
    setDie(nodeIndex * 2, leftBound, middle, targetDie, newValue,
           segmentTree, pendingFactor, modulusValue)
  else:
    setDie(nodeIndex * 2 + 1, middle + 1, rightBound, targetDie, newValue,
           segmentTree, pendingFactor, modulusValue)
  segmentTree[nodeIndex] = (segmentTree[nodeIndex * 2] *
                            segmentTree[nodeIndex * 2 + 1]) mod modulusValue

proc queryProduct(nodeIndex: int, leftBound: int, rightBound: int,
                  queryLeft: int, queryRight: int, segmentTree: var seq[int64],
                  pendingFactor: var seq[int64], modulusValue: int64): int64 =
  if queryLeft <= leftBound and rightBound <= queryRight:
    return segmentTree[nodeIndex]
  pushPending(nodeIndex, leftBound, rightBound, segmentTree, pendingFactor, modulusValue)
  let middle = (leftBound + rightBound) div 2
  var productValue: int64 = 1
  if queryLeft <= middle:
    productValue = (productValue * queryProduct(nodeIndex * 2, leftBound, middle,
                    queryLeft, queryRight, segmentTree, pendingFactor,
                    modulusValue)) mod modulusValue
  if queryRight > middle:
    productValue = (productValue * queryProduct(nodeIndex * 2 + 1, middle + 1,
                    rightBound, queryLeft, queryRight, segmentTree,
                    pendingFactor, modulusValue)) mod modulusValue
  return productValue

var segmentTree = newSeq[int64](diceCount * 4 + 4)
var pendingFactor = newSeq[int64](diceCount * 4 + 4)
for nodeIndex in 0 .. segmentTree.len - 1:
  pendingFactor[nodeIndex] = 1
buildTree(1, 0, diceCount - 1, segmentTree, trackCells)

var aliceCell: int64 = 0
var bobCell: int64 = 0
for turnIndex in 0 .. turnCount - 1:
  let rolledDie = nextInt(inputData, scanPos)
  let shownValue = int64(nextInt(inputData, scanPos))
  let rangeLeft = nextInt(inputData, scanPos)
  let rangeRight = nextInt(inputData, scanPos)
  setDie(1, 0, diceCount - 1, rolledDie, shownValue,
         segmentTree, pendingFactor, trackCells)
  let moveDistance = queryProduct(1, 0, diceCount - 1, rangeLeft, rangeRight,
                                  segmentTree, pendingFactor, trackCells)
  if (turnIndex and 1) == 0:
    aliceCell = (aliceCell + moveDistance) mod trackCells
    appendOutput($aliceCell)
  else:
    bobCell = (bobCell + moveDistance) mod trackCells
    appendOutput($bobCell)
  outputBuffer.add '\n'
  if aliceCell == bobCell:
    applyMultiplier(1, aliceCell, diceCount, segmentTree, pendingFactor, trackCells)

stdout.write outputBuffer
outputBuffer.setLen 0
