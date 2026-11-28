# PUTIN — Put a Point in a Hyperspace (SPOJ)

<https://www.spoj.com/problems/PUTIN/>

## Problem

Count integer points B in a K-dimensional space. They stay off every axis and have coordinate sum at most S. Each given point a_i must dominate at least one coordinate. Print one large integer per test case.

The first line gives the number of test cases. Each case gives K, S, M, then M points with K non-negative coordinates. No two given points match and none lies on an axis. A valid B has all coordinates positive, and for each given point at least one coordinate of B is strictly smaller.

| item | bound |
|---|---|
| dimensions K | 2 to 30 |
| sum budget S | 2 to 10000 |
| given points M | 0 to 20 |
| judge limit | 10000 ms, 1536 MB |

The answer can have about ninety digits, so exact integer arithmetic is required.

Sample input:

```
1
2 4 2
1 3
2 1
```

Sample output:

```
2
```

## Idea

Picture each given point as a corner of an upward block. That block swallows every lattice point above it. Count the uncovered lattice by adding and subtracting overlapping tiles. Inclusion–exclusion turns the union of forbidden blocks into coordinatewise maxima. Each subset contributes one binomial coefficient, and Pascal's triangle supplies them all in one table.

Enumerating every candidate point would take C(S, K) steps, which explodes at the largest bounds. One pass over two to the M subsets replaces that enumeration.

## Why It Works

1. A point off every axis has all coordinates at least one.
2. A point B fails the strict condition for a_i exactly when every coordinate of B is at least the matching coordinate of a_i.
3. The answer is the number of positive vectors with sum at most S minus the vectors dominating at least one given point.
4. Vectors dominating a chosen set of points are the vectors dominating their coordinatewise maximum.
5. If that maximum has coordinate sum T, the count is C(S - T + K, K), or zero when T exceeds S.
6. The universe of positive vectors with sum at most S has size C(S, K).
7. Odd subsets are subtracted and even subsets are added, which removes every overlap exactly once.

| term | meaning |
|---|---|
| `bigBase` | base one billion used for each big-integer limb |
| `activeTable` | binomial values for the current dimension |
| `currentMaximum` | coordinatewise maximum of a chosen subset |
| `positiveTotal` | sum of even-subset terms and the universe |
| `negativeTotal` | sum of odd-subset terms |

Each term is a binomial coefficient with K fixed and the upper index at most S + K.

A script expanded the sample by inclusion–exclusion.

```
K = 2 S = 4 universe C(4,2) = 6
subset [(1, 3)] max [1, 3] sum 4 term C(2,2) = 1 sign -
subset [(2, 1)] max [2, 1] sum 3 term C(3,2) = 3 sign -
subset [(1, 3), (2, 1)] max [2, 3] sum 5 term C(1,2) = 0 sign +
answer = 2
```

The two single-point blocks remove four vectors and the shared block is empty, leaving two valid points.

The Pascal table is rebuilt once per distinct K. Limb arithmetic keeps every intermediate exact.

## Code

**Reader and big-integer limbs.** The scanner loads integers and the big type stores base-one-billion limbs.

```nim
const flushBlockBytes = 1 shl 17
const bigBase: int64 = 1000000000
const limbDigits = 9
const maximumDimension = 30

type TestCase = object
  dimension: int
  budget: int
  points: seq[seq[int64]]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value
```

The reader joins all lines into one input string.
Coordinates fit in a signed 64-bit integer.
No minus branch is needed because all inputs are non-negative.

**Exact addition, subtraction, and printing.** Each limb carries into the next one, and printing pads every limb to nine digits.

```nim
proc addBig(left: seq[int32], right: seq[int32]): seq[int32] =
  let longest = max(left.len, right.len)
  var sumValue = newSeq[int32](longest + 1)
  var carry: int64 = 0
  var limbIndex = 0
  while limbIndex < longest:
    var limbSum: int64 = carry
    if limbIndex < left.len:
      limbSum += int64(left[limbIndex])
    if limbIndex < right.len:
      limbSum += int64(right[limbIndex])
    sumValue[limbIndex] = int32(limbSum mod bigBase)
    carry = limbSum div bigBase
    limbIndex += 1
  sumValue[longest] = int32(carry)
  while sumValue.len > 1 and sumValue[sumValue.len - 1] == 0:
    sumValue.setLen(sumValue.len - 1)
  return sumValue

proc subBig(left: seq[int32], right: seq[int32]): seq[int32] =
  var difference = newSeq[int32](left.len)
  var borrow: int64 = 0
  var limbIndex = 0
  while limbIndex < left.len:
    var limbValue: int64 = int64(left[limbIndex]) - borrow
    if limbIndex < right.len:
      limbValue -= int64(right[limbIndex])
    if limbValue < 0:
      limbValue += bigBase
      borrow = 1
    else:
      borrow = 0
    difference[limbIndex] = int32(limbValue)
    limbIndex += 1
  while difference.len > 1 and difference[difference.len - 1] == 0:
    difference.setLen(difference.len - 1)
  return difference

proc toStringBig(value: seq[int32]): string =
  if value.len == 0:
    return "0"
  var decimalText = $value[value.len - 1]
  var limbIndex = value.len - 2
  while limbIndex >= 0:
    var limbText = $value[limbIndex]
    while limbText.len < limbDigits:
      limbText = "0" & limbText
    decimalText.add limbText
    limbIndex -= 1
  return decimalText
```

Subtraction runs only when the total is at least the removed total.
Trailing zero limbs are trimmed after both operations.
The highest limb is printed without leading zeros.

**Binomial table and subset walk.** Pascal's rule builds every coefficient once, and the walk accumulates signed terms.

```nim
proc buildBinomialTable(dimension: int, highest: int): seq[seq[int32]] =
  var row = newSeq[seq[int32]](dimension + 1)
  for index in 0 .. dimension:
    row[index] = @[]
  row[0] = @[int32(1)]
  var table = newSeq[seq[int32]](highest + 1)
  for number in 1 .. highest:
    var upper = number
    if upper > dimension:
      upper = dimension
    var degree = upper
    while degree >= 1:
      row[degree] = addBig(row[degree], row[degree - 1])
      degree -= 1
    if number >= dimension:
      table[number] = row[dimension]
  return table

var activePoints: seq[seq[int64]]
var activeDimension = 0
var activeBudget = 0
var activeTable: seq[seq[int32]]
var currentMaximum: seq[int64]
var positiveTotal: seq[int32]
var negativeTotal: seq[int32]

proc visitSubsets(pointIndex: int, chosenCount: int) =
  if pointIndex == activePoints.len:
    if chosenCount == 0:
      return
    var maximumSum: int64 = 0
    for axis in 0 ..< activeDimension:
      maximumSum += currentMaximum[axis]
    if maximumSum <= int64(activeBudget):
      let termIndex = int(int64(activeBudget) - maximumSum) + activeDimension
      let termValue = activeTable[termIndex]
      if chosenCount mod 2 == 1:
        negativeTotal = addBig(negativeTotal, termValue)
      else:
        positiveTotal = addBig(positiveTotal, termValue)
    return
  visitSubsets(pointIndex + 1, chosenCount)
  var savedMaximum = newSeq[int64](activeDimension)
  for axis in 0 ..< activeDimension:
    savedMaximum[axis] = currentMaximum[axis]
    if activePoints[pointIndex][axis] > currentMaximum[axis]:
      currentMaximum[axis] = activePoints[pointIndex][axis]
  visitSubsets(pointIndex + 1, chosenCount + 1)
  for axis in 0 ..< activeDimension:
    currentMaximum[axis] = savedMaximum[axis]
```

The table stores C(n, K) for each upper index n.
The walk restores the saved maximum after each included point.
Terms with a coordinate sum above S are skipped.

**Buffered answers.** One buffered line reports each test case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt64(inputData, scanPos))
var allCases = newSeq[TestCase](caseCount)
for caseIndex in 0 ..< caseCount:
  var currentCase: TestCase
  currentCase.dimension = int(nextInt64(inputData, scanPos))
  currentCase.budget = int(nextInt64(inputData, scanPos))
  let pointCount = int(nextInt64(inputData, scanPos))
  currentCase.points = newSeq[seq[int64]](pointCount)
  for pointIndex in 0 ..< pointCount:
    currentCase.points[pointIndex] = newSeq[int64](currentCase.dimension)
    for axis in 0 ..< currentCase.dimension:
      currentCase.points[pointIndex][axis] = nextInt64(inputData, scanPos)
  allCases[caseIndex] = currentCase

var largestBudget = newSeq[int](maximumDimension + 1)
for currentCase in allCases:
  if currentCase.budget > largestBudget[currentCase.dimension]:
    largestBudget[currentCase.dimension] = currentCase.budget

var binomialTables = newSeq[seq[seq[int32]]](maximumDimension + 1)
for dimension in 0 .. maximumDimension:
  if largestBudget[dimension] > 0:
    binomialTables[dimension] = buildBinomialTable(dimension,
                                                   largestBudget[dimension] + dimension)

for currentCase in allCases:
  activePoints = currentCase.points
  activeDimension = currentCase.dimension
  activeBudget = currentCase.budget
  activeTable = binomialTables[activeDimension]
  currentMaximum = newSeq[int64](activeDimension)
  positiveTotal = activeTable[activeBudget]
  negativeTotal = @[]
  visitSubsets(0, 0)
  let answer = subBig(positiveTotal, negativeTotal)
  appendOutput(toStringBig(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

All cases are read before tables are built.
The universe term is C(S, K), stored at index S.
Each printed answer ends with one newline.

## Complexity

The table build and the subset walk dominate the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over integer tokens | all test cases |
| table build | O((S + K) K) big additions per dimension | binomial table |
| subset walk | O(2^M K) coordinate updates | K coordinate slots |
| output | one buffered write per case | block buffer |

Subsets that exceed the budget add no term.

| measure | Big O |
|---|---|
| time per case | O((S + K) K + 2^M K) |
| space | O((S + K) K) for the largest table |

Enumerating every candidate point takes C(S, K) steps, while inclusion–exclusion touches only two to the M subsets. The table and the walk together give the exact count at every bound.
