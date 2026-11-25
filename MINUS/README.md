# MINUS — Minus Operation (SPOJ)

<https://www.spoj.com/problems/MINUS/>

## Problem

Turn a row of numbers into a chosen value by repeatedly replacing adjacent neighbors with their difference. Print the position of the left neighbor used at each step.

Input: the first line gives the test count. Each test gives n and the target m, followed by n starting numbers, one per line. Output: print n − 1 position lines per test, then one blank line. Any valid sequence is accepted.

| item | bound |
|---|---|
| numbers n | 1 to 100 |
| target m | -500 to 500 |
| starting number | 0 to 100 |
| judge limit | 10000 ms, 1536 MB |

A solution always exists, so the DP search never needs a failure branch.

The sample asks for target four from five numbers.

| sample input lines | sample output lines |
|---|---|
| 1 / 5 4 / 12 / 10 / 4 / 3 / 5 | 2 / 3 / 2 / 1 / blank |

The four listed positions reduce the row to four.

## Idea

Every merge gives the left neighbor a plus sign and the right neighbor a minus sign, so the final value is a signed sum. The first number always keeps plus and the second always keeps minus, like the two ends of a see-saw that never swap sides. The algorithm finds signs for the rest with a subset-sum DP, then turns those signs into merges with a tree walk. Enumerating merge orders directly explodes with n, while the DP visits at most one row per number. Solve the signs first, then build the merges from them.

## Why It Works

1. The leftmost number can never sit on the right of a subtraction, so its sign stays plus.
2. The second number is on the right when it first meets the first number, so its sign stays minus.
3. Every later number may take either sign, and a subset-sum DP finds signs that hit the target.
4. A group rooted at its leftmost number has plus there and minus at the next number.
5. Splitting a group after a minus followed by a plus keeps both sides valid, so the walk always finds a split.
6. Merging left group minus right group flips the right signs and reproduces the chosen signs.

| term | meaning |
|---|---|
| `targetSigns` | chosen plus or minus coefficient for each original number |
| `reachable` | subset-sum table for the numbers after the second |
| `wantedTotal` | remaining signed sum after fixing the first two signs |
| `splitNumber` | first number of the right subgroup in the current group |
| `buildGroup` | recursive procedure that emits the merge positions |

The two fixed leading signs reduce the search to an ordinary subset-sum instance.

A scripted trace for the sample lists the chosen signs and the emitted positions.

| step | current row | printed position |
|---|---|---|
| start | 12 10 4 3 5 | - |
| merge neighbors 2 and 3 | 12 6 3 5 | 2 |
| merge neighbors 3 and 4 | 12 6 -2 | 3 |
| merge neighbors 2 and 3 | 12 8 | 2 |
| merge neighbors 1 and 2 | 4 | 1 |

The signs are plus, minus, plus, plus, minus and their weighted sum is four.

All arithmetic stays in integers, so rounding never enters the computation.

## Code

**Input and scanning.** The reader accepts negative targets and stores each test in order.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and not ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '-'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc removeAt(values: var seq[int], position: int) =
  var index = position
  while index < values.len - 1:
    values[index] = values[index + 1]
    index += 1
  values.setLen(values.len - 1)
```

The scanner handles the minus sign of the target.
The removal helper shifts a merged row after each step.
The buffer flushes after a large block of position lines.

**Sign recovery and merge walk.** The DP fixes coefficients and the walk prints positions.

```nim
var targetSigns = newSeq[int]()
var currentStarts = newSeq[int]()
var currentValues = newSeq[int]()

proc findPosition(firstNumber: int): int =
  for position in 0 .. currentStarts.len - 1:
    if currentStarts[position] == firstNumber:
      return position
  return -1

proc effectiveSign(numberIndex: int, inverted: bool): int =
  if inverted:
    return -targetSigns[numberIndex]
  return targetSigns[numberIndex]

proc buildGroup(firstNumber: int, lastNumber: int, inverted: bool): int =
  if firstNumber == lastNumber:
    return findPosition(firstNumber)
  var splitNumber = -1
  var candidate = firstNumber + 1
  while candidate <= lastNumber:
    if effectiveSign(candidate, inverted) == -1 and (candidate == lastNumber or effectiveSign(candidate + 1, inverted) == 1):
      splitNumber = candidate
      break
    candidate += 1
  let leftPosition = buildGroup(firstNumber, splitNumber - 1, inverted)
  let rightPosition = buildGroup(splitNumber, lastNumber, not inverted)
  appendOutput($(leftPosition + 1))
  outputBuffer.add '\n'
  currentValues[leftPosition] = currentValues[leftPosition] - currentValues[rightPosition]
  removeAt(currentValues, rightPosition)
  removeAt(currentStarts, rightPosition)
  return leftPosition

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberCount = nextInt(inputData, scanPos)
  let targetValue = nextInt(inputData, scanPos)
  var originalNumbers = newSeq[int](numberCount)
  for numberIndex in 0 .. numberCount - 1:
    originalNumbers[numberIndex] = nextInt(inputData, scanPos)
  targetSigns = newSeq[int](numberCount)
  if numberCount == 1:
    targetSigns[0] = 1
  else:
    targetSigns[0] = 1
    targetSigns[1] = -1
    var remainingTotal = 0
    for numberIndex in 2 .. numberCount - 1:
      remainingTotal += originalNumbers[numberIndex]
    let wantedTotal = targetValue - originalNumbers[0] + originalNumbers[1]
    let columnCount = 2 * remainingTotal + 1
    let sumOffset = remainingTotal
    var reachable = newSeq[bool](numberCount * columnCount)
    reachable[sumOffset] = true
    for usedCount in 1 .. numberCount - 2:
      let currentValue = originalNumbers[usedCount + 1]
      let rowStart = usedCount * columnCount
      let previousStart = (usedCount - 1) * columnCount
      for sumValue in 0 .. columnCount - 1:
        var possible = false
        if sumValue >= currentValue and reachable[previousStart + sumValue - currentValue]:
          possible = true
        if not possible and sumValue + currentValue < columnCount and reachable[previousStart + sumValue + currentValue]:
          possible = true
        reachable[rowStart + sumValue] = possible
    var walkSum = sumOffset + wantedTotal
    for usedCount in countdown(numberCount - 2, 1):
      let currentValue = originalNumbers[usedCount + 1]
      let previousStart = (usedCount - 1) * columnCount
      if walkSum - currentValue >= 0 and reachable[previousStart + walkSum - currentValue]:
        targetSigns[usedCount + 1] = 1
        walkSum -= currentValue
      else:
        targetSigns[usedCount + 1] = -1
        walkSum += currentValue
  currentStarts = newSeq[int](numberCount)
  currentValues = newSeq[int](numberCount)
  for numberIndex in 0 .. numberCount - 1:
    currentStarts[numberIndex] = numberIndex
    currentValues[numberIndex] = originalNumbers[numberIndex]
  discard buildGroup(0, numberCount - 1, false)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The DP prefers a plus sign while backtracking from the last number.
The walk builds the left subgroup first, so positions stay in row order.
One blank line ends each printed sequence.

## Complexity

Each test pays one subset-sum table and one walk over the numbers.

| phase | time | space |
|---|---|---|
| input read | one pass over numbers | one input string |
| subset-sum DP | numbers times sum range | one boolean table |
| merge walk | one merge per number | two row arrays |
| output | one block per position | output buffer |

The subset-sum table dominates both time and memory.

| measure | Big O |
|---|---|
| time | O(n · S) per test |
| space | O(n · S) |

Naive enumeration of merge orders grows factorially, while the DP and walk stay polynomial.
