# DEXTER — Dexter Rank (SPOJ)

<https://www.spoj.com/problems/DEXTER/>

## Problem

Find Dexter's expected rank after system tests, given each coder's submitted problems and each problem's pass chance. Coders are ordered by solved count, then by total penalty. Equal records share a rank.

Input starts with the test count. Each case gives the coder count and problem count, then one penalty row per coder, then the pass percentages. A penalty of -1 means no submission. Output one expected rank with four decimals.

The bounds from the statement:

| item | bound |
|---|---|
| test cases | 1 to 16 |
| coders N | 2 to 256 |
| problems M | 1 to 12 |
| pass percentage | 0 to 100 |
| judge limit | 4000 ms, 1536 MB |

At most 12 problems keep each coder's outcome list small.

Sample input:

```
3
2 1
100
150
50
2 2
-1 -1
10 -1
0 100
3 2
100 200
-1 199
99 -1
50 50
```

Sample output:

```
1.2500
1.0000
1.6250
```

## Idea

Add the chance each rival beats Dexter the way you add separate tolls on a trip.

A rival beats Dexter on solved count, or on equal count with less penalty. Expected rank is one plus the sum of those chances. Each coder builds at most 2^M outcomes, one per pass pattern. Grouping outcomes by solved count lets a merge compare all penalties. Enumerating joint outcomes for every coder grows far faster.

Add rival chances one rival at a time.

## Why It Works

1. A rival beats Dexter on more solved problems.
2. With equal solved counts, a smaller penalty wins.
3. Equal records add nothing, because both coders share a rank.
4. Expected rank is one plus the sum of the beat chances.
5. Each submitted problem passes on its own, so one coder has at most 2^M outcomes.
6. A merge over sorted penalties compares every pair of outcomes in linear time.

The code uses these names:

| term | meaning |
|---|---|
| `passChance` | pass probability for one problem |
| `buildOutcomes` | builds all outcomes for one coder |
| `cumulativeChances` | prefix sums of outcome chances |
| `crossBetter` | same-count chance from lower penalties |
| `suffixGreater` | chance of a higher solved count |
| `expectedRank` | one plus all rival beat chances |

Each name covers one step of the calculation.

The first sample case traces as follows:

```
pass chance 0.50 for both submitted problems
Dexter fail (0, 0)    chance 0.50 -> rival better 0.50
Dexter pass (1, 100)  chance 0.50 -> rival better 0.00
beat chance = 0.50 * 0.50 + 0.50 * 0.00 = 0.25
expected rank = 1 + 0.25 = 1.2500
```

The expected rank matches the first sample output.

Percentages are divided by 100, and `formatFloat` writes four decimals.

## Code

**Input and scanning.** The reader loads the matrix and the pass percentages.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and ((data[pos] < '0' or data[pos] > '9') and data[pos] != '-'):
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextInt` reads the minus sign in penalty entries.
`appendOutput` waits for a full block before writing.
Token parsing ignores line breaks and spacing.

**Comparison helpers.** The helpers sort outcomes and compare penalties.

```nim
type
  ChancePair = object
    penaltyValue: int
    chanceValue: float64

proc sortPairs(pairs: var seq[ChancePair]) =
  for sortIndex in 1 ..< pairs.len:
    let currentPair = pairs[sortIndex]
    var compareIndex = sortIndex - 1
    while compareIndex >= 0 and pairs[compareIndex].penaltyValue > currentPair.penaltyValue:
      pairs[compareIndex + 1] = pairs[compareIndex]
      compareIndex = compareIndex - 1
    pairs[compareIndex + 1] = currentPair

proc cumulativeChances(pairs: seq[ChancePair]): seq[float64] =
  result = newSeq[float64](pairs.len)
  var runningChance = 0.0
  for pairIndex in 0 ..< pairs.len:
    runningChance = runningChance + pairs[pairIndex].chanceValue
    result[pairIndex] = runningChance

proc crossBetter(dexterPairs: seq[ChancePair], coderPairs: seq[ChancePair], coderCumulative: seq[float64]): float64 =
  var coderIndex = 0
  var accumulatedChance = 0.0
  for dexterPair in dexterPairs:
    while coderIndex < coderPairs.len and coderPairs[coderIndex].penaltyValue < dexterPair.penaltyValue:
      accumulatedChance = accumulatedChance + coderPairs[coderIndex].chanceValue
      coderIndex = coderIndex + 1
    result = result + dexterPair.chanceValue * accumulatedChance
```

`ChancePair` holds one penalty and its probability.
`sortPairs` orders entries by penalty with insertion sort.
`crossBetter` merges two sorted lists in one pass.

**Outcome build.** Each submitted pattern becomes one weighted outcome.

```nim
proc buildOutcomes(penaltyRow: seq[int], passChance: seq[float64]): tuple[groups: seq[seq[ChancePair]], scoreProb: seq[float64]] =
  let problemCount = penaltyRow.len
  var submittedIndex = newSeq[int](0)
  var submittedPenalty = newSeq[int](0)
  var submissionChance = newSeq[float64](0)
  var failureChance = newSeq[float64](0)
  for problemIndex in 0 ..< problemCount:
    if penaltyRow[problemIndex] >= 0:
      submittedIndex.add problemIndex
      submittedPenalty.add penaltyRow[problemIndex]
      submissionChance.add passChance[problemIndex]
      failureChance.add 1.0 - passChance[problemIndex]
  let submittedCount = submittedIndex.len
  result.groups = newSeq[seq[ChancePair]](problemCount + 1)
  result.scoreProb = newSeq[float64](problemCount + 1)
  for scoreIndex in 0 .. problemCount:
    result.groups[scoreIndex] = newSeq[ChancePair](0)
  let subsetLimit = 1 shl submittedCount
  for subsetMask in 0 ..< subsetLimit:
    var subsetChance = 1.0
    var solvedCount = 0
    var penaltySum = 0
    for submitIndex in 0 ..< submittedCount:
      if (subsetMask and (1 shl submitIndex)) != 0:
        subsetChance = subsetChance * submissionChance[submitIndex]
        solvedCount = solvedCount + 1
        penaltySum = penaltySum + submittedPenalty[submitIndex]
      else:
        subsetChance = subsetChance * failureChance[submitIndex]
    result.groups[solvedCount].add ChancePair(penaltyValue: penaltySum, chanceValue: subsetChance)
    result.scoreProb[solvedCount] = result.scoreProb[solvedCount] + subsetChance
  for scoreIndex in 0 .. problemCount:
    sortPairs(result.groups[scoreIndex])
```

Only entries with a penalty of -1 are skipped.
`scoreProb` sums chances for each solved count.
Every group is sorted before any comparison.

**Rank sum.** Each rival adds its chance of beating Dexter.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let coderCount = nextInt(inputData, scanPos)
  let problemCount = nextInt(inputData, scanPos)
  var penaltyMatrix = newSeq[seq[int]](coderCount)
  for coderIndex in 0 ..< coderCount:
    penaltyMatrix[coderIndex] = newSeq[int](problemCount)
    for problemIndex in 0 ..< problemCount:
      penaltyMatrix[coderIndex][problemIndex] = nextInt(inputData, scanPos)
  var passChance = newSeq[float64](problemCount)
  for problemIndex in 0 ..< problemCount:
    passChance[problemIndex] = float64(nextInt(inputData, scanPos)) / 100.0
  let dexterOutcome = buildOutcomes(penaltyMatrix[0], passChance)
  var expectedRank = 1.0
  for coderIndex in 1 ..< coderCount:
    let coderOutcome = buildOutcomes(penaltyMatrix[coderIndex], passChance)
    var cumulativeByScore = newSeq[seq[float64]](problemCount + 1)
    var suffixGreater = newSeq[float64](problemCount + 1)
    for scoreIndex in 0 .. problemCount:
      cumulativeByScore[scoreIndex] = cumulativeChances(coderOutcome.groups[scoreIndex])
    var scoreCursor = problemCount
    var runningHigher = 0.0
    while scoreCursor >= 0:
      suffixGreater[scoreCursor] = runningHigher
      runningHigher = runningHigher + coderOutcome.scoreProb[scoreCursor]
      scoreCursor = scoreCursor - 1
    var coderBetter = 0.0
    for dexterScore in 0 .. problemCount:
      let dexterScoreProbability = dexterOutcome.scoreProb[dexterScore]
      if dexterScoreProbability == 0.0:
        continue
      coderBetter = coderBetter + dexterScoreProbability * suffixGreater[dexterScore]
      coderBetter = coderBetter + crossBetter(dexterOutcome.groups[dexterScore], coderOutcome.groups[dexterScore], cumulativeByScore[dexterScore])
    expectedRank = expectedRank + coderBetter
  appendOutput(formatFloat(expectedRank, ffDecimal, 4))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`suffixGreater` holds the chance of a higher solved count.
`crossBetter` handles equal solved counts.
The final value is written with four decimals.

## Complexity

Each case builds outcome lists for every coder, then compares each rival with Dexter.

| phase | time | space |
|---|---|---|
| input read | one pass over the matrix | one input string |
| outcome build | N lists of up to 2^M entries | grouped outcomes |
| rank sum | one merge per rival and score | score chance arrays |
| output | one line per case | block buffer |

The phase table shows work driven by 2^M outcomes per coder.

| measure | Big O |
|---|---|
| time | O(T * N * 2^M) |
| space | O(N * 2^M) |

Enumerating every joint outcome for all coders grows as 2 raised to N times M.
