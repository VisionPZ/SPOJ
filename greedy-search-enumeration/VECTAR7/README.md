# VECTAR7 — Number of score sequences (SPOJ)

<https://www.spoj.com/problems/VECTAR7/>

## Problem

Two teams score one point at a time from 0:0. Count the scoring orders that end a volleyball game exactly at a given final score, modulo 1000000007.

A game ends when a team reaches 25 while the other has at most 23. At 24:24 play continues until one team leads by two points. Print 0 when the score cannot end a game.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | up to 15 |
| final scores A, B | 0 to 1000000000 |
| judge limit | 100 ms, 1536 MB |

The 24:24 rule drives the split into two counting cases.

Sample input:

```
2
3 25
24 17
```

Sample output:

```
2925
0
```

## Idea

A winning point closes the game, so all earlier points form an ordinary arrangement, like shuffling a row of win and loss tokens.

If the loser has at most 23 points, the winner's 24 earlier points and the loser's points can appear in any order before the last point. That gives one binomial coefficient. If both scores reached at least 24, the game passed through 24:24; from deuce each exchange can go either way, giving a power of two. A state-by-state count would need one step per point, while these formulas need one multiplication. Each query costs logarithmic time.

## Why It Works

1. In the first case no team can have reached 25 before the last point, since the loser is below 24.
2. The first 24 plus loser points contain 24 wins for the winner and loser points for the loser, so their order count is `combTable[24 + loser][loser]`.
3. Every deuce game passes through 24:24, which can be reached in `combTable[48][24]` ways.
4. After deuce the point difference must stay below two until the final point; from 24:24 each completed pair of points can go in two orders.
5. A final score of winner m and loser m minus two has m minus 24 such free pairs, hence a factor of two to that power.

The main terms:

| term | meaning |
|---|---|
| `combTable` | binomial coefficients modulo the prime |
| `loserScore` | lower of the two final scores in a deuce game |
| `powerBase` | running factor used for binary exponentiation |
| `answer` | sequence count for one query |

The two cases cover every legal ending and reject every illegal one.

A worked example from the oracle DP:

```
score 3:25  -> 24 B-points and 3 A-points before the last B-point
              C(27,3) = 2925 sequences
score 24:17  -> neither team reaches 25, deuce never starts
              sequences that end here = 0
score 27:25  -> C(48,24) * 2 = 603457371 * 2 mod 1000000007
              sequences = 206914735
```

The sample answers 2925 and 0 match the trace exactly.

## Code

**Binomial table.** Pascal's rule builds all needed coefficients modulo the prime.

```nim
const flushBlockBytes = 1 shl 17
const modValue = 1000000007
const maxScore = 49

var combTable: array[0 .. maxScore, array[0 .. maxScore, int]]
for totalScore in 0 .. maxScore:
  combTable[totalScore][0] = 1
  combTable[totalScore][totalScore] = 1
  for chosen in 1 .. totalScore - 1:
    combTable[totalScore][chosen] =
      (combTable[totalScore - 1][chosen - 1] + combTable[totalScore - 1][chosen]) mod modValue
```

The table covers totals up to 48, which is the largest case-one total.
Each entry is the sum of two earlier entries modulo the prime.
The deuce coefficient is the entry at 48 choose 24.

**Input and scanning.** All input lines enter one string, then the scanner walks pairs.

```nim
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

Scores fit in a signed int up to 1000000000.
The parser skips spaces and line breaks without special cases.
No minus branch is needed because scores are nonnegative.

**Output buffer.** Answers are collected before a single final write.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 131072 bytes.
Small test sets produce only the final flush.
The same path handles a large batch unchanged.

**Case selection.** Each score pair picks a binomial or a deuce power.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstScore = nextInt(inputData, scanPos)
  let secondScore = nextInt(inputData, scanPos)
  var answer = 0
  if firstScore == 25 and secondScore < 24:
    answer = combTable[24 + secondScore][secondScore]
  elif secondScore == 25 and firstScore < 24:
    answer = combTable[24 + firstScore][firstScore]
  elif firstScore >= 24 and secondScore >= 24 and
      (firstScore - secondScore == 2 or secondScore - firstScore == 2):
    var loserScore = firstScore
    if secondScore < firstScore:
      loserScore = secondScore
    var powerBase: int64 = 2
    var exponent = loserScore - 24
    var power: int64 = 1
    while exponent > 0:
      if (exponent and 1) == 1:
        power = power * powerBase mod modValue
      powerBase = powerBase * powerBase mod modValue
      exponent = exponent shr 1
    answer = int(int64(combTable[48][24]) * power mod modValue)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

An ending outside both cases keeps answer zero.
Binary exponentiation handles exponents up to a billion in logarithmic steps.
All products use int64 before the modulo reduction.

## Complexity

The table is built once and every query reads only precomputed values or a short exponentiation loop.

| phase | time | space |
|---|---|---|
| table build | 49 squared additions | 50 by 50 integers |
| input read | one pass over input bytes | one input string |
| query loop | up to 30 exponentiation steps | block buffer |

The table is tiny and independent of the number of queries.

The asymptotic bounds:

| measure | Big O |
|---|---|
| preprocessing | O(1) |
| time per query | O(log A) |
| space | O(1) besides input |

A point-by-point state count would need up to A plus B steps per query, while the closed form is logarithmic.
