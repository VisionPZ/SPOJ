# IITWPC4J — Gopu and Fishes (SPOJ)
<https://www.spoj.com/problems/IITWPC4J/>

## Problem

Each fish jumps to an aquarium with its own probability, and two fish cannot share one aquarium. Report the chance that every fish lands in a different aquarium.

The first line holds T. Each case starts with n, then n lines of n decimal probabilities.
Print one probability per case with six digits after the decimal point; the error must stay within 1e-6.

The bounds are:

| item | bound |
|---|---|
| test cases T | 1 to 1000 |
| fish n | 1 to 15 |
| probability precision | six decimal digits |
| judge limit | 1000 ms, 1536 MB |

The fish count allows one state per subset of aquariums.

Sample input:

```
2
2
1 0
0 1
2
0.5 0.5
0.5 0.5
```

The first case sends each fish to one fixed aquarium.

Sample output:

```
1.000000
0.500000
```

The second case has two equally likely safe assignments.

## Idea

Think of seating fish one at a time, with a checklist marking every aquarium already taken.

Use subset DP over occupied aquariums. A mask records the taken aquariums, and its set-bit count tells which fish moves next. Multiply by that fish's jump probability and add the result to the next mask. Enumerating assignments repeats shared prefixes, while the DP stores each prefix once.

One sweep over masks builds the answer.

## Why It Works

1. A set bit in a mask marks an occupied aquarium.
2. The number of set bits equals the number of fish already placed.
3. Only an empty aquarium can receive the next fish.
4. Independent jumps multiply their probabilities.
5. Outcomes with different assignments add their probabilities.
6. The full mask collects every safe assignment.

The main names are:

| term | meaning |
|---|---|
| `moveProbabilities` | jump probability for each fish and aquarium |
| `dynamicProbability` | probability of reaching each mask |
| `populatedBits` | set-bit count of each mask |
| `bitPositions` | aquarium index of each single-bit mask |
| `remainingAquariums` | aquariums still empty for one mask |

The arrays keep the DP pass compact.

The generator produced these states for the second sample case:

| mask | fish placed | probability | next action |
|---|---|---|---|
| 00 | 0 | 1.000000 | fish 0 takes 0 or 1 |
| 01 | 1 | 0.500000 | fish 1 takes 1 |
| 10 | 1 | 0.500000 | fish 1 takes 0 |
| 11 | 2 | 0.500000 | answer |

Both safe assignments add to 0.500000.

The scanner `nextReal` reads decimals without locale rules. Formatting with `formatFloat(dynamicProbability[stateCount - 1], ffDecimal, 6)` fixes six digits.

## Code

**Input and output helpers.** The integer scanner reads sizes, and a second scanner reads decimal probabilities.

```nim
import strutils

const flushBlockBytes = 1 shl 17

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

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and data[pos] != '.' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var scale = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      value = value + scale * float64(int(data[pos]) - 48)
      scale = scale * 0.1
      pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

```

`nextReal` builds the whole part and then the fractional digits.
The block buffer holds result lines until it reaches its limit.
All input is read before any case is solved.

**Subset sweep.** Each mask sends probability to every still-empty aquarium.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let fishCount = nextInt(inputData, scanPos)
  var moveProbabilities = newSeq[float64](fishCount * fishCount)
  for rowIndex in 0 .. fishCount - 1:
    for columnIndex in 0 .. fishCount - 1:
      moveProbabilities[rowIndex * fishCount + columnIndex] = nextReal(inputData, scanPos)
  let stateCount = 1 shl fishCount
  var dynamicProbability = newSeq[float64](stateCount)
  var populatedBits = newSeq[int](stateCount)
  var bitPositions = newSeq[int](stateCount)
  for aquariumIndex in 0 .. fishCount - 1:
    bitPositions[1 shl aquariumIndex] = aquariumIndex
  dynamicProbability[0] = 1.0
  for maskValue in 1 .. stateCount - 1:
    populatedBits[maskValue] = populatedBits[maskValue shr 1] + (maskValue and 1)
  let fullMask = stateCount - 1
  for maskValue in 0 .. fullMask:
    let currentProbability = dynamicProbability[maskValue]
    if currentProbability == 0.0:
      continue
    let fishIndex = populatedBits[maskValue]
    let rowStart = fishIndex * fishCount
    var remainingAquariums = fullMask xor maskValue
    while remainingAquariums != 0:
      let aquariumBit = remainingAquariums and (-remainingAquariums)
      let aquariumIndex = bitPositions[aquariumBit]
      let nextMask = maskValue or aquariumBit
      dynamicProbability[nextMask] = dynamicProbability[nextMask] + currentProbability * moveProbabilities[rowStart + aquariumIndex]
      remainingAquariums = remainingAquariums xor aquariumBit
  appendOutput(formatFloat(dynamicProbability[stateCount - 1], ffDecimal, 6))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

```

`populatedBits` selects the row of jump probabilities.
Low bits are removed from `remainingAquariums` one at a time.
The full mask holds the final probability.

## Complexity

The work splits into phases:

| phase | time | space |
|---|---|---|
| input read | one pass over n squared probabilities | one input string |
| bit tables | one step per mask | two mask-sized arrays |
| subset sweep | up to n updates per mask | one probability array |
| output | one formatted line per case | block buffer |

The subset sweep dominates the work.

The asymptotic costs are:

| measure | Big O |
|---|---|
| time | O(T times n times 2 to the n) |
| space | O(2 to the n) |

Listing all assignments would take factorial time per case.

The DP merges assignments that share the same occupied set.
