# BNWNIM — Black and White Nim (SPOJ)

<https://www.spoj.com/problems/BNWNIM/>

## Problem

Rows of black and white beads are shuffled uniformly, then two players strip prefixes under a one-black-bead rule. Report the probability that the first player wins with optimal play, to six decimal places.

The first line holds the test count. Each case gives the row count N, one line of N black bead counts, then one line of N white bead counts. Each case produces one floating-point line with exactly six digits after the decimal point.

| item | bound |
|---|---|
| rows N | up to 50 |
| black beads per row | up to 100 |
| white beads per row | up to 100 |
| judge limit | 1000 ms, 1536 MB |

Black and white counts alone determine the answer, because each gap pattern is equally likely.

Sample input:

```
4
1
0
2
1
2
0
1
2
2
2
2 5
2 0
```

Sample output:

```
1.000000
0.000000
0.666667
0.666667
```

## Idea

Score each row as a Nim heap, then add the heaps with XOR, like combining piles in ordinary Nim. A row's score depends only on the white gaps around its black beads, so a short dynamic program counts how often each score appears. Those counts become probabilities, and a second dynamic program combines the rows. Enumerating every shuffled row would need binomial numbers far beyond any machine.

| step | cost |
|---|---|
| distribution for one row | O(black times white squared) |
| combine rows by XOR | O(rows times 128 times scores) |
| cache repeated row types | constant lookup |

The gap count keeps each row distribution small.

## Why It Works

1. A prefix with no black beads may have any length up to the leading white gap.
2. A prefix with one black bead must end at the first black bead, so only one such move exists.
3. If the remaining row has score g and the leading gap has L whites, the new score is L when L is below g and L plus one otherwise.
4. Shuffling the row is the same as choosing one nonnegative gap vector, and all such vectors are equally likely.
5. A position is losing when the XOR of all row scores is zero, so the win probability is one minus that mass.

| term | meaning |
|---|---|
| `rowDistribution` | probability of each score for one row type |
| `counts` | number of gap vectors reaching one score |
| `prefixSums` | running totals used for fast transition sums |
| `xorStateCount` | number of possible XOR values, 128 |

The table defines the arrays behind the two dynamic programs.

A script-generated trace for one row with one black bead and two white beads:

```
gap (0,2): score 0, probability 1/3
gap (1,1): score 2, probability 1/3
gap (2,0): score 3, probability 1/3
single row losing mass = 1/3
win probability = 2/3 = 0.666667
```

The trace matches the third sample case exactly.

## Code

**Hand scanner, output buffer and fixed-point formatting.** The reader loads all input; the formatter writes six decimal digits without locale effects.

```nim
const flushBlockBytes = 1 shl 17
const maxBeadCount = 100
const xorStateCount = 128
const decimalDigits = 6
const decimalScale = 1000000

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

proc appendProbability(probabilityValue: float) =
  var scaledValue = int(probabilityValue * float(decimalScale) + 0.5)
  if scaledValue < 0:
    scaledValue = 0
  if scaledValue > decimalScale:
    scaledValue = decimalScale
  let wholePart = scaledValue div decimalScale
  let fractionPart = scaledValue mod decimalScale
  appendOutput($wholePart)
  appendOutput(".")
  var divisorValue = decimalScale div 10
  for digitIndex in 0 .. decimalDigits - 1:
    appendOutput($((fractionPart div divisorValue) mod 10))
    divisorValue = divisorValue div 10
  outputBuffer.add '\n'
```

Rounding happens once on the scaled integer.
Clamping protects against tiny floating-point overshoot.
Digits are appended to the shared buffer, never to stdout.

**Row distribution.** Prefix and suffix sums collapse the gap transition to constant time per cell.

```nim
var distributionCache = newSeq[seq[float]]((maxBeadCount + 1) * (maxBeadCount + 1))

proc rowDistribution(blackCount: int, whiteCount: int): seq[float] =
  let cacheKey = blackCount * (maxBeadCount + 1) + whiteCount
  if distributionCache[cacheKey].len > 0:
    return distributionCache[cacheKey]
  let maxGrundy = whiteCount + 1
  let stride = maxGrundy + 1
  var counts = newSeq[float]((whiteCount + 1) * stride)
  for spareWhites in 0 .. whiteCount:
    counts[spareWhites * stride + spareWhites] = 1.0
  for gapIndex in 0 .. blackCount - 1:
    var prefixSums = newSeq[float]((whiteCount + 1) * stride)
    var suffixSums = newSeq[float]((whiteCount + 1) * stride)
    for spareWhites in 0 .. whiteCount:
      for grundyValue in 0 .. maxGrundy:
        let cellIndex = spareWhites * stride + grundyValue
        if grundyValue == 0:
          prefixSums[cellIndex] = counts[cellIndex]
        else:
          prefixSums[cellIndex] = prefixSums[cellIndex - 1] + counts[cellIndex]
      for grundyValue in countdown(maxGrundy, 0):
        let cellIndex = spareWhites * stride + grundyValue
        if grundyValue == maxGrundy:
          suffixSums[cellIndex] = counts[cellIndex]
        else:
          suffixSums[cellIndex] = suffixSums[cellIndex + 1] + counts[cellIndex]
    var nextCounts = newSeq[float]((whiteCount + 1) * stride)
    for totalWhites in 0 .. whiteCount:
      for resultGrundy in 0 .. maxGrundy:
        let resultIndex = totalWhites * stride + resultGrundy
        if resultGrundy < maxGrundy:
          let gapSize = resultGrundy
          if gapSize <= totalWhites:
            let sourceIndex = (totalWhites - gapSize) * stride + gapSize + 1
            nextCounts[resultIndex] = nextCounts[resultIndex] + suffixSums[sourceIndex]
        if resultGrundy > 0:
          let gapSize = resultGrundy - 1
          if gapSize <= totalWhites:
            let sourceIndex = (totalWhites - gapSize) * stride + gapSize
            nextCounts[resultIndex] = nextCounts[resultIndex] + prefixSums[sourceIndex]
    counts = nextCounts
  var probabilities = newSeq[float](stride)
  var totalCount = 0.0
  for grundyValue in 0 .. maxGrundy:
    probabilities[grundyValue] = counts[whiteCount * stride + grundyValue]
    totalCount = totalCount + probabilities[grundyValue]
  for grundyValue in 0 .. maxGrundy:
    probabilities[grundyValue] = probabilities[grundyValue] / totalCount
  distributionCache[cacheKey] = probabilities
  return probabilities
```

The last gap alone starts the score chain.
Each new gap reads summed counts instead of scanning all scores.
Dividing by the total turns gap counts into probabilities.

**XOR combination.** Rows are folded into a small distribution over XOR states.

```nim
proc solveCase(blackCounts: seq[int], whiteCounts: seq[int]): float =
  var combined = newSeq[float](xorStateCount)
  combined[0] = 1.0
  for rowIndex in 0 .. blackCounts.len - 1:
    let singleRow = rowDistribution(blackCounts[rowIndex], whiteCounts[rowIndex])
    var nextCombined = newSeq[float](xorStateCount)
    for stateValue in 0 .. xorStateCount - 1:
      if combined[stateValue] == 0.0:
        continue
      for grundyValue in 0 .. singleRow.len - 1:
        let nextState = stateValue xor grundyValue
        nextCombined[nextState] = nextCombined[nextState] + combined[stateValue] * singleRow[grundyValue]
    combined = nextCombined
  return 1.0 - combined[0]
```

The all-zero state starts with probability one.
Each row shifts mass by its own score.
The losing mass is the probability of ending at state zero.

**Case loop.** Black counts and white counts are read as separate lines and paired by row index.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  var blackCounts = newSeq[int](rowCount)
  var whiteCounts = newSeq[int](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    blackCounts[rowIndex] = nextInt(inputData, scanPos)
  for rowIndex in 0 .. rowCount - 1:
    whiteCounts[rowIndex] = nextInt(inputData, scanPos)
  let winProbability = solveCase(blackCounts, whiteCounts)
  appendProbability(winProbability)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scanner treats the two count lines as one token stream.
Repeated row types reuse the cached distribution.
A final flush writes any partial buffer.

## Complexity

Each distinct row type is solved once and reused across cases.

| phase | time | space |
|---|---|---|
| input read | one pass over bead counts | one input string |
| row distribution | black times white squared | white times score table |
| XOR combination | rows times 128 times score count | 128 probabilities |
| output | one write per block | block buffer |

The row distribution dominates when rows are large.

| measure | Big O |
|---|---|
| time | O(N times black times white squared) for distinct rows |
| space | O(white squared) per cached row type |

Enumerating all shuffled rows would take binomial time in the bead counts, so the gap dynamic program gives the practical bound.
