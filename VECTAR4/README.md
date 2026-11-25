# VECTAR4 — Changus Final Battle (SPOJ)

<https://www.spoj.com/problems/VECTAR4/>

## Problem

Changu starts day 1 by defeating one enemy. Each later day he defeats one fewer, the same number, or one more than the previous day, and the final day defeats at most one. Given N enemies, report the fewest days needed to defeat all of them.

The input starts with the test count T, followed by T lines each holding one N. Print one day count per line in input order.

| item | bound |
|---|---|
| tests T | 1 to 100000 |
| enemies N | 1 to 1000000000000000000 |
| judge limit | 1000 ms, 1536 MB |

The enemy count fits in a 64-bit integer.

Sample input:

```
3
4
1
9
```

Sample output:

```
3
1
5
```

The schedules are 1+2+1, 1, and 1+2+3+2+1.

## Idea

Build the tallest hill that still lands back at one, like stacking blocks up to a peak and then back down. A peak of h gives a perfect square of h squared enemies in 2h - 1 days. A short plateau adds enemies without adding much height, so only three day counts are possible near a square. Integer square root plus a small remainder test gives each answer directly. Simulating days one at a time would take a billion steps for large N.

## Why It Works

1. Starting at 1 and changing by at most 1, reaching peak h and returning to 1 takes 2h - 1 days.
2. That hill defeats h squared enemies, the largest total possible in 2h - 1 days.
3. Holding the peak one extra day lifts the maximum to h squared plus h in 2h days.
4. Holding it two extra days lifts the maximum to (h + 1) squared minus one in 2h + 1 days.
5. Let r be N minus h squared. If r is 0, use 2h - 1 days; if r is at most h, use 2h; otherwise use 2h + 1.
6. Binary search finds the integer square root exactly, so no floating rounding enters the answer.

| term | meaning |
|---|---|
| `integerSquareRoot` | binary search for the floor square root |
| `enemyCount` | total enemies for one test |
| `rootValue` | floor square root of the enemy count |
| `remainderValue` | enemy count beyond rootValue squared |
| `dayCount` | minimum days written for the test |

The table applies the three cases to the sample and two nearby values.

| N | rootValue | remainderValue | dayCount |
|---|---|---|---|
| 1 | 1 | 0 | 1 |
| 4 | 2 | 0 | 3 |
| 5 | 2 | 1 | 4 |
| 7 | 2 | 3 | 5 |
| 9 | 3 | 0 | 5 |

Every row matches the smallest hill that can hold N enemies.

## Code

**Input and scanner.** The whole stream is read once before any computation.

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

The hand reader skips whitespace between numbers.
The output buffer flushes in large blocks.
All products stay within 64-bit range.

**Integer square root and day count.** Each test needs one square root and one comparison.

```nim
proc integerSquareRoot(value: int64): int64 =
  var lowValue: int64 = 0
  var highValue: int64 = 1000000000
  while lowValue <= highValue:
    let middleValue = (lowValue + highValue) div 2
    if middleValue * middleValue <= value:
      lowValue = middleValue + 1
    else:
      highValue = middleValue - 1
  return highValue

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let enemyCount = int64(nextInt(inputData, scanPos))
  let rootValue = integerSquareRoot(enemyCount)
  let remainderValue = enemyCount - rootValue * rootValue
  var dayCount: int64 = 0
  if remainderValue == 0:
    dayCount = 2 * rootValue - 1
  elif remainderValue <= rootValue:
    dayCount = 2 * rootValue
  else:
    dayCount = 2 * rootValue + 1
  appendOutput($dayCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The search uses about thirty halving steps.
The remainder selects one of three day counts.
Each test writes one buffered line.

## Complexity

One square root and one comparison serve each test.

| phase | time | space |
|---|---|---|
| input read | one pass over T numbers | one input string |
| square root | about 30 comparisons per test | a few variables |
| output | one line per test | block buffer |

The square root bound is one billion.

| measure | Big O |
|---|---|
| time | O(T log 1000000000) |
| space | O(input bytes) |

Walking through days would cost O(sqrt N) per test and stall at large N.
The closed hill shape turns each test into a short binary search.
