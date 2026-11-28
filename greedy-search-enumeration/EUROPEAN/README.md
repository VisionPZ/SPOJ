# EUROPEAN — European railroad tracks (SPOJ)

<https://www.spoj.com/problems/EUROPEAN/>

## Problem

Place the fewest rails so every required gauge equals the gap between some pair of rails. The first rail sits at position 0, and the answer lists all rail positions in increasing order.

Input starts with the test count. Each case gives a gauge count, then that many gauge values. Output gives `Scenario #X`, then the rail count, a colon, the sorted positions, and one blank line. Any minimum set of rails is accepted, so another valid layout may replace the sample positions.

The bounds from the statement:

| Item | Bound |
|---|---|
| Gauges per case | 1 to 8 |
| Gauge value | 1000 to 5000 |
| Guaranteed layout | at most 5 rails |
| Judge limit | 105 ms, 1536 MB |

The five-rail guarantee keeps every search short.

The sample case:

```
3
4
1524 1520 1609 1435
3
1000 1520 1600
6
1000 2000 3000 4000 1500 2500
```

```
Scenario #1
4: 0 1520 1609 3044

Scenario #2
4: 0 1000 1520 1600

Scenario #3
5: 0 1500 3000 4000 5000

```

## Idea

Think of marking a ruler with a pencil so several lengths can be read from pairs of marks. Start at zero, then add marks one gauge away from a mark already placed.

The program uses iterative deepening depth-first search over the rail count. It tries two rails, then three, and stops at five. Each step adds a rail at an existing position plus or minus a gauge. A bit mask tracks the gauges already matched. Among all minimum layouts, the program keeps the smallest sorted list, so the answer stays the same on every run.

One search node tries at most 64 new positions. That is two directions, eight gauges, and four current rails. Checking one new position costs at most five subtractions.

Listing every subset of possible positions is slower. That method tests hundreds of candidate positions taken four at a time. Stepping by one gauge at a time reaches a minimum layout with far fewer trials.

Search by gauge steps, not by raw positions.

## Why It Works

Four facts carry the proof.

1. Every rail in a smallest layout helps to realize some gauge. That gauge joins it to another rail. Starting at zero and stepping by a gauge therefore reaches every layout we need.
2. A layout with k rails has `C(k, 2)` pairs. A count with fewer pairs than gauges cannot work.
3. Each gauge still missing needs a pair that uses a new rail. If the missing count exceeds the number of pairs a new rail can form, the branch fails.
4. Sorting the current positions before storing a state avoids revisiting the same layout in another order. Comparing complete layouts keeps one answer for the special judge.

The main terms and their meanings:

| Term | Meaning |
|---|---|
| `targetRails` | rail count tried in the current pass |
| `remainingPairs` | pairs still available after the current rails |
| `countMaskBits(allGaugeMask and not coveredMask)` | number of gauges still missing |
| `positionLimit` | sum of the gauges, the largest rail position we generate |
| `visitedSets` | rail sets already explored in this pass |
| `bestPositions` | smallest complete layout found so far |

The pair bound cuts branches early, and the stamp table makes coverage checks cheap.

A traced run on gauges 2744, 2929, and 3805 from the random tests:

```
gauges: 2744 2929 3805
k=2 pairs=1 too few pairs
k=3 pairs=3 enough pairs
k=4 pairs=6 enough pairs
k=5 pairs=10 enough pairs
chosen rails: 0 185 2929 3805
gauge 2744 from rails 185 and 2929
gauge 2929 from rails 0 and 2929
gauge 3805 from rails 0 and 3805
```

Three rails give enough pairs by count, yet no three positions realize all three gauges. Four rails work because 2929 minus 2744 gives 185.

## Code

**Input and constants.** The whole stream is read once, then parsed by digit index.

```nim
import sets

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxRailCount = 5
const maxGaugeCount = 8
const maxGaugeValue = 5000
const maxCandidateCount = 128

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and data[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The loop reads every line before any parsing starts. `scanPos` advances by index, so no string token is built. The scanner skips whitespace and adds one digit at a time.

**Per-case state.** Every array is allocated once, before the case loop.

```nim
var gaugeCount = 0
var gaugeValues: array[maxGaugeCount, int]
var gaugeIndexByValue: array[maxGaugeValue + 1, int]
var gaugeStamp: array[maxGaugeValue + 1, int]
var currentStamp = 0
var allGaugeMask = 0
var positionLimit = 0
var railPositions: array[maxRailCount, int]
var sortedPositions: array[maxRailCount, int]
var candidateStamp: array[maxGaugeCount * maxGaugeValue + 1, int]
var candidateMark = 0
var bestPositions: array[maxRailCount, int]
var bestRailCount = 0
var bestFound = false
var visitedSets = initSet[(int64, int64)](512)
```

`gaugeStamp` replaces a per-case table clear with one integer stamp. Five positions fit into two 64-bit halves of a state key. The arrays hold at most eight gauges and five rails.

**Coverage bookkeeping.** Each new rail updates the gauge mask by subtraction.

```nim
proc countMaskBits(maskValue: int): int =
  var count = 0
  var remaining = maskValue
  while remaining > 0:
    remaining = remaining and (remaining - 1)
    count += 1
  return count

proc coveredWithMarks(coveredMask, newPosition, markCount: int): int =
  var coveredResult = coveredMask
  for markIndex in 0 ..< markCount:
    let basePosition = railPositions[markIndex]
    var difference = 0
    if newPosition >= basePosition:
      difference = newPosition - basePosition
    else:
      difference = basePosition - newPosition
    if difference <= maxGaugeValue and gaugeStamp[difference] == currentStamp:
      coveredResult = coveredResult or (1 shl gaugeIndexByValue[difference])
  return coveredResult
```

The bit count runs only on the mask of missing gauges. A stamp match means the difference equals a gauge in this case. The loop touches at most five existing rails.

**Depth-first search.** This procedure grows one rail layout and keeps the smallest winner.

```nim
proc searchRails(markCount, coveredMask, targetRails: int) =
  for markIndex in 0 ..< markCount:
    sortedPositions[markIndex] = railPositions[markIndex]
  for sortIndex in 1 ..< markCount:
    let keyPosition = sortedPositions[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0 and sortedPositions[previousIndex] > keyPosition:
      sortedPositions[previousIndex + 1] = sortedPositions[previousIndex]
      previousIndex -= 1
    sortedPositions[previousIndex + 1] = keyPosition

  var keyLow: int64 = 0
  var keyHigh: int64 = 0
  for markIndex in 0 ..< markCount:
    if markIndex < 3:
      keyLow = keyLow or (int64(sortedPositions[markIndex]) shl (markIndex * 16))
    else:
      keyHigh = keyHigh or (int64(sortedPositions[markIndex]) shl ((markIndex - 3) * 16))
  let stateKey = (keyLow, keyHigh)
  if stateKey in visitedSets:
    return
  visitedSets.incl stateKey

  if coveredMask == allGaugeMask:
    var isBetter = not bestFound
    if not isBetter:
      for markIndex in 0 ..< markCount:
        if sortedPositions[markIndex] < bestPositions[markIndex]:
          isBetter = true
          break
        if sortedPositions[markIndex] > bestPositions[markIndex]:
          break
    if isBetter:
      for markIndex in 0 ..< markCount:
        bestPositions[markIndex] = sortedPositions[markIndex]
      bestRailCount = markCount
      bestFound = true
    return

  if markCount >= targetRails:
    return

  let remainingPairs = targetRails * (targetRails - 1) div 2 - markCount * (markCount - 1) div 2
  if countMaskBits(allGaugeMask and not coveredMask) > remainingPairs:
    return

  candidateMark += 1
  var candidateList: array[maxCandidateCount, int]
  var candidateCount = 0
  for existingIndex in 0 ..< markCount:
    candidateStamp[railPositions[existingIndex]] = candidateMark
  for markIndex in 0 ..< markCount:
    let basePosition = railPositions[markIndex]
    for gaugeIndex in 0 ..< gaugeCount:
      let gaugeValue = gaugeValues[gaugeIndex]
      let rightPosition = basePosition + gaugeValue
      if rightPosition <= positionLimit and candidateStamp[rightPosition] != candidateMark:
        candidateStamp[rightPosition] = candidateMark
        candidateList[candidateCount] = rightPosition
        candidateCount += 1
      let leftPosition = basePosition - gaugeValue
      if leftPosition >= 0 and candidateStamp[leftPosition] != candidateMark:
        candidateStamp[leftPosition] = candidateMark
        candidateList[candidateCount] = leftPosition
        candidateCount += 1

  for candidateIndex in 0 ..< candidateCount:
    let newPosition = candidateList[candidateIndex]
    let newCovered = coveredWithMarks(coveredMask, newPosition, markCount)
    railPositions[markCount] = newPosition
    searchRails(markCount + 1, newCovered, targetRails)
```

The key uses five positions packed into two integers. Sorting before the key stops order permutations from multiplying the work. The pair bound prunes a branch before any new rail is tried.

Each call owns `candidateList`, so recursion cannot overwrite the positions still waiting in the loop. The stamp array removes duplicate candidates in constant time. At most 64 candidates are produced per node.

**Driver.** The case loop fills the tables, searches counts, and appends output.

```nim
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let inputCount = nextInt(inputData, scanPos)
  gaugeCount = 0
  for inputIndex in 0 ..< inputCount:
    let gaugeValue = nextInt(inputData, scanPos)
    var isDuplicate = false
    for existingIndex in 0 ..< gaugeCount:
      if gaugeValues[existingIndex] == gaugeValue:
        isDuplicate = true
        break
    if not isDuplicate:
      gaugeValues[gaugeCount] = gaugeValue
      gaugeCount += 1

  currentStamp += 1
  allGaugeMask = 0
  positionLimit = 0
  for gaugeIndex in 0 ..< gaugeCount:
    let gaugeValue = gaugeValues[gaugeIndex]
    gaugeIndexByValue[gaugeValue] = gaugeIndex
    gaugeStamp[gaugeValue] = currentStamp
    allGaugeMask = allGaugeMask or (1 shl gaugeIndex)
    positionLimit += gaugeValue

  bestFound = false
  bestRailCount = 0
  for targetRails in 1 .. maxRailCount:
    if targetRails * (targetRails - 1) div 2 < gaugeCount:
      continue
    visitedSets.clear()
    railPositions[0] = 0
    searchRails(1, 0, targetRails)
    if bestFound:
      break

  outputBuffer.add "Scenario #"
  outputBuffer.add $caseIndex
  outputBuffer.add '\n'
  outputBuffer.add $bestRailCount
  outputBuffer.add ':'
  for markIndex in 0 ..< bestRailCount:
    outputBuffer.add ' '
    outputBuffer.add $bestPositions[markIndex]
  outputBuffer.add '\n'
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

Duplicate gauges are dropped before the mask is built. The count loop stops at the first rail count that succeeds. Every line goes into `outputBuffer`, and `flushBlockBytes` bounds the memory used by the output.

## Complexity

The cost splits into input parsing, bounded search, and buffered writing.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes, then one digit pass | input bytes |
| One rail count | at most 64 candidate positions per visited set | one state key per set |
| Coverage update | at most five stamp lookups per candidate | fixed arrays |
| Output write | one write per 256 KiB block | one output buffer |

The search visits about nine thousand sets on a hard eight-gauge case.

| Measure | Big O |
|---|---|
| Time | O(S times gauges per case), where S is the number of distinct rail sets visited |
| Space | O(S plus input bytes plus output block) |

With at most five rails and eight gauges, S stays small and the run stays inside the judge limit. Enumerating all subsets of candidate positions would test far more layouts.
