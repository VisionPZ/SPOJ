# RENT — Rent your airplane and make money (SPOJ)

<https://www.spoj.com/problems/RENT/>

## Problem

A company with one plane receives rental orders, each giving a time interval and a price. Choose non-overlapping orders that maximize the total price.

Input: `T` cases. Each starts with `n`, then `n` lines `st d p`: start time, duration, and price. Output: one line per case, the maximum total price the company can earn.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `T` | at most 30 |
| Orders per case `n` | at most 10000 |
| Start `st` | 0 ≤ st < 10^6 |
| Duration `d`, price `p` | 0 < d < 10^6, 0 < p < 100000 |
| Judge limit | 3000 ms, 1536 MB |

An order ending exactly when another starts is compatible.

The sample input and output:

```
1
4
0 5 10
3 7 14
5 9 7
6 9 8
```

```
18
```

## Idea

Treat the offers as jobs on one calendar and decide each one by comparing take against skip. Think of one airplane's calendar, where a new order fits only after the last accepted one.

The program sorts orders by finish time. For order `i`, a binary search finds how many earlier orders finish before its start. The dynamic program then compares taking order `i` plus that prefix's best profit with skipping order `i`.

Sorting costs O(n log n), the searches cost O(n log n), and the DP costs O(n). Enumeration of feasible subsets costs 2^n, which explodes at 10000 orders.

A sorted calendar and a prefix maximum decide each offer in log time.

## Why It Works

Four facts carry the solution.

1. An order occupies the half-open interval `[st, st + d)`. It fits before another order exactly when its finish time is at most that order's start.
2. Sorting by finish time turns all compatible earlier orders into a prefix. `lastCompatibleCount` finds that prefix length by binary search.
3. The DP takes the better of `price + bestProfit[prefix]` and `bestProfit[i]`, where `bestProfit[i]` already solves the first `i` orders.
4. Profits use 64-bit integers, so summing up to 10000 prices cannot overflow.

The values the DP stores:

| Term | Meaning |
|---|---|
| `finishTime` | start plus duration of one order |
| `lastCompatibleCount` | count of orders ending by a given start time |
| `bestProfit` | optimal profit for each prefix of sorted orders |
| `takeProfit`, `skipProfit` | the two candidates compared in the DP |

The prefix search is what makes each decision logarithmic.

A script-traced example with the four sample orders:

```
order  start dur price  finish
1      0     5   10     5
2      3     7   14     10
3      5     9   7      14
4      6     9   8      15

i  order  compatible prefix  take       skip      best
1  1       0                  10         0         10
2  2       0                  14         10        14
3  3       1 (order 1)        7 + 10=17  14        17
4  4       1 (order 1)        8 + 10=18  17        18

answer = 18  (orders 1 and 4)
```

## Code

**Constants and order type.** One record holds start, finish, and price.

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
```

`flushBlockBytes` sets the output block size. `finishTime` is computed once when reading each order.

**Input and scanner.** The whole stream is read into one buffer.

```nim
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
```

`nextInt` skips non-digits and reads each positive value by index. The `var` parameter keeps the scan position between calls.

**Output helper and sort order.** Orders sort by finish time, then by start time.

```nim
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
```

`appendOutput` flushes at 256 KiB. `compareOrders` uses finish time first, which the DP requires.

**Binary search.** `lastCompatibleCount` finds the prefix ending by a start time.

```nim
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
```

The loop halves `[0, len]` until it finds the first finish time above `startTime`. It returns a count, which indexes `bestProfit` directly.

**DP solver.** Each order compares taking against skipping.

```nim
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
```

`orders.sort` fixes the prefix order. `takeProfit` adds the current price to the compatible prefix's profit. `skipProfit` carries the earlier optimum forward. The result is the last prefix value.

**Driver.** Orders are read, solved, and answered once per case.

```nim
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
```

Three reusable sequences avoid per-case allocation of helpers. `startTime + duration` becomes `finishTime` at input time. Each case appends one answer line.

## Complexity

Each case sorts orders, searches a prefix, then fills the DP table.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sort | O(n log n) | O(n) |
| Binary searches | O(n log n) total | O(1) |
| DP fill | O(n) | O(n) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n log n) | O(n) |

The sort dominates, and `n ≤ 10000` keeps it small.

| Measure | Big O |
|---|---|
| Time | O(n log n) per case |
| Space | O(n) for orders and the profit table |

Visiting every feasible subset would cost 2^n time.

Testing all subsets of non-overlapping orders would take 2^n steps. Binary search plus a prefix maximum reaches the optimum in O(n log n).
