# BOILING — Boiling Vegetables (SPOJ)

<https://www.spoj.com/problems/BOILING/>

## Problem

Cut vegetable pieces until the smallest piece divided by the largest piece exceeds T. Each cut splits one piece into two pieces of any positive weights. Find the fewest cuts.

| item | bound |
|---|---|
| threshold T | 0.5 < T < 1, two decimals |
| pieces N | 1 to 1000 |
| weight wi | positive, below 1000000 |
| answer | below 500 |
| judge limit | 1000 ms, 1536 MB |

The threshold has two decimals, so store it as hundredths. The answer stays the same for T and T + 0.0001.

Sample input:

```
0.99 3
2000 3000 4000
```

Sample output:

```
6
```

## Idea

Pick the largest final piece M, like choosing the tallest jar that every vegetable must fit under. Each original piece of weight w becomes enough parts that no part exceeds M. It also needs room for every part to stay above T × M.

Try every candidate M = w/k, where w is an original weight and k is a small part count. Integer divisions decide both bounds exactly, so no floating point is needed. Keep the smallest cut count that works.

## Why It Works

1. Let M be the largest final piece, so every final piece lies in (T × M, M].
2. Splitting weight w into k equal parts gives each part size w/k.
3. That split fits when k × T × M < w and w ≤ k × M.
4. Write T as t/100 and M as pivotWeight/pieceTarget.
5. The lower bound is ceil(k × w / pivotWeight).
6. The upper bound is floor((100 × k × w − 1) / (t × pivotWeight)).
7. An optimum exists with M equal to w/k for some original piece and k ≤ 500.
8. Checking all such candidates finds the minimum total cuts.

| term | meaning |
|---|---|
| thresholdHundredths | t, the threshold times one hundred |
| pivotWeight | original weight defining a candidate M |
| pieceTarget | number of equal parts of the pivot weight |
| fewestPieces | least parts needed for one original weight |
| mostPieces | greatest parts still above T × M |

For T = 0.80 and weights 1000, 1400, the candidate M = 500 works. The first weight needs 2 parts, the second needs 3, so the answer is (2 − 1) + (3 − 1) = 3.

## Code

**Input and scanning.** The reader parses the decimal threshold, the piece count, and the weights.

```nim
const flushBlockBytes = 1 shl 17
const maximumCuts = 500

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

proc nextThreshold(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - 48
    pos += 1
  var fractionPart = 0
  var fractionDigits = 0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9' and fractionDigits < 2:
      fractionPart = fractionPart * 10 + int(data[pos]) - 48
      pos += 1
      fractionDigits += 1
  while fractionDigits < 2:
    fractionPart = fractionPart * 10
    fractionDigits += 1
  return wholePart * 100 + fractionPart

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The threshold reader pads one decimal digit with a trailing zero.
Integer arithmetic keeps every comparison exact.

**Candidate scan.** Each pivot and part count prices all original pieces.

```nim
let thresholdHundredths = nextThreshold(inputData, scanPos)
let pieceCount = nextInt(inputData, scanPos)
var pieceWeights = newSeq[int](pieceCount)
for pieceIndex in 0 .. pieceCount - 1:
  pieceWeights[pieceIndex] = nextInt(inputData, scanPos)
var bestCuts = maximumCuts
for pivotIndex in 0 .. pieceCount - 1:
  let pivotWeight = pieceWeights[pivotIndex]
  for pieceTarget in 1 .. maximumCuts:
    var requiredCuts: int64 = 0
    var feasible = true
    for otherIndex in 0 .. pieceCount - 1:
      let otherWeight = pieceWeights[otherIndex]
      let fewestPieces = (int64(pieceTarget) * int64(otherWeight) + int64(pivotWeight) - 1) div int64(pivotWeight)
      let mostPieces = (100 * int64(pieceTarget) * int64(otherWeight) - 1) div (int64(thresholdHundredths) * int64(pivotWeight))
      if fewestPieces > mostPieces:
        feasible = false
        break
      requiredCuts = requiredCuts + fewestPieces - 1
      if requiredCuts >= int64(bestCuts):
        break
    if feasible and requiredCuts < int64(bestCuts):
      bestCuts = int(requiredCuts)
appendOutput($bestCuts)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Ceiling division adds the pivot weight minus one before dividing.
The upper bound subtracts one before dividing to keep the strict inequality.
Candidates already worse than the best answer stop early.

## Complexity

The double loop over pivots and part counts dominates.

| phase | time | space |
|---|---|---|
| input read | one pass over N weights | one input string |
| candidate scan | at most N times 500 times N | array of weights |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(N² × 500) worst case |
| space | O(N) |

Simulating every cut sequence would explore far more states than these integer bounds.

The strict bounds and the small candidate set give the exact answer.
