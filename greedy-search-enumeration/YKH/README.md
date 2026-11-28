# YKH — Please help You-Know-Who (SPOJ)

<https://www.spoj.com/problems/YKH/>

## Problem

A seller sets one or more prices and pays a bribe for each price. Each client buys `a - b * p` grams at price `p` and chooses the price that gives the seller the largest profit. Find the maximum total profit after all bribes.

The first line is the number of test cases. Each case starts with the non-negative bribe `B` and the client count `C`. The next `C` lines give positive integers `a` and `b` for one client. All input numbers are at most 2000. Print one float per case with absolute or relative error below 1e-6.

| item | bound |
|---|---|
| test cases | fewer than 20 |
| clients `C` | at most 2000 |
| `a`, `b`, `B` | at most 2000 |
| judge limit | 1513 ms, 1536 MB |

A client with negative demand buys nothing, so the best price never exceeds `a / b`.

Sample input:

```
2
10 2
10 1
20 3
100 1
5 1
```

Sample output:

```
46.25
0
```

## Idea

Think of clients as beads on a string ordered by their favourite price; one certificate can serve a consecutive run of beads. Sorting by `a / b` makes every certificate cover one contiguous block. A dynamic program over prefix lengths tries every last block and keeps the best revenue. Brute force over all price sets is continuous and unbounded, while this block DP costs quadratic time in the client count.

The table gives the cost of one case.

| item | bound |
|---|---|
| sorting | `C` log `C` comparisons |
| block DP | `C` squared block trials |

This cost shape fits the client bound and the time limit.

## Why It Works

1. Client profit at price `p` is a * p - b * p * p, a concave parabola.
2. Sorting by `a / b` orders the parabolas so any two switch at most once.
3. An optimal price set therefore serves contiguous blocks of the sorted list.
4. For a block, let `A` be the sum of `a` and `B` the sum of `b`.
5. Revenue is A * p - B * p * p, maximized at p = A / (2 * B).
6. That maximum equals A * A / (4 * B), which is the value used in the DP.
7. Subtract one bribe per block, and keep zero as the option of selling nothing.

The table names the values used in the code.

| term | meaning |
|---|---|
| `clients` | sorted pairs of `a` and `b` |
| `prefixA` | running sum of `a` values |
| `prefixB` | running sum of `b` values |
| `amountSum` | sum of `a` in one candidate block |
| `rateSum` | sum of `b` in one candidate block |
| `bestProfit` | best profit for each prefix length |

Each DP state stores one float.

The worked example uses the first sample case. The script reports the sorted order and the single block.

```
sorted by a/b: (20,3) ratio 6.667, (10,1) ratio 10
amountSum = 30
rateSum   = 4
price     = 30 / 8 = 3.75
revenue   = 30 * 30 / 16 = 56.25
profit    = 56.25 - 10 = 46.25
```

The second sample case has a bribe of 100 and one client, so selling gives negative profit and the answer is zero.

## Code

**Input, sort, and formatting.** The reader loads the clients, an insertion sort orders them, and the formatter trims trailing zeros.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const answerDecimals = 6

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

proc comesBefore(firstA: int, firstB: int, secondA: int, secondB: int): bool =
  return float64(firstA) * float64(secondB) < float64(secondA) * float64(firstB)

proc sortClients(values: var seq[int]) =
  for outerIndex in 1 .. values.len div 2 - 1:
    var cursor = outerIndex
    while cursor > 0:
      let previous = cursor - 1
      let firstA = values[previous * 2]
      let firstB = values[previous * 2 + 1]
      let secondA = values[cursor * 2]
      let secondB = values[cursor * 2 + 1]
      if comesBefore(secondA, secondB, firstA, firstB):
        let heldA = values[cursor * 2]
        let heldB = values[cursor * 2 + 1]
        values[cursor * 2] = firstA
        values[cursor * 2 + 1] = firstB
        values[previous * 2] = heldA
        values[previous * 2 + 1] = heldB
        cursor = previous
      else:
        break

proc formatAnswer(value: float64): string =
  if value == 0.0:
    return "0"
  result = formatFloat(value, ffDecimal, answerDecimals)
  while result.len > 0 and result[result.len - 1] == '0':
    result.setLen(result.len - 1)
  if result.len > 0 and result[result.len - 1] == '.':
    result.setLen(result.len - 1)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Cross multiplication avoids division during sorting. Insertion sort keeps the source short for 2000 clients. Six decimal places meet the error bound.

**Block dynamic program.** Prefix sums turn every candidate block into one arithmetic expression.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let bribe = nextInt(inputData, scanPos)
  let clientCount = nextInt(inputData, scanPos)
  var clients = newSeq[int](clientCount * 2)
  for clientIndex in 0 .. clientCount - 1:
    clients[clientIndex * 2] = nextInt(inputData, scanPos)
    clients[clientIndex * 2 + 1] = nextInt(inputData, scanPos)
  sortClients(clients)
  var prefixA = newSeq[float64](clientCount + 1)
  var prefixB = newSeq[float64](clientCount + 1)
  for clientIndex in 0 .. clientCount - 1:
    prefixA[clientIndex + 1] = prefixA[clientIndex] + float64(clients[clientIndex * 2])
    prefixB[clientIndex + 1] = prefixB[clientIndex] + float64(clients[clientIndex * 2 + 1])
  var bestProfit = newSeq[float64](clientCount + 1)
  for prefixLength in 1 .. clientCount:
    var bestHere = bestProfit[prefixLength - 1]
    for blockStart in 0 .. prefixLength - 1:
      let amountSum = prefixA[prefixLength] - prefixA[blockStart]
      let rateSum = prefixB[prefixLength] - prefixB[blockStart]
      let blockRevenue = amountSum * amountSum / (4.0 * rateSum)
      let candidate = bestProfit[blockStart] + blockRevenue - float64(bribe)
      if candidate > bestHere:
        bestHere = candidate
    bestProfit[prefixLength] = bestHere
  if bestProfit[clientCount] < 0.0:
    bestProfit[clientCount] = 0.0
  appendOutput(formatAnswer(bestProfit[clientCount]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop tries every start for each prefix end. The initial best value represents serving no further client. A negative final result is clamped to zero.

## Complexity

One case sorts the clients and then fills a quadratic DP table.

| phase | time | space |
|---|---|---|
| input read | one pass over all integers | one input string |
| sort | insertion sort over `C` pairs | one flat array |
| block DP | `C` squared revenue trials | three arrays of `C` floats |

The three arrays dominate working memory.

| measure | Big O |
|---|---|
| time | O(C^2) per case |
| space | O(C) |

Trying every subset of certificates would take exponential time, while the block DP takes quadratic time.
