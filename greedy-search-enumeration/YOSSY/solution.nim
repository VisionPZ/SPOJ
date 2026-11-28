const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let soldierCount = nextInt(inputData, scanPos)
var powerOf = newSeq[int](soldierCount)
var foodOf = newSeq[int](soldierCount)
for soldierIndex in 0 .. soldierCount - 1:
  powerOf[soldierIndex] = nextInt(inputData, scanPos)
  foodOf[soldierIndex] = nextInt(inputData, scanPos)
let foodSupply = nextInt(inputData, scanPos)
let listLength = nextInt(inputData, scanPos)

proc ratioBefore(firstIndex: int, secondIndex: int): bool =
  let leftProduct = int64(powerOf[firstIndex]) * int64(foodOf[secondIndex])
  let rightProduct = int64(powerOf[secondIndex]) * int64(foodOf[firstIndex])
  if leftProduct != rightProduct:
    return leftProduct > rightProduct
  return powerOf[firstIndex] > powerOf[secondIndex]

var soldierOrder = newSeq[int](soldierCount)
for soldierIndex in 0 .. soldierCount - 1:
  soldierOrder[soldierIndex] = soldierIndex
for soldierIndex in 1 .. soldierCount - 1:
  let currentIndex = soldierOrder[soldierIndex]
  var insertionIndex = soldierIndex
  while insertionIndex > 0 and ratioBefore(currentIndex, soldierOrder[insertionIndex - 1]):
    insertionIndex = insertionIndex - 1
  var shiftIndex = soldierIndex
  while shiftIndex > insertionIndex:
    soldierOrder[shiftIndex] = soldierOrder[shiftIndex - 1]
    shiftIndex = shiftIndex - 1
  soldierOrder[insertionIndex] = currentIndex

var sortedPowers = newSeq[int](soldierCount)
var sortedFoods = newSeq[int](soldierCount)
for soldierIndex in 0 .. soldierCount - 1:
  sortedPowers[soldierIndex] = powerOf[soldierOrder[soldierIndex]]
  sortedFoods[soldierIndex] = foodOf[soldierOrder[soldierIndex]]
powerOf = sortedPowers
foodOf = sortedFoods

var foodPrefix = newSeq[int64](soldierCount + 1)
var powerPrefix = newSeq[int64](soldierCount + 1)
for soldierIndex in 0 .. soldierCount - 1:
  foodPrefix[soldierIndex + 1] = foodPrefix[soldierIndex] + int64(foodOf[soldierIndex])
  powerPrefix[soldierIndex + 1] = powerPrefix[soldierIndex] + int64(powerOf[soldierIndex])

var topPowers = newSeq[int64]()

proc pushPower(candidate: int64) =
  if topPowers.len < listLength:
    topPowers.add candidate
    var childIndex = topPowers.len - 1
    while childIndex > 0:
      let parentIndex = (childIndex - 1) div 2
      if topPowers[parentIndex] <= topPowers[childIndex]:
        break
      let swapValue = topPowers[parentIndex]
      topPowers[parentIndex] = topPowers[childIndex]
      topPowers[childIndex] = swapValue
      childIndex = parentIndex
  elif candidate > topPowers[0]:
    topPowers[0] = candidate
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      if leftChild >= topPowers.len:
        break
      let rightChild = leftChild + 1
      var smallestChild = leftChild
      if rightChild < topPowers.len and topPowers[rightChild] < topPowers[leftChild]:
        smallestChild = rightChild
      if topPowers[parentIndex] <= topPowers[smallestChild]:
        break
      let swapValue = topPowers[parentIndex]
      topPowers[parentIndex] = topPowers[smallestChild]
      topPowers[smallestChild] = swapValue
      parentIndex = smallestChild

proc fractionalBound(startIndex: int, capacity: int64): int64 =
  var lowIndex = startIndex
  var highIndex = soldierCount
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex + 1) div 2
    if foodPrefix[middleIndex] - foodPrefix[startIndex] <= capacity:
      lowIndex = middleIndex
    else:
      highIndex = middleIndex - 1
  let wholeCount = lowIndex
  var bound = powerPrefix[wholeCount] - powerPrefix[startIndex]
  if wholeCount < soldierCount:
    let usedFood = foodPrefix[wholeCount] - foodPrefix[startIndex]
    let remainingFood = capacity - usedFood
    let nextFood = int64(foodOf[wholeCount])
    if nextFood > 0:
      bound = bound + int64(powerOf[wholeCount]) * remainingFood div nextFood
  return bound

proc searchArmies(startIndex: int, usedFood: int64, currentPower: int64) =
  if topPowers.len == listLength and currentPower + fractionalBound(startIndex, int64(foodSupply) - usedFood) <= topPowers[0]:
    return
  if startIndex == soldierCount:
    pushPower(currentPower)
    return
  let soldierFood = int64(foodOf[startIndex])
  let soldierPower = int64(powerOf[startIndex])
  if usedFood + soldierFood <= int64(foodSupply):
    searchArmies(startIndex + 1, usedFood + soldierFood, currentPower + soldierPower)
  searchArmies(startIndex + 1, usedFood, currentPower)

searchArmies(0, 0, 0)

for powerIndex in 1 .. topPowers.len - 1:
  let currentPower = topPowers[powerIndex]
  var insertionIndex = powerIndex
  while insertionIndex > 0 and topPowers[insertionIndex - 1] < currentPower:
    topPowers[insertionIndex] = topPowers[insertionIndex - 1]
    insertionIndex = insertionIndex - 1
  topPowers[insertionIndex] = currentPower

for powerIndex in 0 .. topPowers.len - 1:
  appendOutput($(topPowers[powerIndex]))
  outputBuffer.add '\n'
for missingIndex in topPowers.len .. listLength - 1:
  appendOutput("0")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
