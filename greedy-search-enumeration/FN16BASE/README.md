# FN16BASE — Forever Young (SPOJ)

<https://www.spoj.com/problems/FN16BASE/>

## Problem

Write an age `y` in a base `b` so that every digit stays between 0 and 9. Read those digits as a decimal number, and require that number to be at least `l`. Report the largest base `b` that satisfies both rules.

Each test case is one line with the two decimal integers `y` and `l`. The value `y` runs from 10 to 10^18, and `l` runs from 10 to `y`. Several lines follow until end of file, and each line produces one answer.

| item | bound |
|---|---|
| age y | 10 to 10^18 |
| lower bound l | 10 to y |
| test cases | until end of file |
| judge limit | 4000 ms, 1536 MB |

Base 10 always works because the decimal reading of `y` equals `y`, which is at least `l`.

Sample input:

```
32 20
2016 100
```

Sample output:

```
16
42
```

## Idea

Think of a car odometer: a larger base uses fewer wheels, and fewer wheels show a smaller number. A base above one million gives at most three digits, so checking a small window of bases settles the hard cases. For smaller bases, binary search finds the largest base whose evaluation of `l` still fits inside `y`, then a downward scan finds the first base with decimal digits only. When that bound is huge, scan bases up to one million and test small target decimal values separately. Short takeaway: bound the search first, then verify digits.

## Why It Works

1. Interpreting a decimal number `D` in base `b` gives a value that grows with `D`.
2. A valid answer has decimal reading `D` at least `l`, so evaluating `l` in base `b` cannot exceed `y`.
3. Binary search therefore returns an upper bound on every valid base.
4. A base with four or more digits satisfies `b^3` at most `y`, so such a base is below 10^6.
5. For a two-digit reading `10h + u`, the base is `(y - u) / h` whenever the division is exact.
6. For a three-digit reading `100h + 10t + u`, the base solves `h b^2 + t b + u = y`.

| term | meaning |
|---|---|
| `searchBound` | largest base where evaluating `l` stays within `y` |
| `evalDecimalInBase` | value of decimal digits when read in a chosen base |
| `worksInBase` | test that every base-b digit of `y` is at most 9 |
| `baseForDecimalValue` | base recovered from a known two- or three-digit reading |
| `bestBase` | largest valid base found so far |

For `y = 32` and `l = 20`, a two-digit reading needs `20h + u` at least 20. With `h = 2` and `u = 0`, the division `(32 - 0) / 2` gives base 16. The digits of 32 in base 16 are 2 and 0, and their decimal reading is 20. Any base above 16 leaves a first digit larger than 9.

Overflow guards stop evaluation once an intermediate value exceeds 10^18. Square roots use integer binary search, so no floating point rounding enters the three-digit test.

## Code

**Input and scanning.** The scanner reads decimal ages and bounds as 64-bit values.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false
```

The hand reader builds each number one digit at a time.
The 64-bit accumulator holds ages up to 10^18.
The token check stops after the final input line.

**Digit tests.** These helpers evaluate decimal readings and recover bases from short readings.

```nim
proc evalDecimalInBase(decimalValue: int64, base: int64): int64 =
  var remaining = decimalValue
  var place: int64 = 1
  result = 0
  while remaining > 0:
    let digit = remaining mod 10
    if digit > 0 and place > high(int64) div digit:
      return high(int64)
    let part = digit * place
    if result > high(int64) - part:
      return high(int64)
    result += part
    if remaining >= 10:
      if place > high(int64) div base:
        return high(int64)
      place *= base
    remaining = remaining div 10
  return result

proc worksInBase(age: int64, base: int64): bool =
  var remaining = age
  while remaining > 0:
    let digit = remaining mod base
    if digit >= 10:
      return false
    remaining = remaining div base
  return true

proc integerSquareRoot(value: int64): int64 =
  var low: int64 = 0
  var highValue: int64 = 1000000001
  while low < highValue - 1:
    let middle = (low + highValue) div 2
    if middle * middle > value:
      highValue = middle
    else:
      low = middle
  return low
```

Evaluation stops early on overflow and returns a value larger than any age.
Digit extraction stops at the first digit above nine.
The square root uses integer division only.

**Short readings.** The code recovers a base from a two- or three-digit decimal reading.

```nim
proc baseForDecimalValue(age: int64, decimalValue: int64): int64 =
  let unitDigit = decimalValue mod 10
  if decimalValue < 100:
    let tensDigit = decimalValue div 10
    if tensDigit == 0:
      return -1
    if (age - unitDigit) mod tensDigit == 0:
      let candidate = (age - unitDigit) div tensDigit
      if candidate > tensDigit and candidate > unitDigit:
        return candidate
    return -1
  let tensDigit = (decimalValue div 10) mod 10
  let hundredsDigit = decimalValue div 100
  var low: int64 = 10
  var highValue = integerSquareRoot(age div hundredsDigit)
  while low < highValue - 1:
    let middle = (low + highValue) div 2
    let guess = hundredsDigit * middle * middle + tensDigit * middle + unitDigit
    if guess > age:
      highValue = middle - 1
    elif guess == age:
      return middle
    else:
      low = middle
  let lowGuess = hundredsDigit * low * low + tensDigit * low + unitDigit
  if lowGuess == age:
    return low
  let highGuess = hundredsDigit * (low + 1) * (low + 1) + tensDigit * (low + 1) + unitDigit
  if highGuess == age:
    return low + 1
  return -1

proc upperSearchBound(age: int64, lower: int64): int64 =
  var low: int64 = 10
  var highValue = age
  while low < highValue - 1:
    let middle = (low + highValue) div 2
    if evalDecimalInBase(lower, middle) > age:
      highValue = middle - 1
    else:
      low = middle
  if evalDecimalInBase(lower, low + 1) <= age:
    return low + 1
  return low
```

Two-digit bases come from an exact division.
Three-digit bases come from a binary search on the quadratic.
The upper bound keeps every later scan as short as possible.

**Search and output.** The driver chooses between a downward scan and a bounded scan.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextToken(inputData, scanPos):
  let age = nextInt64(inputData, scanPos)
  let lower = nextInt64(inputData, scanPos)
  let searchBound = upperSearchBound(age, lower)
  var bestBase: int64 = 10
  if searchBound < 1000000:
    var candidate = searchBound
    while candidate >= 2:
      if worksInBase(age, candidate):
        bestBase = candidate
        break
      candidate -= 1
  else:
    for tryBase in 11 .. 1000000:
      if worksInBase(age, int64(tryBase)):
        bestBase = int64(tryBase)
    var testDecimal = lower
    while testDecimal < 1000:
      let candidate = baseForDecimalValue(age, testDecimal)
      if candidate >= 10:
        if candidate > bestBase:
          bestBase = candidate
        break
      testDecimal += 1
  appendOutput($bestBase)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A small bound allows a scan down from that bound.
A large bound splits the work into a million-base scan and short readings.
Each test case writes one line through the shared buffer.

## Complexity

The search bound is found in logarithmic time, and the scans stay bounded by one million.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| upper bound | O(log y) evaluations | constant |
| bounded scan | at most 10^6 digit tests | constant |
| output | one line per test case | block buffer |

| measure | Big O |
|---|---|
| time per test case | O(10^6 * log y) worst case |
| space | O(1) |

Trying every base up to `y` would need 10^18 steps for the largest ages. The bound and the short-reading split replace that with a fixed million-step scan. Short takeaway: bound first, then test only candidate bases.
