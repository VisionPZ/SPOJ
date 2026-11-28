const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const infinity = 1_000_000_000_000'i64
const verticalShift = 1001
const verticalSlots = 2003

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

let courseCount = nextInt(inputData, scanPos)
let restaurantCount = nextInt(inputData, scanPos)
let budgetLimit = nextInt(inputData, scanPos)

var gridRow = newSeq[int](restaurantCount)
var gridColumn = newSeq[int](restaurantCount)
var priceTable = newSeq[int](restaurantCount * courseCount)

for restaurant in 0..<restaurantCount:
  gridRow[restaurant] = nextInt(inputData, scanPos)
  gridColumn[restaurant] = nextInt(inputData, scanPos)
  for course in 0..<courseCount:
    priceTable[restaurant * courseCount + course] = nextInt(inputData, scanPos)

proc signFor(combo, bitPosition: int): int =
  if (combo and bitPosition) == 0: 1 else: -1

proc transformedRow(combo, restaurant: int): int =
  signFor(combo, 1) * gridRow[restaurant]

proc transformedColumn(combo, restaurant: int): int =
  signFor(combo, 2) * gridColumn[restaurant]

var sweepOrders: array[4, seq[int]]
for combo in 0..<4:
  sweepOrders[combo] = newSeq[int](restaurantCount)
  for restaurant in 0..<restaurantCount:
    sweepOrders[combo][restaurant] = restaurant
  for index in 1..<restaurantCount:
    let moving = sweepOrders[combo][index]
    let movingRow = transformedRow(combo, moving)
    var cursor = index - 1
    while cursor >= 0 and transformedRow(combo, sweepOrders[combo][cursor]) > movingRow:
      sweepOrders[combo][cursor + 1] = sweepOrders[combo][cursor]
      cursor -= 1
    sweepOrders[combo][cursor + 1] = moving

proc fenwickUpdate(tree: var seq[int64], index: int, value: int64) =
  var cursor = index
  while cursor < tree.len:
    if value < tree[cursor]:
      tree[cursor] = value
    cursor += (cursor and (-cursor))

proc fenwickQuery(tree: seq[int64], index: int): int64 =
  var cursor = index
  var best = infinity
  while cursor > 0:
    if tree[cursor] < best:
      best = tree[cursor]
    cursor -= (cursor and (-cursor))
  return best

let stateWidth = budgetLimit + 1
var previousLayer = newSeq[int64](stateWidth * restaurantCount)
var currentLayer = newSeq[int64](stateWidth * restaurantCount)
var distanceToRestaurant = newSeq[int64](restaurantCount)
var columnTree = newSeq[int64](verticalSlots)

for index in 0..<previousLayer.len:
  previousLayer[index] = infinity
for restaurant in 0..<restaurantCount:
  let openingPrice = priceTable[restaurant * courseCount]
  if openingPrice > 0 and openingPrice <= budgetLimit:
    previousLayer[openingPrice * restaurantCount + restaurant] = 0'i64

for course in 1..<courseCount:
  for index in 0..<currentLayer.len:
    currentLayer[index] = infinity
  for spent in 0..budgetLimit:
    for restaurant in 0..<restaurantCount:
      distanceToRestaurant[restaurant] = infinity
    for combo in 0..<4:
      for index in 0..<columnTree.len:
        columnTree[index] = infinity
      for restaurant in sweepOrders[combo]:
        let rowValue = transformedRow(combo, restaurant)
        let columnValue = transformedColumn(combo, restaurant)
        let previousCost = previousLayer[spent * restaurantCount + restaurant]
        let columnIndex = columnValue + verticalShift
        if previousCost < infinity div 2:
          let reduced = previousCost - int64(rowValue) - int64(columnValue)
          fenwickUpdate(columnTree, columnIndex, reduced)
        let candidate = fenwickQuery(columnTree, columnIndex) + int64(rowValue) + int64(columnValue)
        if candidate < distanceToRestaurant[restaurant]:
          distanceToRestaurant[restaurant] = candidate
    for restaurant in 0..<restaurantCount:
      let dishPrice = priceTable[restaurant * courseCount + course]
      let newCost = spent + dishPrice
      if dishPrice > 0 and newCost <= budgetLimit:
        let travelTime = distanceToRestaurant[restaurant]
        let target = newCost * restaurantCount + restaurant
        if travelTime < currentLayer[target]:
          currentLayer[target] = travelTime
  let swapLayer = previousLayer
  previousLayer = currentLayer
  currentLayer = swapLayer

var bestTravel = infinity
for index in 0..<previousLayer.len:
  if previousLayer[index] < bestTravel:
    bestTravel = previousLayer[index]

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if bestTravel >= infinity div 2:
  appendOutput("-1")
else:
  appendOutput($(bestTravel))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
