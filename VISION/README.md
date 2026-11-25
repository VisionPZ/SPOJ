# VISION — Vision Field (SPOJ)

<https://www.spoj.com/problems/VISION/>

## Problem

An observer stands at point `(0, h)` and looks at buildings standing at positions 1 through N with top heights A1 through AN. Count how many building tops are visible, meaning the slope to that top beats every slope to an earlier top.

Input gives N, then N heights, then M, then M query heights. Print one visible count per query. Heights and query heights are positive integers at most 1000000000.

| item | bound |
|---|---|
| buildings N | at most 1000000 |
| queries M | at most 1000000 |
| building height | 1 to 1000000000 |
| query height | 1 to 1000000000 |
| judge limit | 305 ms, 1536 MB |

The sample from the statement:

```
5
2 3 3 3 4
3
3
2
4
```

```
3
2
5
```

## Idea

Each building becomes a line whose value is its slope from the observer, like adjusting a telescope dial as the observer rises. A newer building is visible exactly when its slope exceeds every earlier slope at that height. That happens above one threshold height per building, so the answer is a count of thresholds below the query height.

The algorithm keeps the upper envelope of slope lines with a convex hull, deriving one threshold per building in amortized constant time. It sorts the thresholds and answers each query by binary search in `O(log N)`. Testing every building for every query would cost `O(NM)` and cannot meet the limit.

## Why It Works

1. The slope from `(0, h)` to building `i` is `(Ai - h) / i`.
2. Newer buildings have larger slope coefficients, so building `j` beats building `i` only when `h` exceeds `(j*Ai - i*Aj) / (j - i)`.
3. Building `j` is visible precisely when its slope beats all earlier slopes, which happens above the largest such intersection.
4. The upper hull keeps only buildings that can set a new record; a new line pops the last line once its intersection falls before the last hull breakpoint.
5. Because query heights are integers, comparing the floored threshold with the height gives the same strict visible test.

| term | meaning |
|---|---|
| `visibilityThreshold` | largest height at which a building stops being visible |
| `hullBuildings` | building indexes that form the current upper hull |
| `hullNumerators` | numerator of each hull breakpoint |
| `hullDenominators` | denominator of each hull breakpoint |
| `compareFractions` | exact signed comparison of two breakpoints |
| `countBelow` | binary search for thresholds under a query height |

The table names the hull arrays and the two comparison helpers.

A script trace of the sample follows.

| building | threshold | visible at height 3 | visible at height 4 |
|---|---|---|---|
| 1 | always | yes | yes |
| 2 | 1 | yes | yes |
| 3 | 3 | no | yes |
| 4 | 3 | no | yes |
| 5 | 2 | yes | yes |

The visible counts are 3, 2, and 5 for query heights 3, 2, and 4, matching the sample output.

## Code

**Exact fraction helpers.** Products of slopes and heights need more than 64 bits, so the code compares 128-bit products built from 32-bit limbs.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const neverVisible = -(1 shl 60)

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

proc multiplyPositive(firstValue: int64, secondValue: int64): tuple[highPart: int64, lowPart: uint64] =
  let firstLow = uint64(firstValue) and 0xffffffff'u64
  let firstHigh = uint64(firstValue) shr 32
  let secondLow = uint64(secondValue) and 0xffffffff'u64
  let secondHigh = uint64(secondValue) shr 32
  let bottom = firstLow * secondLow
  let crossOne = firstLow * secondHigh
  let crossTwo = firstHigh * secondLow
  let middle = (bottom shr 32) + (crossOne and 0xffffffff'u64) + (crossTwo and 0xffffffff'u64)
  result.lowPart = (bottom and 0xffffffff'u64) or (middle shl 32)
  result.highPart = int64(firstHigh * secondHigh + (crossOne shr 32) +
                          (crossTwo shr 32) + (middle shr 32))

proc compareFractions(firstNumerator: int64, firstDenominator: int64,
                      secondNumerator: int64, secondDenominator: int64): int =
  let firstNegative = firstNumerator < 0
  let secondNegative = secondNumerator < 0
  if firstNegative != secondNegative:
    if firstNegative:
      return -1
    return 1
  let firstMagnitude = if firstNegative: -firstNumerator else: firstNumerator
  let secondMagnitude = if secondNegative: -secondNumerator else: secondNumerator
  let leftProduct = multiplyPositive(firstMagnitude, secondDenominator)
  let rightProduct = multiplyPositive(secondMagnitude, firstDenominator)
  var magnitude = 0
  if leftProduct.highPart > rightProduct.highPart:
    magnitude = 1
  elif leftProduct.highPart < rightProduct.highPart:
    magnitude = -1
  elif leftProduct.lowPart > rightProduct.lowPart:
    magnitude = 1
  elif leftProduct.lowPart < rightProduct.lowPart:
    magnitude = -1
  if firstNegative:
    return -magnitude
  return magnitude
```

Limb multiplication keeps every cross product exact.
Negative numerators are compared by magnitude and sign.
Denominators are always positive because building indexes grow.

**Hull construction.** Each building either extends the upper hull or replaces obsolete lines.

```nim
proc floorDivide(numerator: int64, denominator: int64): int64 =
  if numerator >= 0:
    return numerator div denominator
  return -((-numerator + denominator - 1) div denominator)

proc compareThresholds(firstValue: int64, secondValue: int64): int =
  if firstValue < secondValue:
    return -1
  if firstValue > secondValue:
    return 1
  return 0

proc countBelow(values: seq[int64], target: int64): int =
  var lowBound = 0
  var highBound = values.len
  while lowBound < highBound:
    let middle = (lowBound + highBound) div 2
    if values[middle] < target:
      lowBound = middle + 1
    else:
      highBound = middle
  return lowBound

let buildingCount = nextInt(inputData, scanPos)
var buildingHeights = newSeq[int](buildingCount)
for buildingIndex in 0 .. buildingCount - 1:
  buildingHeights[buildingIndex] = nextInt(inputData, scanPos)

var visibilityThreshold = newSeq[int64](buildingCount)
var hullBuildings: seq[int] = @[]
var hullNumerators: seq[int64] = @[]
var hullDenominators: seq[int64] = @[]

for currentBuilding in 0 .. buildingCount - 1:
  var placed = false
  while hullBuildings.len > 0:
    let lastBuilding = hullBuildings[hullBuildings.len - 1]
    let lastPosition = int64(lastBuilding + 1)
    let lastHeight = int64(buildingHeights[lastBuilding])
    let currentPosition = int64(currentBuilding + 1)
    let currentHeight = int64(buildingHeights[currentBuilding])
    let crossNumerator = currentPosition * lastHeight - lastPosition * currentHeight
    let crossDenominator = currentPosition - lastPosition
    if hullBuildings.len >= 2:
      let previousNumerator = hullNumerators[hullNumerators.len - 1]
      let previousDenominator = hullDenominators[hullDenominators.len - 1]
      if compareFractions(crossNumerator, crossDenominator,
                          previousNumerator, previousDenominator) <= 0:
        hullBuildings.setLen(hullBuildings.len - 1)
        hullNumerators.setLen(hullNumerators.len - 1)
        hullDenominators.setLen(hullDenominators.len - 1)
        continue
    hullBuildings.add currentBuilding
    hullNumerators.add crossNumerator
    hullDenominators.add crossDenominator
    visibilityThreshold[currentBuilding] = floorDivide(crossNumerator, crossDenominator)
    placed = true
    break
  if not placed:
    hullBuildings.add currentBuilding
    hullNumerators.add 0
    hullDenominators.add 1
    visibilityThreshold[currentBuilding] = neverVisible

visibilityThreshold.sort(compareThresholds)
```

Floor division handles negative numerators correctly.
A popped hull line can never set a new record at any height.
The first building uses the sentinel because it is always visible.

**Query answering.** A binary search counts thresholds below each query height.

```nim
let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let eyeHeight = int64(nextInt(inputData, scanPos))
  appendOutput($countBelow(visibilityThreshold, eyeHeight))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sorted thresholds make one binary search per query.
Strict comparison preserves the strict visibility rule.
Answers are buffered and flushed in blocks.

## Complexity

The hull, sort, and binary searches set the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over heights and queries | one input string |
| hull build | amortized `O(N)` fraction comparisons | three hull arrays |
| sort | `O(N log N)` comparisons | one threshold array |
| queries | `O(M log N)` binary searches | block buffer |

Building indexes and query counts drive the two dominant phases.

| measure | Big O |
|---|---|
| time | `O(N log N + M log N)` |
| space | `O(N)` |

Checking every building at every height would take `O(NM)`. Thresholds turn each query into one binary search over a sorted list.
