# PARTY — Party Schedule (SPOJ)
<https://www.spoj.com/problems/PARTY/>

## Problem

A tight budget and a list of parties: each party costs an entrance fee and delivers some fun. You want the most fun without overspending.

When several plans give the same fun, spend the least money. Report the chosen cost and its fun for each budget list.

Input: each case starts with budget and party count. Then come that many fee-fun pairs. A case of `0 0` ends the input. Output: two integers per case, the cheapest cost and the maximum fun.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Budget | at most 500 |
| Parties per case | at most 100 |
| Entrance fee | 5 to 25 francs |
| Fun value | 0 to 10 |
| Terminator | `0 0` |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The sample has one case with ten parties:

```
50 10
12 3
15 8
16 9
16 6
10 2
21 9
18 4
12 4
17 8
18 9
0 0
```

```
49 26
```

The best plan spends 49 francs and earns 26 fun.

## Idea

Fill a budget table one party at a time, and keep the smallest cost that reaches the top fun. Picture packing a knapsack with tickets: each ticket exists once, and you maximize enjoyment under a weight limit.

The program uses 0/1 knapsack (each item chosen at most once) dynamic programming. Entry `bestFun[k]` holds the most fun affordable within cost k. For each party, the program walks k downward and tries adding that party's fun.

Walking downward matters: it reads last party's values, so no party is used twice. After all parties, the program scans for the highest fun and the lowest cost achieving it.

Each case costs O(n × budget) time and O(budget) space. Trying all 2ⁿ subsets costs exponential time.

Takeaway: one budget-sized row replaces an exponential search over party sets.

## Why It Works

Four facts justify the update.

1. Before a party is processed, `bestFun[k − fee]` is the best fun using earlier parties within that smaller cost.
2. Adding the current party gives candidate `bestFun[k − fee] + fun`. Walking k downward leaves `bestFun[k − fee]` unchanged by this party, so the party appears once.
3. Taking the maximum keeps `bestFun[k]` as the best fun within cost k. The array is nondecreasing in k, so the global best is simply its maximum.
4. Scanning k upward and accepting the first `bestFun[k] == topFun` yields the cheapest cost with maximum fun. That matches the spending rule.

These are the values in the knapsack loop:

| Term | Meaning |
| --- | --- |
| `budget` | largest allowed total fee |
| `fee`, `fun` | entrance cost and fun of one party |
| `bestFun[k]` | best fun using processed parties within cost k |
| `candidate` | fun from taking the current party at cost k |
| `topFun` | highest fun over all costs |
| `cheapest` | smallest cost that reaches `topFun` |

A script traces a small case with budget 10:

```
start: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
after fee 5 fun 2: [0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2]
after fee 6 fun 4: [0, 0, 0, 0, 0, 2, 4, 4, 4, 4, 4]
after fee 10 fun 5: [0, 0, 0, 0, 0, 2, 4, 4, 4, 4, 5]
top fun: 5 cheapest cost: 10
```

The last row keeps cost 6 with fun 4, yet chooses cost 10 because fun 5 is higher. Cost 7 through 9 also hold fun 4, so they lose to cost 10.

## Code

**Input.** A single buffer holds all cases, and the scanner walks it once.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxBudget = 500

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

The scanner skips whitespace and stops at the buffer end. The `maxBudget` constant documents the largest legal cost. The cost is one pass over the input bytes.

**Output.** Answers collect in a block-flushed buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush happens every `flushBlockBytes` bytes. No write occurs while processing a party. The cost is one pass over the answer text.

**Driver.** Each case runs the knapsack and prints the best pair.

```nim
while true:
  let budget = nextInt(inputData, i)
  let partyCount = nextInt(inputData, i)
  if budget == 0 and partyCount == 0:
    break
  var bestFun = newSeq[int](budget + 1)
  for j in 0..<partyCount:
    let fee = nextInt(inputData, i)
    let fun = nextInt(inputData, i)
    for k in countdown(budget, fee):
      let candidate = bestFun[k - fee] + fun
      if candidate > bestFun[k]:
        bestFun[k] = candidate
  var topFun = 0
  for k in 0..budget:
    if bestFun[k] > topFun:
      topFun = bestFun[k]
  var cheapest = budget
  for k in 0..budget:
    if bestFun[k] == topFun and k < cheapest:
      cheapest = k
  appendOutput($cheapest)
  outputBuffer.add ' '
  appendOutput($topFun)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The `countdown(budget, fee)` bound stops before k drops below the fee. The zero pair ends the loop before any table is built. The final write flushes the tail.

## Complexity

The party loop carries the cost.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Knapsack per case | O(n × budget) | O(budget) |
| Best-cost scan | O(budget) | O(1) |
| Output | O(cases) | O(block size) |

The knapsack dominates, with at most 100 × 500 updates per case.

| Measure | Big O |
| --- | --- |
| Time per case | O(n × budget) |
| Total time | O(sum of n × budget over cases) |
| Working space | O(budget) |

Trying all subsets of parties takes O(2ⁿ) time, which grows far faster than the budget table.
