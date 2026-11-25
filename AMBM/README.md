# AMBM — Ambitious Manager (SPOJ)

<https://www.spoj.com/problems/AMBM/>

## Problem

Baba needs a set of days whose redesigned salaries add up to exactly N. The redesigned pay on day i is a_i plus twice the previous pay, and every chosen day contributes once.

Input starts with the number of cases T. Each case gives N and K on one line, then K daily amounts a_i on the next line. N fits in a signed 64-bit integer, K is at most 50, and each a_i is at most 1000.

Output prints sorted 1-based day indices separated by single spaces. A case with no matching set prints -1.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| target N | 1 to 2^63 - 1 |
| days K | 1 to 50 |
| daily amount a_i | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

The pay recurrence makes each day larger than all earlier days together.

Sample input and output:

```
2
9 3
1 1 2
10 2
2 3
```

```
1 3
-1
```

The two blocks come from the statement and drive the checks.

## Idea

Treat each day's pay as a coin worth more than all smaller coins combined, like canonical currency denominations. Take the largest coin that fits, then repeat.

The program builds the pays with the recurrence b_i = 2*b_{i-1} + a_i and walks days from largest to smallest. Each day costs one comparison and one subtraction. A brute-force search would test 2^K subsets per case, which explodes at K = 50.

Greedy selection finishes every case in one backward pass.

## Why It Works

1. The recurrence gives b_i = 2*b_{i-1} + a_i for every day after the first.
2. Each a_i is positive, so b_i exceeds twice b_{i-1}.
3. Earlier pays sum to less than b_i, so every subset sum is unique.
4. Greedy takes b_i whenever it fits the remaining target.
5. A nonzero remainder after the last day proves no subset exists.

| term | meaning |
|---|---|
| `runningPay` | current redesigned daily salary |
| `dailyPay` | salary for each day, in order |
| `remaining` | target still to be collected |
| `chosenDays` | 1-based days selected by greedy |

The uniqueness of subset sums makes greedy exact.

A traced example uses a = 1 1 2 and N = 9:

```
b1 = 1, b2 = 2*1 + 1 = 3, b3 = 2*3 + 2 = 8
N = 9: take day 3 (8), remainder 1
take day 1 (1), remainder 0 -> print 1 3
N = 10: take 8, remainder 2, skip 3, take 1, remainder 1 -> print -1
```

The trace matches the first sample answer exactly.

## Code

**Input and output setup.**

```nim
const flushBlockBytes = 1 shl 17

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

```

The hand reader loads every line before parsing numbers.
One buffer collects output across all cases.

**Greedy pay construction and selection.**

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let targetAmount = int64(nextInt(inputData, scanPos))
  let periodDays = nextInt(inputData, scanPos)
  var dailyPay = newSeq[int64](periodDays)
  var runningPay: int64 = 0
  var totalPay: int64 = 0
  for dayIndex in 0 .. periodDays - 1:
    let basePay = int64(nextInt(inputData, scanPos))
    runningPay = runningPay * 2 + basePay
    dailyPay[dayIndex] = runningPay
    totalPay = totalPay + runningPay
  if totalPay < targetAmount:
    appendOutput("-1")
  else:
    var remaining = targetAmount
    var chosenDays = newSeq[int]()
    var dayIndex = periodDays - 1
    while dayIndex >= 0:
      if dailyPay[dayIndex] <= remaining:
        remaining = remaining - dailyPay[dayIndex]
        chosenDays.add dayIndex + 1
      dayIndex -= 1
    if remaining != 0:
      appendOutput("-1")
    else:
      var outputIndex = chosenDays.len - 1
      while outputIndex >= 0:
        appendOutput($chosenDays[outputIndex])
        if outputIndex > 0:
          appendOutput(" ")
        outputIndex -= 1
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The recurrence runs once per day and keeps a running total.
Days are visited backward, then printed in increasing order.
A nonzero remainder prints -1.

## Complexity

Each case builds K pays and makes one greedy pass over them.

| phase | time | space |
|---|---|---|
| input read | one pass over case tokens | one input string |
| pay build | K recurrence steps | K salaries |
| greedy pass | one backward scan | K chosen days |
| output | one buffered write per case | block buffer |

The pay build and greedy pass share the same linear cost.

| measure | Big O |
|---|---|
| time | O(K) per case |
| space | O(K) per case |

Testing all subsets would cost O(2^K) per case, so greedy replaces exponential work with a single pass.
