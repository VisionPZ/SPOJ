# IOPC1205 — The magical escape (SPOJ)

<https://www.spoj.com/problems/IOPC1205/>

## Problem

Prisoners enter a room one at a time, and a shared bulb carries the only signal. Some prisoners are telepaths. Find the expected number of days until their shared counter reaches the prisoner count.

Input starts with the test count. Each case gives N and M, the prisoner count and the magician count. Output the expectation as one digit, a dot, six digits, `E+`, and two exponent digits.

| item | bound |
|---|---|
| test cases T | up to 100 |
| prisoners N | 1 to 10^9 |
| magicians M | 1 to min(100, N) |
| judge limit | 1000 ms, 1536 MB |

Let K be the number of non-magicians, so K = N−M. Let `H(K)` be the sum of 1/i from i = 1 to K.

Sample input:

```
2
100 10
1 1
```

Sample output:

```
1.408258E+03
1.000000E+00
```

## Idea

A non-magician waits for an off bulb, then turns it on once. A magician turns an on bulb off and increments the shared counter. Think of collecting K tokens from one queue and M names from another.

A difference-equation argument gives the expected continuous time as a harmonic part plus a small correction. Multiplying by N converts continuous time into days. The correction is a finite sum over at most 99 magician counts.

A state table handles short outsider queues, while a closed form handles long ones. The table stops at 100 magicians and 100 outsiders.

One short computation settles each case.

## Why It Works

1. In continuous time, each prisoner has an independent rate-one arrival process.
2. Days equal continuous time multiplied by N, since the total arrival rate is N.
3. With bulb off, either a fresh magician or a fresh non-magician changes the state.
4. With bulb on, only a magician changes the state; other visitors wait.
5. Starting with no magicians left, the expectation is H_K + K/M.
6. Adding unseen magicians produces the correction sum below.

| term | meaning |
|---|---|
| `H(K)` | harmonic number, the sum of 1/i from i=1 to K |
| `magicianCount` | M, the number of telepaths |
| `outsiderCount` | K = N−M, the number of other prisoners |
| `correction` | finite sum over signal indices |
| `offState` | expected time with an off bulb and given counts |
| `onState` | expected time with an on bulb and given counts |
| `expectedDays` | N times the continuous-time expectation |

The leading term H(K) + K/M dominates; the correction stays tiny.

For N = 100 and M = 10, K = 90. H(90) is about 5.0825706 and K/M is 9. The first correction term is 0.1 times (9/10)^90 divided by 91, which is tiny. The sum gives about 14.0825789. Multiplying by 100 gives 1408.25789, printed as 1.408258E+03.

The trace matches the sample.

## Code

**Input and scanner.** All input is read once and parsed by a hand scanner.

```nim
import math

const flushBlockBytes = 1 shl 17
const harmonicTableLimit = 100000

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

The table limit keeps harmonic lookups fast.

The scanner accepts any spacing inside the input.

**Output buffer and harmonic numbers.** A precomputed table covers small counts, and Euler–Maclaurin extends large ones.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var harmonicTable = newSeq[float](harmonicTableLimit + 1)
for indexValue in 1 .. harmonicTableLimit:
  harmonicTable[indexValue] = harmonicTable[indexValue - 1] + 1.0 / float(indexValue)

proc harmonicSum(value: int64): float =
  if value <= int64(harmonicTableLimit):
    return harmonicTable[int(value)]
  let largeValue = float(value)
  let tableValue = float(harmonicTableLimit)
  let correction = 1.0 / (2.0 * largeValue) - 1.0 / (2.0 * tableValue) -
    1.0 / (12.0 * largeValue * largeValue) + 1.0 / (12.0 * tableValue * tableValue)
  return harmonicTable[harmonicTableLimit] + ln(largeValue) - ln(tableValue) + correction
```

The table is built once before any test case.

The residual terms keep large harmonic values accurate.

**Small-gap states.** Few outsiders keep the state table small and avoid cancellation.

```nim
proc smallGapDays(prisonerCount: int64, magicianCount: int64, outsiderCount: int64): float =
  let rowLength = int(outsiderCount) + 1
  var offState = newSeq[float](int(magicianCount + 1) * rowLength)
  var onState = newSeq[float](int(magicianCount + 1) * rowLength)
  for magicians in 1 .. magicianCount:
    offState[int(magicians) * rowLength] = harmonicSum(magicians)
    onState[int(magicians) * rowLength] = offState[int(magicians) * rowLength]
  onState[0] = 1.0 / float(magicianCount)
  for outsiders in 1 .. outsiderCount:
    offState[int(outsiders)] = 1.0 / float(outsiders) + onState[int(outsiders - 1)]
    onState[int(outsiders)] = 1.0 / float(magicianCount) + offState[int(outsiders)]
  for magicians in 1 .. magicianCount:
    for outsiders in 1 .. outsiderCount:
      let stateIndex = int(magicians) * rowLength + int(outsiders)
      let previousIndex = int(magicians - 1) * rowLength + int(outsiders)
      offState[stateIndex] = (1.0 + float(magicians) * offState[previousIndex] +
        float(outsiders) * onState[stateIndex - 1]) /
        float(magicians + outsiders)
      onState[stateIndex] = (1.0 + float(magicians) * offState[previousIndex] +
        float(magicianCount - magicians) * offState[stateIndex]) /
        float(magicianCount)
  return float(prisonerCount) * offState[int(magicianCount) * rowLength + int(outsiderCount)]
```

A short outsider queue makes the table smaller than 10000 entries.

A large correction sum would lose digits, so states replace the formula here.

**Expectation formula.** With many outsiders, the correction sum uses binomial coefficients.

```nim
proc expectedDays(prisonerCount: int64, magicianCount: int64): float =
  let outsiderCount = prisonerCount - magicianCount
  if outsiderCount == 0:
    return float(prisonerCount) * harmonicSum(magicianCount)
  if outsiderCount <= magicianCount:
    return smallGapDays(prisonerCount, magicianCount, outsiderCount)
  var correction = 0.0
  var combination: float = 1.0
  var previousFactorial: float = 1.0
  for signalIndex in 1 .. magicianCount - 1:
    combination = combination * float(magicianCount - signalIndex + 1) /
      float(signalIndex)
    let ratio = float(magicianCount - signalIndex) / float(magicianCount)
    var term = combination * previousFactorial * pow(ratio, float(outsiderCount))
    var divisor = 1.0
    for offset in 1 .. signalIndex:
      divisor = divisor * float(outsiderCount + offset)
    term = term / divisor
    if (signalIndex mod 2) == 1:
      correction += term
    else:
      correction -= term
    previousFactorial = previousFactorial * float(signalIndex)
  let baseSum = harmonicSum(outsiderCount) + float(outsiderCount) /
    float(magicianCount)
  return float(prisonerCount) * (baseSum + correction)
```

All magicians being present removes the signal queue.

Coefficients alternate sign and stay finite in double precision.

**Scientific formatting.** The answer is written in the required one-plus-six form.

```nim
proc appendScientific(value: float) =
  var exponentValue = int(floor(ln(value) / ln(10.0)))
  var mantissa = value / pow(10.0, float(exponentValue))
  if mantissa >= 10.0:
    mantissa = mantissa / 10.0
    exponentValue += 1
  let scaledValue = int64(mantissa * 1000000.0 + 0.5)
  let wholePart = scaledValue div 1000000
  let fractionPart = scaledValue mod 1000000
  appendOutput($(wholePart))
  outputBuffer.add '.'
  if fractionPart < 10:
    outputBuffer.add '0'
  if fractionPart < 100:
    outputBuffer.add '0'
  if fractionPart < 1000:
    outputBuffer.add '0'
  if fractionPart < 10000:
    outputBuffer.add '0'
  if fractionPart < 100000:
    outputBuffer.add '0'
  appendOutput($(fractionPart))
  outputBuffer.add 'E'
  outputBuffer.add '+'
  if exponentValue < 10:
    outputBuffer.add '0'
  appendOutput($(exponentValue))
  outputBuffer.add '\n'

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let prisonerCount = int64(nextInt(inputData, scanPos))
  let magicianCount = int64(nextInt(inputData, scanPos))
  appendScientific(expectedDays(prisonerCount, magicianCount))

stdout.write outputBuffer
outputBuffer.setLen 0
```

Adding 0.5 before truncation gives the required rounding.

The exponent always has two digits because expectations stay above one.

## Complexity

Each case builds the harmonic table once globally, then evaluates at most 99 correction terms.

| phase | time | space |
|---|---|---|
| table build | O(10^5) additions once | harmonic table |
| expectation | O(M·min(K,M)) or O(M²) float work | O(M·min(K,M)) when K is small |
| output | one buffered write per block | block buffer |

The inner divisor loop makes the correction cost quadratic in M.

| measure | Big O |
|---|---|
| time per case | O(M²) |
| space per case | O(1) |

A full state table would need O(NM) states and fail at N = 10^9.

The hybrid keeps all cases within the limit.
