## Problem

Read several party budgets and lists of parties. Each party has an entrance fee and a fun value. Choose parties so that total fun is as large as possible without exceeding the budget. Print the smallest fee that reaches the best fun, followed by that fun.

| Quantity | Bound |
| --- | --- |
| Budget | at most 500 |
| Parties per case | at most 100 |
| Fee | 5 to 25 |
| Fun | 0 to 10 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

Input ends with a line containing `0 0`. The budget need not be spent exactly.

## Idea

Use a one-dimensional knapsack table. `bestFun[k]` is the largest fun reachable with exactly that much spent. Visit parties one by one and walk k downwards so each party is used once. After all parties, take the largest table value and the smallest spent amount that reaches it.

Each party updates at most `budget` entries, so the cost per case is O(n · budget). Enumerating all subsets would cost O(2ⁿ).

## Why It Works

When a party with fee `fee` and fun `fun` is considered, any solution spending `k` either skips it, keeping `bestFun[k]`, or uses it, gaining `bestFun[k − fee] + fun`. Walking downwards guarantees the new value cannot be reused within the same party.

The maximum table entry is the best achievable fun. Several amounts may reach it, so the final scan picks the least expensive one. The sample budget 50 and ten parties give best fun 26 at cost 49.

## Code

Input is read once and parsed with a digit scanner.

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

The `maxBudget` constant records the stated upper bound but the table is sized from the actual input value. Every number is non-negative, so the scanner needs no sign branch.

The driver fills the knapsack table and prints the tie-broken answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

The countdown loop keeps each party to one use. The two final scans find the best fun and then the least cost that reaches it. Output is written in blocks, not once per case.

## Complexity

Filling the table costs O(n · budget) time and O(budget) space per case. The two final scans cost O(budget). Output costs O(1) per case. Total time is O(n · budget) and total space is O(budget) plus the input buffer. Enumerating subsets would cost O(2ⁿ).
