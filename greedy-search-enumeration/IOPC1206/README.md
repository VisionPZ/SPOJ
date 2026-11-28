# IOPC1206 — Fair bases (SPOJ)

<https://www.spoj.com/problems/IOPC1206/>

## Problem

Sum the number of fair bases over every integer in a range [a, b]. A base K is fair for N when the padded base-K writings of 0 through N-1 all earn the same score. A digit's score is how often it appears in its position.

Input starts with T, the number of cases, where T ≤ 20. Each case gives a and b with 2 ≤ a ≤ b ≤ 10^12. Output one line per case with the sum of fairness factors over that range.

| item | bound |
|---|---|
| cases T | up to 20 |
| range endpoints a, b | 2 to 10^12 |
| judge limit | 1000 ms, 1536 MB |

The huge range makes per-integer checking impossible, so the answer comes from an aggregated count.

The sample case has two queries and two replies.

```
2
4 8
20 30
```

```
9
27
```

The first range has nine fair bases in total.

## Idea

The trick is to count base-power pairs instead of inspecting integers. That is like counting stack heights instead of every coin. Each pair contributes a simple range of multipliers.

The algorithm uses a prefix count F(X) over all integers up to X. It rewrites F(X) as a sum over bases and powers, with a floor-sum grouping for the first power and short loops for higher powers. Computing F(b) minus F(a-1) answers each case.

Aggregate once per endpoint, then subtract two prefix values.

## Why It Works

1. Write N in base K and let e be the last digit position of N-1.
2. If K^e divides N, every position below the top has a whole number of digit cycles, so each digit there appears equally often.
3. The top digits that occur all gain the same extra count, so every number has the same score.
4. If K^e does not divide N, some lower position favours small digits, and the scores differ.
5. Hence K is fair exactly when N equals m times K^e with e at least 1 and m from 1 to K-1.
6. For a fixed base and power, the count of multipliers up to X is the smaller of K-1 and floor(X / K^e).

| term | meaning |
|---|---|
| `fairnessPrefix` | total fair-base count over integers from 2 to the limit |
| `integerRoot` | largest integer whose power stays within the limit |
| `powerLimited` | a power that stops early once it passes the limit |
| `squareRoot` | split point between the two floor-sum forms |

The table gives a prefix count from integer roots and grouped quotients.

The generator counts fair bases directly for small N and cross-checks the prefix.

```
F(3) = 2
F(8) = 11
F(8) - F(3) = 9
```

The nine fair bases from N=4 through N=8 match the first sample answer.

## Code

**Input and helpers.** The reader loads all tokens, and two helpers bound integer powers.

```nim
const flushBlockBytes = 1 shl 17
const rootSearchHigh = 1000000

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

The scanner handles endpoints up to 10^12 in 64-bit `int`.

`appendOutput` is present for the shared program shape.

`powerLimited` stops multiplying once the product passes the limit.

**Root search.** Binary search finds each integer root without floating point.

```nim
proc powerLimited(baseValue: int64, exponentCount: int, limitValue: int64): int64 =
  result = 1
  for exponentIndex in 1 .. exponentCount:
    result = result * baseValue
    if result > limitValue:
      return result

proc integerRoot(targetValue: int64, exponentCount: int): int64 =
  var lowValue: int64 = 1
  var highValue: int64 = rootSearchHigh
  while lowValue <= highValue:
    let middleValue = (lowValue + highValue) div 2
    if powerLimited(middleValue, exponentCount, targetValue) <= targetValue:
      lowValue = middleValue + 1
    else:
      highValue = middleValue - 1
  return highValue
```

The early return keeps every intermediate product bounded.

Integer arithmetic avoids rounding at powers near 10^12.

The search upper bound covers the square root of the largest endpoint.

**Prefix count.** The first power uses floor-sum grouping, and higher powers use short loops.

```nim
proc fairnessPrefix(limitValue: int64): int64 =
  if limitValue < 2:
    return 0
  result = 0
  let squareRoot = integerRoot(limitValue, 2)
  result += squareRoot * (squareRoot - 1) div 2
  var baseValue = squareRoot + 1
  while baseValue <= limitValue:
    let quotient = limitValue div baseValue
    let lastBase = min(limitValue div quotient, limitValue)
    result += quotient * (lastBase - baseValue + 1)
    baseValue = lastBase + 1
  var exponentCount = 2
  while true:
    let maxBase = integerRoot(limitValue, exponentCount)
    if maxBase < 2:
      break
    let smallBase = integerRoot(limitValue, exponentCount + 1)
    if smallBase >= 2:
      result += smallBase * (smallBase - 1) div 2
    baseValue = smallBase + 1
    if baseValue < 2:
      baseValue = 2
    while baseValue <= maxBase:
      let powerValue = powerLimited(baseValue, exponentCount, limitValue)
      result += limitValue div powerValue
      baseValue += 1
    exponentCount += 1
```

Grouping jumps over equal quotients instead of visiting each base.

The small-base sum covers multipliers up to K-1 in one formula.

Higher powers stop when their integer root falls below two.

**Case answers.** Each case subtracts two prefix values.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rangeStart = int64(nextInt(inputData, scanPos))
  let rangeEnd = int64(nextInt(inputData, scanPos))
  let answer = fairnessPrefix(rangeEnd) - fairnessPrefix(rangeStart - 1)
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The lower endpoint uses a-1 so the range includes a.

Each answer fits in a 64-bit signed value.

## Complexity

Two prefix evaluations answer each case, with no per-integer work.

| phase | time | space |
|---|---|---|
| input read | one pass over 2T endpoints | one input string |
| first power | grouped quotients up to the square root | a few integers |
| higher powers | short base loops | a few integers |
| output | one line per case | one output block |

All phases use constant working space.

| measure | Big O |
|---|---|
| time | O(T * sqrt(b)) |
| space | O(1) excluding input |

Checking every integer and every base would cost O(range * b), so the prefix formula is the decisive gain.
