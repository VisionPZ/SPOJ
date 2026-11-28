# EIUASSEMBLY — Assembly line (SPOJ)

<https://www.spoj.com/problems/EIUASSEMBLY/>

## Problem

A line of robots passes one product through every station, so the line only makes as many products per hour as its slowest robot. Spend a budget upgrading robot speeds, and report the largest rate the whole line can reach.

The first line gives the test count T. Each test starts with N and M, then N lines of base rate Pi and cost Mi. One line per test holds the best final rate.

| item | bound |
|---|---|
| tests T | 1 to 10 |
| robots N | 1 to 100000 |
| budget M | 0 to 1000000000000 |
| rate Pi and cost Mi | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

An upgrade of one robot costs Mi for one extra product per hour.

Sample input:

```
1
3 7
1 2
2 3
3 1
```

Sample output:

```
3
```

## Idea

Raising the line rate is like raising a row of fences: every fence below the target must be lifted before the row improves. Guess a target rate and add up the cost of all missing units. Binary search the largest target whose cost fits the budget.

The cost check touches each robot once, so one guess costs linear time. Trying each possible rate in turn would repeat that scan too often. A few dozen guesses settle the answer over this whole range.

## Why It Works

1. The line rate after upgrades equals the minimum robot rate.
2. Reaching target x costs (x − Pi) upgrades for robot i when Pi is below x.
3. That cost is exact, because upgrades are identical and independent.
4. If cost x fits the budget, every smaller target also fits.
5. Binary search therefore finds the largest feasible target.

| term | meaning |
|---|---|
| `baseRates` | starting products per hour |
| `upgradeCosts` | money for one extra unit on one robot |
| `affordableRate` | test that sums all missing units within the budget |

The monotonic cost test is what makes binary search valid.

The script example uses rates 1, 2, 3 and costs 2, 3, 1 with budget 7. Target 3 costs 2 × 2 + 1 × 3 + 0 × 1 = 7, so it fits. Target 4 costs 3 × 2 + 2 × 3 + 1 × 1 = 13, so it fails. The answer is 3.

The sample answer matches those two cost checks.

## Code

**Input and parser.** All robot data is read into two arrays per test.

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
```

One string holds the whole input.
The scanner consumes tokens in order.
Values fit in the target type before conversion.

**Feasibility test.** The cost sum stops as soon as one robot exceeds the budget.

```nim
proc affordableRate(baseRates: seq[int64], upgradeCosts: seq[int64], budget, targetRate: int64): bool =
  var remainingBudget = budget
  for robotIndex in 0 .. baseRates.len - 1:
    let missingUnits = targetRate - baseRates[robotIndex]
    if missingUnits <= 0:
      continue
    if missingUnits > remainingBudget div upgradeCosts[robotIndex]:
      return false
    remainingBudget -= missingUnits * upgradeCosts[robotIndex]
  return true
```

Division guards the product before it can overflow.
Robots already at the target cost nothing.
The test is monotone in the target.

**Binary search.** The upper bound uses the largest starting rate plus the whole budget.

```nim
  var lowRate: int64 = 0
  var highRate = largestRate + budget + 1
  while lowRate < highRate:
    let middleRate = lowRate + (highRate - lowRate + 1) div 2
    if affordableRate(baseRates, upgradeCosts, budget, middleRate):
      lowRate = middleRate
    else:
      highRate = middleRate - 1
  appendOutput($lowRate)
  outputBuffer.add '\n'
```

The upper midpoint keeps the loop moving.
Each step halves the remaining range.
Buffered output handles many tests per file.

## Complexity

The check dominates each binary search step.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | two robot arrays |
| cost test | one pass over robots per guess | none |
| binary search | logarithmic guesses per test | none |
| output | one buffered line per test | block buffer |

Each test repeats the same linear check only a few dozen times.

| measure | Big O |
|---|---|
| time | O(N log(M + max Pi)) per test |
| space | O(N) |

Testing every rate from the minimum upward would take time proportional to the budget instead of its logarithm. Binary search gives the answer from a short chain of cost checks.
