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

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
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
  var i = 0
  var j = finishTimes.len
  while i < j:
    let k = i + (j - i) div 2
    if finishTimes[k] <= startTime:
      i = k + 1
    else:
      j = k
  return i

proc solveCase(orders: var seq[Order], finishTimes: var seq[int], bestProfit: var seq[int64]): int64 =
  orders.sort(compareOrders)
  let orderCount = orders.len
  finishTimes.setLen(orderCount)
  for i in 0..<orderCount:
    finishTimes[i] = orders[i].finishTime
  bestProfit.setLen(orderCount + 1)
  bestProfit[0] = 0
  for i in 0..<orderCount:
    let compatibleCount = lastCompatibleCount(finishTimes, orders[i].startTime)
    let takeProfit = int64(orders[i].price) + bestProfit[compatibleCount]
    let skipProfit = bestProfit[i]
    if takeProfit > skipProfit:
      bestProfit[i + 1] = takeProfit
    else:
      bestProfit[i + 1] = skipProfit
  return bestProfit[orderCount]

var orders = newSeq[Order]()
var finishTimes = newSeq[int]()
var bestProfit = newSeq[int64]()

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let orderCount = nextInt(inputData, i)
  orders.setLen(orderCount)
  for k in 0..<orderCount:
    let startTime = nextInt(inputData, i)
    let duration = nextInt(inputData, i)
    orders[k].startTime = startTime
    orders[k].finishTime = startTime + duration
    orders[k].price = nextInt(inputData, i)
  let answer = solveCase(orders, finishTimes, bestProfit)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
