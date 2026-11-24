## Problem

Each case lists orders for one airplane. An order has a start time, a duration, and a price. Choose orders that never overlap, then print the largest total price on its own line. Two orders fit when the first one ends at or before the second one starts.

The statement fixes these bounds:

| Quantity | Bound |
| --- | --- |
| Test cases per file | 1 to 30 |
| Orders per case, n | up to 10000 |
| Start time | 0 to 999999 |
| Duration | 1 to 999999 |
| Price | 1 to 99999 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The case count times the order count sets an input ceiling of 300000 orders, so each case must stay near linear work.

## Idea

Sort orders by finish time, then walk them once and keep the best total for each prefix. A binary search over finish times counts the earlier orders that end at or before the current start, so one order costs O(log n). Taking adds the price to the best compatible prefix and skipping keeps the current best, while scanning every earlier order would cost O(n squared).

## Why It Works

An order occupies the half-open span from its start to its start plus its duration. Two orders fit when the earlier finish is at most the later start, so touching ends are allowed.

Sorting by finish time puts every compatible earlier order before the current order. The value bestProfit at index k is the best total using the first k sorted orders. The search returns compatibleCount, the number of finish times at most the current start.

Those orders all finish before the current start, so any of their best subsets can pair with the current order. The current order finishes after its own start, so compatibleCount never exceeds its position, and its bestProfit value is already known.

The update takes the larger of skipping and taking:

takeProfit = price plus bestProfit at compatibleCount
skipProfit = bestProfit at the current position
new bestProfit = the larger of those two values

The trace script prints these steps for the sample:

```
order 1 finish 5 price 10 compatible 0 take 10 skip 0 best 10
order 2 finish 10 price 14 compatible 0 take 14 skip 10 best 14
order 3 finish 14 price 7 compatible 1 take 17 skip 14 best 17
order 4 finish 15 price 8 compatible 1 take 18 skip 17 best 18
answer 18
```

The last row gives 18, which matches the sample output.

## Code

The constants cap the digit value and the output block. The object holds one order in three named fields. The read loop appends every input line to one buffer, and the scanner builds integers by hand. The output helper writes only when the buffer reaches the block size.

```nim
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
```

The read loop visits each input line once. The scanner stops at any separator, which keeps the digit loop short. The buffer never grows past one block plus one answer.

The comparator orders jobs by finish time, then by start time for ties. The search keeps a half-open window over the sorted finish times and returns the count of times at most the start.

```nim
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
```

The search runs at most log base two of n iterations. The `<=` test is the trap: it admits an order that ends exactly when the next one starts. That detail decides the sample.

solveCase sorts once, copies finish times into a flat array, then walks all n orders. Each step does one search and one comparison, then stores the larger total at the next position.

```nim
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
```

The two loops each run n times, and the profit table has n plus one slots. Storing the finish times separately keeps the search working on plain integers. Profits use int64, which holds the sum of 10000 prices below 100000.

The main loop reads one case, reuses the three work arrays, and prints one answer per case. A final write flushes any bytes left in the output buffer.

```nim
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
```

The outer loop runs once per case, and the inner loop runs once per order. Reusing the arrays avoids a fresh allocation for every case. The duration is added to the start at read time, so each order stores its finish directly.

## Complexity

Reading costs one pass over the input buffer. Sorting one case costs O(n log n), and the walk costs O(n log n) because each order does a binary search. Total time is O(total tokens plus the sum of n log n over all cases).

Space is O(n) per case for the orders, the finish times, and the profit table. The naive form compares every earlier order at each step and costs O(n squared) per case.
