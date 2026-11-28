const flushBlockBytes = 1 shl 17

type Soldier = object
  coordX: int
  coordY: int

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

proc comesBefore(leftSoldier: Soldier, rightSoldier: Soldier): bool =
  if leftSoldier.coordX != rightSoldier.coordX:
    return leftSoldier.coordX < rightSoldier.coordX
  return leftSoldier.coordY < rightSoldier.coordY

proc sortSoldiers(values: var seq[Soldier], lowIndex: int, highIndex: int) =
  if highIndex - lowIndex < 16:
    var sortIndex = lowIndex + 1
    while sortIndex <= highIndex:
      let heldSoldier = values[sortIndex]
      var shiftIndex = sortIndex
      while shiftIndex > lowIndex and comesBefore(heldSoldier, values[shiftIndex - 1]):
        values[shiftIndex] = values[shiftIndex - 1]
        shiftIndex -= 1
      values[shiftIndex] = heldSoldier
      sortIndex += 1
    return
  let pivotSoldier = values[(lowIndex + highIndex) div 2]
  var leftIndex = lowIndex
  var rightIndex = highIndex
  while leftIndex <= rightIndex:
    while comesBefore(values[leftIndex], pivotSoldier):
      leftIndex += 1
    while comesBefore(pivotSoldier, values[rightIndex]):
      rightIndex -= 1
    if leftIndex <= rightIndex:
      swap(values[leftIndex], values[rightIndex])
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex:
    sortSoldiers(values, lowIndex, rightIndex)
  if leftIndex < highIndex:
    sortSoldiers(values, leftIndex, highIndex)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let soldierCount = nextInt(inputData, scanPos)
var soldiers = newSeq[Soldier](soldierCount)
for soldierIndex in 0 .. soldierCount - 1:
  soldiers[soldierIndex].coordX = nextInt(inputData, scanPos)
  soldiers[soldierIndex].coordY = nextInt(inputData, scanPos)

var needsSorting = false
for soldierIndex in 1 .. soldierCount - 1:
  if soldiers[soldierIndex].coordX < soldiers[soldierIndex - 1].coordX:
    needsSorting = true
    break
if needsSorting:
  sortSoldiers(soldiers, 0, soldierCount - 1)

var frontlineCount = 0
var bestRightHeight = -1
var scanIndex = soldierCount - 1
while scanIndex >= 0:
  let groupX = soldiers[scanIndex].coordX
  var groupHeight = -1
  while scanIndex >= 0 and soldiers[scanIndex].coordX == groupX:
    if soldiers[scanIndex].coordY > groupHeight:
      groupHeight = soldiers[scanIndex].coordY
    scanIndex -= 1
  if groupHeight > bestRightHeight:
    frontlineCount += 1
    bestRightHeight = groupHeight

appendOutput($frontlineCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
