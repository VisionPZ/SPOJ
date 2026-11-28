# BUILD — Building Beacons (SPOJ)

<https://www.spoj.com/problems/BUILD/>

## Problem

Pick stones to build towers of given prime heights so the summed stone strengths are as large as possible. Each stone has height 2^X and strength Y. A stone is a single instance and can be used once.

Input starts with T. Each case gives K, then K pairs X and Y, then N and N tower heights. Heights are decimal integers. Print the maximum strength sum, or Plan Failed! when the towers cannot be built.

| item | bound |
|---|---|
| test cases T | up to 11 |
| stones K | up to 977 |
| exponent X | 0 to 977 |
| strength Y | 1 to 977 |
| towers N | up to 97 |
| tower height H | below 10^281 |
| judge limit | 2158 ms, 1536 MB |

Heights are too large for machine integers, so they are read as decimal text.

Sample input:

```
1
2
2 3
0 4
1
5
```

Sample output:

```
7
```

## Idea

Treat every stone as one unit at its binary level, like stacking coins of equal denomination. Two units at one level combine into one unit at the next level. A tower needs one unit at each set bit of its height. The algorithm sweeps levels from low to high and keeps only the count of units carried upward. At each level it chooses how many stones to use, taking the highest strengths first. A full search over stone subsets would be exponential. Takeaway: carry units upward and spend them on tower bits.

## Why It Works

1. A tower of height H needs one unit of size 2^i for each bit i set in H.
2. Units come from stones at level i and from pairs of units carried from level i-1.
3. Units beyond the tower needs at level i must pair up, so their count is even.
4. At a fixed level, using the c highest strengths is best because all stones there have the same height.
5. The sweep state is the carry count, since any unit at a level can serve any tower that needs that bit.

| term | meaning |
|---|---|
| `requirements` | number of towers needing a unit at each bit |
| `highestLevel` | largest exponent among stones and tower bits |
| `prefixSums` | best strength total for using c stones at a level |
| `maxCarry` | largest number of units carried between levels |
| `currentBest` | best strength total for each incoming carry |

The table names the values used by the level sweep.

In the sample the tower height 5 has bits 0 and 2 set. The height-4 stone and the height-1 stone fill those bits, giving strength 3 + 4 = 7.

The sample answer 7 uses exactly the two available stones.

## Code

**Input and scanning.** Heights are read as digit text, while exponents and strengths are integers.

```nim
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

proc nextNumberText(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var text = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    text.add data[pos]
    pos += 1
  return text

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The text scanner reads large heights.
Stone data uses the integer scanner.
All answers go through one block buffer.

**Height bits and strengths.** Each tower height adds one need per set bit.

```nim
proc countHeightBits(heightText: string, requirements: var seq[int]): int =
  var digits = newSeq[int](heightText.len)
  for digitIndex in 0 .. heightText.len - 1:
    digits[digitIndex] = int(heightText[digitIndex]) - 48
  var firstDigit = 0
  var bitIndex = 0
  while firstDigit < digits.len:
    var remainder = 0
    for digitIndex in firstDigit .. digits.len - 1:
      let divided = remainder * 10 + digits[digitIndex]
      digits[digitIndex] = divided div 2
      remainder = divided mod 2
    requirements[bitIndex] += remainder
    while firstDigit < digits.len and digits[firstDigit] == 0:
      firstDigit += 1
    bitIndex += 1
  return bitIndex

proc sortValues(values: var seq[int]) =
  for rightIndex in 1 .. values.len - 1:
    let carriedValue = values[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and values[leftIndex] < carriedValue:
      values[leftIndex + 1] = values[leftIndex]
      leftIndex -= 1
    values[leftIndex + 1] = carriedValue
```

Decimal long division extracts bits from low to high.
Each set bit raises the need at that level by one.
Stones at one level are sorted by strength.

**Level sweep.** Each level spends units and carries the rest upward.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let stoneCount = nextInt(inputData, scanPos)
  var exponents = newSeq[int](stoneCount)
  var strengths = newSeq[int](stoneCount)
  var highestLevel = 0
  for stoneIndex in 0 .. stoneCount - 1:
    exponents[stoneIndex] = nextInt(inputData, scanPos)
    strengths[stoneIndex] = nextInt(inputData, scanPos)
    if exponents[stoneIndex] > highestLevel:
      highestLevel = exponents[stoneIndex]
  let towerCount = nextInt(inputData, scanPos)
  var requirements = newSeq[int](1200)
  for towerIndex in 0 .. towerCount - 1:
    let heightText = nextNumberText(inputData, scanPos)
    let bitCount = countHeightBits(heightText, requirements)
    if bitCount - 1 > highestLevel:
      highestLevel = bitCount - 1
  var valuesByLevel = newSeq[seq[int]](highestLevel + 1)
  for levelIndex in 0 .. highestLevel:
    valuesByLevel[levelIndex] = newSeq[int](0)
  for stoneIndex in 0 .. stoneCount - 1:
    valuesByLevel[exponents[stoneIndex]].add strengths[stoneIndex]
  var prefixSums = newSeq[seq[int]](highestLevel + 1)
  for levelIndex in 0 .. highestLevel:
    sortValues(valuesByLevel[levelIndex])
    prefixSums[levelIndex] = newSeq[int](valuesByLevel[levelIndex].len + 1)
    prefixSums[levelIndex][0] = 0
    for valueIndex in 0 .. valuesByLevel[levelIndex].len - 1:
      prefixSums[levelIndex][valueIndex + 1] = prefixSums[levelIndex][valueIndex] + valuesByLevel[levelIndex][valueIndex]
  let maxCarry = stoneCount + 2
  var currentBest = newSeq[int64](maxCarry + 1)
  var nextBest = newSeq[int64](maxCarry + 1)
  for carryValue in 0 .. maxCarry:
    currentBest[carryValue] = -1
    nextBest[carryValue] = -1
  currentBest[0] = 0
  for levelIndex in 0 .. highestLevel:
    for carryValue in 0 .. maxCarry:
      nextBest[carryValue] = -1
    let availableCount = valuesByLevel[levelIndex].len
    let neededCount = requirements[levelIndex]
    for carryValue in 0 .. maxCarry:
      if currentBest[carryValue] < 0:
        continue
      for usedCount in 0 .. availableCount:
        let totalUnits = carryValue + usedCount
        if totalUnits < neededCount:
          continue
        if (totalUnits - neededCount) mod 2 != 0:
          continue
        let nextCarry = (totalUnits - neededCount) div 2
        if nextCarry > maxCarry:
          continue
        let candidate = currentBest[carryValue] + int64(prefixSums[levelIndex][usedCount])
        if candidate > nextBest[nextCarry]:
          nextBest[nextCarry] = candidate
    for carryValue in 0 .. maxCarry:
      currentBest[carryValue] = nextBest[carryValue]
  if currentBest[0] < 0:
    appendOutput("Plan Failed!\n")
  else:
    appendOutput($currentBest[0])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Prefix sums give the strength of taking the best c stones.
Only even excess units move to the next level.
A negative best value means the plan fails.

## Complexity

The sweep visits each level once per possible carry.

| phase | time | space |
|---|---|---|
| input read | one pass over stones and heights | one input string |
| bit extraction | one decimal division per bit | one digit array |
| level sweep | levels times carries times stones at that level | two carry arrays |

Across all levels the inner stone loop touches each stone once per carry state.

| measure | Big O |
|---|---|
| time per case | O(L K^2) worst case |
| space per case | O(L + K) |

Trying every stone subset would cost O(2^K) time. The level sweep reduces the decision to a small carry state.
