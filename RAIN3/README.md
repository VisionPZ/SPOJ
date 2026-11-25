# RAIN3 — Rain (SPOJ)

<https://www.spoj.com/problems/RAIN3/>

## Problem

Generate a rainfall sequence from two recurrences and report the longest stay whose every window of days sums to at most a given limit. Each input block supplies two seeds, a length, and the limit.

| item | bound |
|---|---|
| blocks | given by the first integer |
| sequence length N | 1 to 1500000 |
| all input integers | signed 32-bit range |
| judge limit | 500 ms, 1536 MB |

Every generated value is positive, so longer windows always have larger sums. This makes the first violating window length decide the answer.

Sample input:

```
1
123456 123456 10 10000
```

Sample output:

```
2
```

## Idea

Slide a window over the days and shrink it whenever the rain total exceeds the limit, like letting water drain from one end of a trough. The shortest violating window gives the answer directly: subtract one from its length. Each day enters and leaves the window once, so one pass per block replaces repeated searches.

## Why It Works

1. The recurrence produces a positive rainfall value for every day.
2. Positive values make window sums grow when the window grows.
3. If no window violates the limit, every stay of N days is safe.
4. The sliding window keeps the total for the shortest suffix ending at the current day.
5. When that total exceeds the limit, the current window is the shortest violation ending there.

The names below match the source identifiers.

| term | meaning |
|---|---|
| `windowTotal` | rainfall sum of the current window |
| `leftDay` | first day still inside the window |
| `shortestViolation` | smallest window length whose sum exceeds the limit |
| `safeDays` | reported answer, one less than that length |

The equalities reduce the search to one monotone scan.

The sample sequence and its first violation, produced by the oracle in gen.py:

| days | rainfall | window sum at days 6 to 8 |
|---|---|---|
| 6 | 4048 | 4048 |
| 7 | 990 | 5038 |
| 8 | 6935 | 11973 |

The sum 11973 exceeds 10000 at length 3, so the safe stay is 2 days.

## Code

**Input and recurrence constants.** The reader loads all blocks and parses signed integers.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const stateMultiplier = 31
const stateAddend = 78901
const stateModulus = 699037
const otherMultiplier = 64
const otherAddend = 23456
const otherModulus = 2097151
const dayModulus = 100

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

proc positiveModulo(dividend: int64, divisor: int64): int64 =
  let remainderValue = dividend mod divisor
  if remainderValue < 0:
    return remainderValue + divisor
  return remainderValue
```

Negative seeds are normalised to a non-negative residue.
The scanner accepts a minus sign before a number.
All recurrence arithmetic stays in int64.

**Sliding-window driver.** One pass generates values and tracks the shortest violation.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let blockCount = nextInt(inputData, scanPos)
for blockIndex in 0 ..< blockCount:
  let initialState = nextInt(inputData, scanPos)
  let initialOther = nextInt(inputData, scanPos)
  let dayCount = nextInt(inputData, scanPos)
  let allowedSum = int64(nextInt(inputData, scanPos))
  var stateValue = int64(initialState)
  var otherValue = int64(initialOther)
  var predictions = newSeq[int](dayCount)
  var leftDay = 0
  var windowTotal: int64 = 0
  var shortestViolation = dayCount + 1
  for rightDay in 0 ..< dayCount:
    stateValue = positiveModulo(stateAddend + stateMultiplier * stateValue, stateModulus)
    otherValue = positiveModulo(otherAddend + otherMultiplier * otherValue, otherModulus)
    let rainfall = int((stateValue mod dayModulus + 1) * (otherValue mod dayModulus + 1))
    predictions[rightDay] = rainfall
    windowTotal = windowTotal + int64(rainfall)
    while windowTotal > allowedSum:
      let violationLength = rightDay - leftDay + 1
      if violationLength < shortestViolation:
        shortestViolation = violationLength
      windowTotal = windowTotal - int64(predictions[leftDay])
      leftDay += 1
  var safeDays = dayCount
  if shortestViolation <= dayCount:
    safeDays = shortestViolation - 1
  appendOutput($safeDays)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each day enters the window once and leaves at most once.
A sentinel larger than N marks the case with no violation.
The buffer flushes in blocks rather than per answer.

## Complexity

Let N be the sequence length in one block.

| phase | time | space |
|---|---|---|
| sequence generation | one recurrence step per day | one stored value per day |
| window scan | one add and at most one remove per day | two indices and a total |
| output | one append per block | one block buffer |

The scan is linear because both window ends move forward only.

| measure | Big O |
|---|---|
| time per block | O(N) |
| space per block | O(N) |

Testing every stay length separately would cost O(N^2), while the sliding window finishes in one pass.
