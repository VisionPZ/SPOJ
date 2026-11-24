import std/algorithm

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18

type
  Order = object
    startTime: int
    finishTime: int
    price: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareOrders(left, right: Order): int =
  if left.finishTime != right.finishTime:
    return left.finishTime - right.finishTime
  return left.startTime - right.startTime

proc lastCompatibleCount(finishTimes: seq[int], startTime: int): int =
  var lowIndex = 0
  var highIndex = finishTimes.len
  while lowIndex < highIndex:
    let middleIndex = lowIndex + (highIndex - lowIndex) div 2
    if finishTimes[middleIndex] <= startTime:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex

proc solveCase(orders: var seq[Order], finishTimes: var seq[int], bestProfit: var seq[int64]): int64 =
  orders.sort(compareOrders)
  let orderCount = orders.len
  finishTimes.setLen(orderCount)
  for orderIndex in 0..<orderCount:
    finishTimes[orderIndex] = orders[orderIndex].finishTime
  bestProfit.setLen(orderCount + 1)
  bestProfit[0] = 0
  for orderIndex in 0..<orderCount:
    let compatibleCount = lastCompatibleCount(finishTimes, orders[orderIndex].startTime)
    let takeProfit = int64(orders[orderIndex].price) + bestProfit[compatibleCount]
    let skipProfit = bestProfit[orderIndex]
    if takeProfit > skipProfit:
      bestProfit[orderIndex + 1] = takeProfit
    else:
      bestProfit[orderIndex + 1] = skipProfit
  return bestProfit[orderCount]

var orders = newSeq[Order]()
var finishTimes = newSeq[int]()
var bestProfit = newSeq[int64]()

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let orderCount = nextInt(inputData, scanPos)
  orders.setLen(orderCount)
  for orderIndex in 0..<orderCount:
    let startTime = nextInt(inputData, scanPos)
    let duration = nextInt(inputData, scanPos)
    orders[orderIndex].startTime = startTime
    orders[orderIndex].finishTime = startTime + duration
    orders[orderIndex].price = nextInt(inputData, scanPos)
  let answer = solveCase(orders, finishTimes, bestProfit)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
