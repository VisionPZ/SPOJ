# PRLGAME2 — A Famous Game (SPOJ)

<https://www.spoj.com/problems/PRLGAME2/>

## Problem

A bag holds `N` balls, each red or blue. Every possible red count from 0 to `N` is equally likely before any ball is examined. After seeing `Q` red balls among `P` drawn balls, report the chance that the next ball is red.

Each line holds one test case with three integers `N`, `P`, `Q`. There is no count of test cases. Read lines until end of input. Print `Case k: ` followed by the probability rounded to four decimal places.

| item | bound |
|---|---|
| balls N | 2 to 100000 |
| drawn balls P | 0 to N-1 |
| red balls drawn Q | 0 to P |
| judge limit | 1000 ms, 1536 MB |

Extra whitespace is ignored by the judge, so one line per case is enough.

Sample input:

```
3 0 0
4 2 1
```

Sample output:

```
Case 1: 0.5000
Case 2: 0.5000
```

## Idea

Start from a uniform guess about the red count, then update that guess with the balls already seen, like revising a coin's bias after watching a few tosses.

Before any draw, each possible red count has the same weight. Seeing `Q` red balls in `P` draws multiplies each hypothesis by its hypergeometric likelihood. The posterior average of the next-ball chance simplifies to `(Q + 1)/(P + 2)`.

The value `N` cancels out of the result. Computing the posterior sum for every case would cost `O(N)` work. The closed form costs one multiplication, one addition and one division, then fixed-width formatting. Use integer arithmetic for the rounding, so no float error changes the last digit.

## Why It Works

1. Let `R` be the unknown number of red balls.
2. The prior gives every `R` from 0 to `N` equal weight.
3. Observing `Q` red balls in `P` draws gives hypothesis `R` weight proportional to `C(R, Q)C(N-R, P-Q)`.
4. Under hypothesis `R`, the next ball is red with chance `(R - Q)/(N - P)`.
5. Summing the weighted chances and dividing by the total weight gives `(Q + 1)/(P + 2)` by the beta-binomial identity.
6. The sample with `P = 0` returns `1/2`, because no observation shifts the uniform prior.

| term | meaning |
|---|---|
| `drawnCount` | value P, the number of examined balls |
| `redCount` | value Q, the red balls among those examined |
| `redDraws` | passed value `Q + 1` |
| `totalDraws` | passed value P |
| `scaledValue` | probability multiplied by 10000 and rounded |

The table connects each formula symbol to its program value.

A script-traced example for the first sample case:

| step | value |
|---|---|
| inputs | `N = 3`, `P = 0`, `Q = 0` |
| hypotheses | red counts 0, 1, 2, 3, each with weight 1/4 |
| next-red chances | `0`, `1/3`, `2/3`, `1` |
| average | `(0 + 1/3 + 2/3 + 1)/4 = 1/2` |
| closed form | `(0 + 1)/(0 + 2) = 1/2` |
| printed value | `Case 1: 0.5000` |

The trace agrees with the sample output.

Rounding uses `2 * numerator * 10000 + denominator` over `2 * denominator`, which rounds half upward. The whole and fractional digits come from one integer division, so the printed string always has exactly four decimal places.

## Code

**Shared input and output helpers.** The reader consumes stdin once and detects EOF by scanning for another digit.

```nim
const flushBlockBytes = 1 shl 17
const decimalPlaces = 10000

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

proc hasMoreTokens(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The EOF check skips all remaining whitespace.
The scanner accepts numbers on one line or many lines.
The block buffer avoids a system call for each case.

**Fixed-point formatting.** The probability becomes an integer scaled by 10000.

```nim
proc appendFixedProbability(redDraws: int64, totalDraws: int64) =
  let scaledValue = (2 * (redDraws + 1) * decimalPlaces + totalDraws + 2) div
                    (2 * (totalDraws + 2))
  let wholePart = scaledValue div decimalPlaces
  let fractionPart = scaledValue mod decimalPlaces
  appendOutput($wholePart)
  outputBuffer.add '.'
  var digitWeight: int64 = decimalPlaces div 10
  while digitWeight > 0:
    let digitValue = (fractionPart div digitWeight) mod 10
    outputBuffer.add chr(48 + int(digitValue))
    digitWeight = digitWeight div 10
```

The division rounds to the nearest scaled integer.
The four digits are written from the highest place to the lowest.
A carry to the whole part is handled by the first division.

**Case loop.** Each line produces one numbered answer.

```nim
var caseNumber = 1
while hasMoreTokens(inputData, scanPos):
  discard nextInt(inputData, scanPos)
  let drawnCount = int64(nextInt(inputData, scanPos))
  let redCount = int64(nextInt(inputData, scanPos))
  appendOutput("Case " & $caseNumber & ": ")
  appendFixedProbability(redCount, drawnCount)
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first value `N` is read and discarded.
The case counter starts at one and grows per input line.
The final flush writes the remaining buffered bytes.

## Complexity

Each case performs one exact rational computation in constant time.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| probability | one multiplication and one division | constant |
| output | one buffered write per block | one output string |

The phase table shows that `N` never affects the work per case.

| measure | Big O |
|---|---|
| time | O(lines of input) |
| space | O(input size) |

Summing posterior weights for every red count would cost O(N) per case; the closed form removes that loop.
