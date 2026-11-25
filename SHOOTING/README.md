# SHOOTING — Emmons (SPOJ)

<https://www.spoj.com/problems/SHOOTING/>

## Problem

Every bullet must be fired once, and every target must receive at least one bullet. A target's counter starts at one and is multiplied by each bullet value it receives. The score is the sum of all target counters, and we want the highest possible score.

Input starts with the number of test cases. Each case gives `n m`, then n bullet values. Output one integer per case: the maximum final score.

| item | bound |
|---|---|
| bullets n | 1 to 2000 |
| targets m | 1 to n |
| bullet value | absolute value below 10000 |
| test cases | up to 50 |
| judge limit | 10000 ms, 1536 MB |

The value of `m` drives the search because it fixes the number of groups.

Sample input:

```
3
10 2
0 -1 -2 0 1 2 3 2 10 1
10 3
0 -1 -2 0 1 2 3 2 10 1
5 3
10 0 0 -1 -1
```

Sample output:

```
240
241
11
```

## Idea

Treat each target as a box that multiplies every bullet placed inside it, like stacking weights whose effects compound. We need to split all bullets into `m` boxes and choose the split with the largest summed product.

The algorithm is subset dynamic programming. For every subset of bullets it stores the best score for each possible number of boxes, then extends a subset by forming one new box at a time.

Enumerating all assignments directly would try `m^n` arrangements, which is far slower than the subset table.

## Why It Works

1. A complete play is a partition of the bullets into exactly `m` nonempty groups.
2. A group's contribution is the product of its bullet values.
3. Every partition has a first group; the remaining groups form a smaller independent subproblem.
4. A subset table records the best score for each subset and each group count.
5. Taking the maximum over all choices of the first group gives the optimal score by induction on subset size.

| term | meaning |
|---|---|
| `missingScore` | sentinel for an unreachable subset and group count |
| `groupMask` | bit pattern of bullets assigned to one target |
| `leftoverMask` | bullets still available for remaining targets |
| `groupProduct` | product of bullet values in one target |
| `bestScores` | table of best scores by subset and group count |

For the first sample, grouping both zeroes together scores zero. The other eight bullets multiply to 240, so the answer is 240.

## Code

**Input and scanner.** The scanner handles negative bullet values and builds one case at a time.

```nim
const flushBlockBytes = 1 shl 17
const missingScore = -(1 shl 60)

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value
```

The minus branch reads negative bullets.
All input arrives in one string before parsing.
Each case keeps its own value array.

**Subset dynamic program.** Each state chooses one group and combines it with a smaller state.

```nim
proc solveCase(values: seq[int64], targetGroups: int): int64 =
  let bulletCount = values.len
  let totalMasks = 1 shl bulletCount
  var bestScores = newSeq[seq[int64]](totalMasks)
  for maskIndex in 0 ..< totalMasks:
    bestScores[maskIndex] = newSeq[int64](targetGroups + 1)
    for groupCount in 0 .. targetGroups:
      bestScores[maskIndex][groupCount] = missingScore
  bestScores[0][0] = 0

  for maskIndex in 1 ..< totalMasks:
    var firstBit = 0
    while (maskIndex and (1 shl firstBit)) == 0:
      firstBit += 1
    let remainingMask = maskIndex and not (1 shl firstBit)
    var companion = remainingMask
    while true:
      let groupMask = companion or (1 shl firstBit)
      let leftoverMask = remainingMask and not companion
      var groupProduct: int64 = 1
      var bitIndex = 0
      while bitIndex < bulletCount:
        if (groupMask and (1 shl bitIndex)) != 0:
          groupProduct = groupProduct * values[bitIndex]
        bitIndex += 1
      for groupCount in 1 .. targetGroups:
        if bestScores[leftoverMask][groupCount - 1] == missingScore:
          continue
        let candidate = bestScores[leftoverMask][groupCount - 1] + groupProduct
        if candidate > bestScores[maskIndex][groupCount]:
          bestScores[maskIndex][groupCount] = candidate
      if companion == 0:
        break
      companion = (companion - 1) and remainingMask
  return bestScores[totalMasks - 1][targetGroups]
```

The lowest set bit anchors each first group.
Companion submasks enumerate every possible group.
Products and sums stay in int64 for the stated values.

**Driver.** One line of output is appended per case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let bulletCount = nextInt(inputData, scanPos)
  let targetGroups = nextInt(inputData, scanPos)
  var bulletValues = newSeq[int64](bulletCount)
  for bulletIndex in 0 .. bulletCount - 1:
    bulletValues[bulletIndex] = int64(nextInt(inputData, scanPos))
  appendOutput($solveCase(bulletValues, targetGroups))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case is solved independently.
The answer is written once per case.
The buffer flushes in blocks, then once at the end.

## Complexity

The table has one row per subset and one column per target count.

| phase | time | space |
|---|---|---|
| input read | one pass over bullets | one input string |
| subset table | three to the power of n transitions | two to the power of n rows |
| output | one line per case | block buffer |

The subset table dominates the running time.

| measure | Big O |
|---|---|
| time | O(3^n * m) |
| space | O(2^n * m) |

Direct enumeration of assignments would cost O(m^n) per case.
