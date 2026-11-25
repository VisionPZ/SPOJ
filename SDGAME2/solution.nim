const flushBlockBytes = 1 shl 17
const unavailableValue = 1000000001

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

let rollCount = nextInt(inputData, scanPos)
let diceCount = nextInt(inputData, scanPos)
let cellCount = nextInt(inputData, scanPos)

var segmentProduct = newSeq[int64](4 * diceCount)
var segmentAvailable = newSeq[int](4 * diceCount)
var zeroTag = newSeq[int](4 * diceCount)
for tagIndex in 0 .. zeroTag.len - 1:
  zeroTag[tagIndex] = -1
  segmentProduct[tagIndex] = 1
  segmentAvailable[tagIndex] = 1

proc applyZero(nodeIndex: int, firstCell, lastCell: int) =
  segmentProduct[nodeIndex] = 0
  segmentAvailable[nodeIndex] = lastCell - firstCell + 1
  zeroTag[nodeIndex] = 0

proc pushTag(nodeIndex: int, firstCell, lastCell: int) =
  if zeroTag[nodeIndex] == 0 and firstCell < lastCell:
    let middleCell = (firstCell + lastCell) div 2
    applyZero(nodeIndex * 2, firstCell, middleCell)
    applyZero(nodeIndex * 2 + 1, middleCell + 1, lastCell)
    zeroTag[nodeIndex] = -1

proc assignDie(nodeIndex, firstCell, lastCell, dieIndex, assignedProduct: int, available: bool) =
  if firstCell == lastCell:
    segmentProduct[nodeIndex] = int64(assignedProduct)
    segmentAvailable[nodeIndex] = 0
    if available:
      segmentAvailable[nodeIndex] = 1
    zeroTag[nodeIndex] = -1
    return
  pushTag(nodeIndex, firstCell, lastCell)
  let middleCell = (firstCell + lastCell) div 2
  if dieIndex <= middleCell:
    assignDie(nodeIndex * 2, firstCell, middleCell, dieIndex, assignedProduct, available)
  else:
    assignDie(nodeIndex * 2 + 1, middleCell + 1, lastCell, dieIndex, assignedProduct, available)
  segmentProduct[nodeIndex] = (segmentProduct[nodeIndex * 2] * segmentProduct[nodeIndex * 2 + 1]) mod int64(cellCount)
  segmentAvailable[nodeIndex] = segmentAvailable[nodeIndex * 2] + segmentAvailable[nodeIndex * 2 + 1]

var queryProduct: int64 = 1
var queryAvailable = 0

proc queryRange(nodeIndex, firstCell, lastCell, queryFirst, queryLast: int) =
  if queryFirst <= firstCell and lastCell <= queryLast:
    queryProduct = (queryProduct * segmentProduct[nodeIndex]) mod int64(cellCount)
    queryAvailable += segmentAvailable[nodeIndex]
    return
  pushTag(nodeIndex, firstCell, lastCell)
  let middleCell = (firstCell + lastCell) div 2
  if queryFirst <= middleCell:
    queryRange(nodeIndex * 2, firstCell, middleCell, queryFirst, queryLast)
  if queryLast > middleCell:
    queryRange(nodeIndex * 2 + 1, middleCell + 1, lastCell, queryFirst, queryLast)

var dieValues = newSeq[int64](diceCount)
var activeSlots = newSeq[int](diceCount)
var activeEpochs = newSeq[int](diceCount)
var activeDice = newSeq[int](diceCount)
var activeCount = 0
var zeroEpoch = 0
for dieIndex in 0 .. diceCount - 1:
  dieValues[dieIndex] = 1
  activeSlots[dieIndex] = -1
  activeEpochs[dieIndex] = -1
  activeDice[dieIndex] = dieIndex

proc removeActive(dieIndex: int) =
  let slotIndex = activeSlots[dieIndex]
  if slotIndex < 0 or activeEpochs[dieIndex] != zeroEpoch:
    return
  let lastSlot = activeCount - 1
  let swappedDie = activeDice[lastSlot]
  activeDice[slotIndex] = swappedDie
  activeSlots[swappedDie] = slotIndex
  activeCount = lastSlot
  activeSlots[dieIndex] = -1

proc addActive(dieIndex: int) =
  if activeSlots[dieIndex] >= 0 and activeEpochs[dieIndex] == zeroEpoch:
    return
  activeEpochs[dieIndex] = zeroEpoch
  activeSlots[dieIndex] = activeCount
  activeDice[activeCount] = dieIndex
  activeCount += 1

var alicePosition: int64 = 0
var bobPosition: int64 = 0
var aliceTurn = true

for rollIndex in 0 .. rollCount - 1:
  let dieIndex = nextInt(inputData, scanPos)
  let shownValue = nextInt(inputData, scanPos)
  let rangeFirst = nextInt(inputData, scanPos)
  let rangeLast = nextInt(inputData, scanPos)

  dieValues[dieIndex] = int64(shownValue)
  if shownValue > 0:
    addActive(dieIndex)
    assignDie(1, 0, diceCount - 1, dieIndex, shownValue mod cellCount, true)
  else:
    removeActive(dieIndex)
    assignDie(1, 0, diceCount - 1, dieIndex, 0, true)

  queryProduct = 1
  queryAvailable = 0
  queryRange(1, 0, diceCount - 1, rangeFirst, rangeLast)
  var moveDistance: int64 = 1
  if queryAvailable > 0:
    moveDistance = queryProduct

  var rolledPosition: int64 = 0
  if aliceTurn:
    alicePosition = (alicePosition + moveDistance) mod int64(cellCount)
    rolledPosition = alicePosition
  else:
    bobPosition = (bobPosition + moveDistance) mod int64(cellCount)
    rolledPosition = bobPosition
  appendOutput($rolledPosition)
  outputBuffer.add '\n'

  if alicePosition == bobPosition:
    let multiplier = alicePosition
    if multiplier == 0:
      zeroEpoch += 1
      activeCount = 0
      applyZero(1, 0, diceCount - 1)
    else:
      var activeIndex = 0
      while activeIndex < activeCount:
        let currentDie = activeDice[activeIndex]
        let newValue = dieValues[currentDie] * multiplier
        if newValue > int64(unavailableValue - 1):
          dieValues[currentDie] = int64(unavailableValue)
          assignDie(1, 0, diceCount - 1, currentDie, 1, false)
          removeActive(currentDie)
        else:
          dieValues[currentDie] = newValue
          assignDie(1, 0, diceCount - 1, currentDie, int(newValue mod int64(cellCount)), true)
          activeIndex += 1
  aliceTurn = not aliceTurn

stdout.write outputBuffer
outputBuffer.setLen 0
