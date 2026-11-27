# LANDSCAP — Landscaping (SPOJ)

<https://www.spoj.com/problems/LANDSCAP/>

## Problem

Given a row of elevations, lower chosen columns so that at most K flat-topped hills remain, and spend the least total earth removed. A hill is a maximal run of equal height whose neighbors sit lower or outside the row.

Input starts with t. Each case gives N and K, then N lines holding one elevation each. Output one integer per case: the minimum total reduction. In the explanation, h names a candidate height level and p names the count of hills already closed.

| item | bound |
|---|---|
| test cases | not bounded in the statement |
| columns N | 1 to 1000 |
| hill budget K | 1 to 25 |
| elevation | 1 to 1 000 000 |
| judge limit | 9 s, 1536 MB |

N and K set the work. Elevations set the cost of each lowering.

The sample input:

```
1
12 1
1
2
3
3
3
2
1
3
2
2
1
2
```

The sample output:

```
5
```

## Idea

Count hills while tracing the skyline, like a walker counting bumps that end when the ground drops away. Dynamic programming walks the row once and remembers the current flat run.

The state holds the run's height, the hills already closed, and whether the run can still become a hill. Two running tables over heights give the best lower, equal, or higher predecessor in constant time per state. Each column costs O(HK), where H counts distinct elevations in the case, at most N.

Trying every lowered landscape costs exponential time. Comparing every predecessor height costs O(H²K) per column. Running minima remove that extra factor. One pass over columns with running minima settles the whole row.

## Why It Works

1. An optimal lowering never needs a height absent from the input. Raising such a column to the next input height changes no comparison with its neighbors and lowers the cost.
2. A hill ends when the height drops after a run. The run counts only if its left neighbor was lower or outside the row.
3. A rise makes the old run fail as a hill and starts a new possible hill. A drop closes the old run when it was still possible. A drop starts a run that cannot be a hill. Equality preserves the run's status.
4. `prefixBest` holds the best cost over heights up to the current one. `suffixPeak` and `suffixValley` hold the best cost over higher heights. Each state reads its best predecessor in constant time.

The tables carry these meanings.

| term | meaning |
|---|---|
| `peakRun` | best cost for a run that can still become a hill |
| `valleyRun` | best cost for a run with a higher left neighbor |
| `prefixBest` | best cost over heights at most the current height, either run state |
| `suffixPeak` | best cost over higher heights when the run can still become a hill |
| `suffixValley` | best cost over higher heights when the run cannot become a hill |
| `stride` | count of peak counts stored per height |

The two run states and two minima tables cover every way to end a hill.

A script traced the sample under a budget of one hill. The cost column gives the best answer for the prefix ending at that column.

```
col elevation best_cost_at_most_1_hill
  1        1          0
  2        2          0
  3        3          0
  4        3          0
  5        3          0
  6        2          0
  7        1          0
  8        3          2
  9        2          3
 10        2          4
 11        1          4
 12        2          5
```

The last row matches the sample answer of five.

## Code

**Constants and digit scanner.** Read the whole stream once and parse integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = 1 shl 60
const maxColumns = 1000
const maxPeaks = 25

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

`flushBlockBytes` sets a 256 KiB output block. `infinity` leaves room for one column's cost. `nextInt` skips separators without building tokens. The scanner handles non-negative values only, as the statement allows.

**Comparators and height lookup.** Sort distinct elevations and map a value to its level.

```nim
proc compareValues(leftValue, rightValue: int): int =
  if leftValue < rightValue: return -1
  if leftValue > rightValue: return 1
  return 0

proc heightLevel(heightValues: seq[int], levelCount: int, target: int): int =
  var low = 0
  var high = levelCount - 1
  while low <= high:
    let middle = (low + high) div 2
    if heightValues[middle] < target:
      low = middle + 1
    else:
      high = middle - 1
  return low + 1
```

`compareValues` supplies the explicit comparator that Nim 0.19.4 requires. `heightLevel` returns a one-based level through binary search. The search reads only the filled part of the array.

**Case setup.** Compress heights, clear buffers, and seed the first column.

```nim
proc solveCase(elevations: seq[int], columnCount: int, budget: int, peakRun: var seq[int], valleyRun: var seq[int], nextPeak: var seq[int], nextValley: var seq[int], prefixBest: var seq[int], suffixPeak: var seq[int], suffixValley: var seq[int]): int =
  var sortedValues = newSeq[int](columnCount)
  for column in 0 .. columnCount - 1:
    sortedValues[column] = elevations[column]
  sort(sortedValues, compareValues)
  var distinctValues = newSeq[int](columnCount)
  var distinctCount = 0
  for value in sortedValues:
    if distinctCount == 0 or distinctValues[distinctCount - 1] != value:
      distinctValues[distinctCount] = value
      distinctCount += 1
  let stride = budget + 1
  let levelCount = distinctCount
  for index in 0 .. (levelCount + 2) * stride - 1:
    peakRun[index] = infinity
    valleyRun[index] = infinity
    nextPeak[index] = infinity
    nextValley[index] = infinity
    prefixBest[index] = infinity
    suffixPeak[index] = infinity
    suffixValley[index] = infinity
  let firstLevel = heightLevel(distinctValues, distinctCount, elevations[0])
  for level in 1 .. firstLevel:
    peakRun[level * stride] = elevations[0] - distinctValues[level - 1]
  var maxTopSeen = firstLevel
```

`distinctCount` limits levels to values that occur. Clearing all seven buffers avoids stale zero costs from earlier cases. The first column starts as a possible hill at each height not above its elevation.

**Column sweep.** Build running minima, then update every candidate height.

```nim
  for column in 1 .. columnCount - 1:
    let elevation = elevations[column]
    let topLevel = heightLevel(distinctValues, distinctCount, elevation)
    maxTopSeen = max(maxTopSeen, topLevel)
    for count in 0 .. budget:
      prefixBest[count] = infinity
      suffixPeak[(maxTopSeen + 1) * stride + count] = infinity
      suffixValley[(maxTopSeen + 1) * stride + count] = infinity
    for level in 1 .. topLevel - 1:
      let base = level * stride
      for count in 0 .. budget:
        prefixBest[base + count] = min(prefixBest[base - stride + count], min(peakRun[base + count], valleyRun[base + count]))
    for level in countdown(maxTopSeen, 1):
      let base = level * stride
      for count in 0 .. budget:
        suffixPeak[base + count] = min(suffixPeak[base + stride + count], peakRun[base + count])
        suffixValley[base + count] = min(suffixValley[base + stride + count], valleyRun[base + count])
      if level > topLevel:
        for count in 0 .. budget:
          nextPeak[base + count] = infinity
          nextValley[base + count] = infinity
    for level in 1 .. topLevel:
      let base = level * stride
      let addCost = elevation - distinctValues[level - 1]
      for count in 0 .. budget:
        var valleyCost = min(valleyRun[base + count], suffixValley[base + stride + count]) + addCost
        if count > 0:
          valleyCost = min(valleyCost, suffixPeak[base + stride + count - 1] + addCost)
        nextValley[base + count] = valleyCost
        nextPeak[base + count] = min(peakRun[base + count], prefixBest[base - stride + count]) + addCost
    swap(peakRun, nextPeak)
    swap(valleyRun, nextValley)
```

`prefixBest` accumulates the best lower or equal predecessor. `suffixPeak` and `suffixValley` accumulate the best higher predecessor. A valley state gains one closed hill only from a former possible hill. Levels above `topLevel` are cleared before the buffers swap.

**Answer extraction.** Read the minimum over all final heights.

```nim
  var answer = infinity
  for level in 1 .. levelCount:
    let base = level * stride
    for count in 0 .. budget:
      answer = min(answer, valleyRun[base + count])
    if budget > 0:
      for count in 0 .. budget - 1:
        answer = min(answer, peakRun[base + count])
  return answer
```

A final possible hill still counts, so its budget stops one below K. A final valley run spends no extra hill.

**Driver buffers.** Allocate flat arrays once and read all of stdin.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
let bufferSize = (maxColumns + 2) * (maxPeaks + 1)
var peakRun = newSeq[int](bufferSize)
var valleyRun = newSeq[int](bufferSize)
var nextPeak = newSeq[int](bufferSize)
var nextValley = newSeq[int](bufferSize)
var prefixBest = newSeq[int](bufferSize)
var suffixPeak = newSeq[int](bufferSize)
var suffixValley = newSeq[int](bufferSize)
var elevations = newSeq[int](maxColumns)
var outputBuffer = ""
```

`bufferSize` covers the largest legal case. `elevations` is reused across cases with no reallocation. `inputData` holds the whole stream for the hand scanner.

**Case loop.** Parse one case, solve it, and write in blocks.

```nim
for caseIndex in 0 .. caseCount - 1:
  let columnCount = nextInt(inputData, scanPos)
  let requestedBudget = nextInt(inputData, scanPos)
  let budget = min(requestedBudget, maxPeaks)
  for column in 0 .. columnCount - 1:
    elevations[column] = nextInt(inputData, scanPos)
  let answer = solveCase(elevations, columnCount, budget, peakRun, valleyRun, nextPeak, nextValley, prefixBest, suffixPeak, suffixValley)
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

`requestedBudget` is capped at `maxPeaks` before indexing. `outputBuffer` flushes at 256 KiB and once more after the loop. `stdout.write` handles a block, never a single number.

## Complexity

The sweep dominates the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over lines, then one digit pass | input bytes |
| height setup | sort at most 1000 values | distinct values |
| column sweep | O(HK) per column | seven flat buffers |
| output | one write per 256 KiB block | block buffer |

Cost grows with distinct heights, not with the elevation range.

The overall bounds follow from the sweep.

| measure | Big O |
|---|---|
| time | O(NHK) per case, with H at most N and K at most 25 |
| space | O(HK) plus the input and output buffers |

Running minima make the sweep linear in heights. Enumerating lowered landscapes costs exponential time, and comparing every predecessor height costs O(NH²K).
