<https://www.spoj.com/problems/FBWHEELS/>

## Problem

Buy a sequence of letters shorter than the secret word. Two wheels pick two different starting positions, and you win only when both positions spell that sequence. Report the M largest expected gains over all distinct sequences.

Input starts with T cases. Each case gives N, M, W, X, Y, Z, then the secret word, then N basic deals with cost and length. Output prints M real numbers per case in descending order, accurate to 1e-2.

| item | bound |
|---|---|
| test cases T | 1 to 150 |
| secret word length L | 2 to 100000 |
| basic deals N | 1 to 20 |
| answers M | 1 to 20 |
| combine surcharge W | 0 to 10000 |
| parameters X, Y, Z | X < L; Y, Z up to 1000000000 |
| judge limit | 60000 ms, 1536 MB |

A deal of length L1 plus a deal of length L2 costs C1+C2+W. Deals can be combined repeatedly while the total length stays below L.

Sample input:

```
2
1 3 0 1 5 6
ZZ
2 1
3 4 1 4 3 2
FOXENINBOXEN
5 2
1000 11
2 2
```

Sample output:

```
24.00000 -2.00000 -2.00000
7.05556 3.49091 3.49091 3.49091
```

## Idea

Repeated pieces of a word share one score, like several copies of the same key opening the same lock. A suffix automaton groups substrings that occur the same number of times, and a sweep keeps the best few groups for each length. Only those groups can enter the top M, so the search stays small.

## Why It Works

1. Combining deals is an unbounded knapsack: each extra piece adds its cost plus W.
2. A sequence of length ℓ has K = L-ℓ+1 possible starting positions.
3. The wheels choose an ordered pair of distinct starts, so there are K(K-1) pairs.
4. If a sequence occurs c times, the match probability is c(c-1)/(K(K-1)).
5. The win is Y(L-|X-ℓ|)^2+Z, and paying for the deal is a fixed loss.
6. A suffix automaton state covers a length range and one occurrence count c.
7. A sweep in length keeps the M largest occurrence counts active for each length.
8. Any sequence with fewer than two occurrences loses its deal cost, and the cheapest loss fills remaining slots.

| term | meaning |
|---|---|
| `minimumCost` | cheapest deal for each purchased length |
| `smallestCost` | cheapest deal over all lengths |
| `intervals` | length ranges paired with occurrence counts |
| `heapOccurrence` | active occurrence counts in the sweep |
| `candidateValues` | scores that can enter the answer |
| `rewardValue` | win amount for a length |
| `matchFactor` | probability two wheels agree |

In the first sample case, length one costs 2. The word "Z" occurs twice among two starts, so both wheels match and the gain is 5*(2-0)^2+6-2 = 24. Other letters never match and lose 2, giving 24, -2, -2. In the second case, "OXEN" costs 5, occurs twice, and wins 3*12^2+2. With K=9 its expectation is 434*2/72-5 = 7.05556.

## Code

**Input and heap helpers.** The reader loads all input, and a max-heap tracks active groups.

```nim
import algorithm
import strutils

const flushBlockBytes = 1 shl 17
const impossibleCost = 1000000000000000000

type ScoreInterval = tuple[lower: int, upper: int, occurrence: int]

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc heapPush(heapOccurrence: var seq[int], heapUpper: var seq[int], heapSize: var int, occurrence: int, upper: int) =
  heapSize += 1
  var position = heapSize
  heapOccurrence[position] = occurrence
  heapUpper[position] = upper
  while position > 1:
    let parentPosition = position div 2
    if heapOccurrence[parentPosition] >= occurrence:
      break
    heapOccurrence[position] = heapOccurrence[parentPosition]
    heapUpper[position] = heapUpper[parentPosition]
    position = parentPosition
  heapOccurrence[position] = occurrence
  heapUpper[position] = upper

proc heapPop(heapOccurrence: var seq[int], heapUpper: var seq[int], heapSize: var int): ScoreInterval =
  result = (0, heapUpper[1], heapOccurrence[1])
  let lastOccurrence = heapOccurrence[heapSize]
  let lastUpper = heapUpper[heapSize]
  heapSize -= 1
  if heapSize == 0:
    return
  var position = 1
  while true:
    let leftChild = position * 2
    if leftChild > heapSize:
      break
    let rightChild = leftChild + 1
    var betterChild = leftChild
    if rightChild <= heapSize and heapOccurrence[rightChild] > heapOccurrence[leftChild]:
      betterChild = rightChild
    if heapOccurrence[betterChild] <= lastOccurrence:
      break
    heapOccurrence[position] = heapOccurrence[betterChild]
    heapUpper[position] = heapUpper[betterChild]
    position = betterChild
  heapOccurrence[position] = lastOccurrence
  heapUpper[position] = lastUpper
```

The heap orders groups by occurrence count.
Each group also stores its last valid length.
The output buffer collects all answer lines.

**Deal costs and automaton.** Cheapest deals come first, then substring groups.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let dealCount = nextInt(inputData, scanPos)
  let answerCount = nextInt(inputData, scanPos)
  let combineCost = nextInt(inputData, scanPos)
  let targetLength = nextInt(inputData, scanPos)
  let rewardScale = nextInt(inputData, scanPos)
  let rewardBonus = nextInt(inputData, scanPos)
  let secretWord = nextWord(inputData, scanPos)
  let wordLength = secretWord.len
  var dealCosts = newSeq[int](dealCount)
  var dealLengths = newSeq[int](dealCount)
  for dealIndex in 0 .. dealCount - 1:
    dealCosts[dealIndex] = nextInt(inputData, scanPos)
    dealLengths[dealIndex] = nextInt(inputData, scanPos)
  var minimumCost = newSeq[int64](wordLength)
  for lengthValue in 0 .. wordLength - 1:
    minimumCost[lengthValue] = int64(impossibleCost)
  for dealIndex in 0 .. dealCount - 1:
    if dealLengths[dealIndex] < wordLength:
      minimumCost[dealLengths[dealIndex]] = min(minimumCost[dealLengths[dealIndex]], int64(dealCosts[dealIndex]))
  for lengthValue in 1 .. wordLength - 1:
    for dealIndex in 0 .. dealCount - 1:
      let pieceLength = dealLengths[dealIndex]
      if pieceLength < lengthValue and minimumCost[lengthValue - pieceLength] < int64(impossibleCost):
        let candidateCost = minimumCost[lengthValue - pieceLength] + int64(dealCosts[dealIndex]) + int64(combineCost)
        if candidateCost < minimumCost[lengthValue]:
          minimumCost[lengthValue] = candidateCost
  var smallestCost = int64(impossibleCost)
  for lengthValue in 1 .. wordLength - 1:
    if minimumCost[lengthValue] < smallestCost:
      smallestCost = minimumCost[lengthValue]
  let stateLimit = 2 * wordLength + 2
  var transitions = newSeq[array[26, int]](stateLimit)
  var suffixLinks = newSeq[int](stateLimit)
  var longestLength = newSeq[int](stateLimit)
  var endSize = newSeq[int](stateLimit)
  for stateIndex in 0 .. stateLimit - 1:
    suffixLinks[stateIndex] = -1
  var stateCount = 1
  var lastState = 0
  for position in 0 .. wordLength - 1:
    let letterIndex = int(secretWord[position]) - 65
    let currentState = stateCount
    stateCount += 1
    longestLength[currentState] = longestLength[lastState] + 1
    endSize[currentState] = 1
    var walkState = lastState
    while walkState != -1 and transitions[walkState][letterIndex] == 0:
      transitions[walkState][letterIndex] = currentState
      walkState = suffixLinks[walkState]
    if walkState == -1:
      suffixLinks[currentState] = 0
    else:
      let nextState = transitions[walkState][letterIndex]
      if longestLength[walkState] + 1 == longestLength[nextState]:
        suffixLinks[currentState] = nextState
      else:
        let cloneState = stateCount
        stateCount += 1
        transitions[cloneState] = transitions[nextState]
        longestLength[cloneState] = longestLength[walkState] + 1
        suffixLinks[cloneState] = suffixLinks[nextState]
        while walkState != -1 and transitions[walkState][letterIndex] == nextState:
          transitions[walkState][letterIndex] = cloneState
          walkState = suffixLinks[walkState]
        suffixLinks[nextState] = cloneState
        suffixLinks[currentState] = cloneState
    lastState = currentState
  var lengthCounts = newSeq[int](wordLength + 1)
  for stateIndex in 0 .. stateCount - 1:
    lengthCounts[longestLength[stateIndex]] += 1
  for lengthValue in 1 .. wordLength:
    lengthCounts[lengthValue] += lengthCounts[lengthValue - 1]
  var stateOrder = newSeq[int](stateCount)
  for stateIndex in countdown(stateCount - 1, 0):
    let stateLength = longestLength[stateIndex]
    lengthCounts[stateLength] -= 1
    stateOrder[lengthCounts[stateLength]] = stateIndex
  for orderIndex in countdown(stateCount - 1, 1):
    let stateIndex = stateOrder[orderIndex]
    endSize[suffixLinks[stateIndex]] += endSize[stateIndex]
```

Each new piece adds its cost and the surcharge.
The automaton has at most twice as many states as letters.
A reverse length order propagates occurrence counts to suffixes.

**Sweep and answers.** Groups enter the sweep by their first length, and only the best few stay active.

```nim
  var occurrencesByLength = newSeq[seq[int]](wordLength)
  var intervals = newSeq[ScoreInterval]()
  for stateIndex in 1 .. stateCount - 1:
    let lowerBound = longestLength[suffixLinks[stateIndex]] + 1
    var upperBound = longestLength[stateIndex]
    if upperBound >= wordLength:
      upperBound = wordLength - 1
    if lowerBound <= upperBound and endSize[stateIndex] >= 2:
      intervals.add((lowerBound, upperBound, endSize[stateIndex]))
  intervals.sort(proc(leftInterval, rightInterval: ScoreInterval): int =
    if leftInterval.lower < rightInterval.lower:
      return -1
    if leftInterval.lower > rightInterval.lower:
      return 1
    return 0)
  var heapOccurrence = newSeq[int](intervals.len + 2)
  var heapUpper = newSeq[int](intervals.len + 2)
  var heapSize = 0
  var intervalIndex = 0
  var keptIntervals = newSeq[ScoreInterval]()
  for lengthValue in 1 .. wordLength - 1:
    while intervalIndex < intervals.len and intervals[intervalIndex].lower <= lengthValue:
      heapPush(heapOccurrence, heapUpper, heapSize, intervals[intervalIndex].occurrence, intervals[intervalIndex].upper)
      intervalIndex += 1
    keptIntervals.setLen 0
    while heapSize > 0 and keptIntervals.len < answerCount:
      if heapUpper[1] < lengthValue:
        discard heapPop(heapOccurrence, heapUpper, heapSize)
        continue
      let selected = heapPop(heapOccurrence, heapUpper, heapSize)
      occurrencesByLength[lengthValue].add selected.occurrence
      keptIntervals.add selected
    for keptInterval in keptIntervals:
      heapPush(heapOccurrence, heapUpper, heapSize, keptInterval.occurrence, keptInterval.upper)
  var candidateValues = newSeq[float]()
  for lengthValue in 1 .. wordLength - 1:
    if minimumCost[lengthValue] >= int64(impossibleCost):
      continue
    let distance = abs(targetLength - lengthValue)
    let rewardSpan = wordLength - distance
    let rewardValue = float(rewardScale) * float(rewardSpan * rewardSpan) + float(rewardBonus)
    let startCount = wordLength - lengthValue + 1
    for occurrence in occurrencesByLength[lengthValue]:
      if occurrence < 2:
        continue
      let matchFactor = float(occurrence * (occurrence - 1)) / float(startCount * (startCount - 1))
      let expectedValue = rewardValue * matchFactor - float(minimumCost[lengthValue])
      if expectedValue > -float(smallestCost):
        candidateValues.add expectedValue
  candidateValues.sort(proc(leftValue, rightValue: float): int =
    if leftValue > rightValue:
      return -1
    if leftValue < rightValue:
      return 1
    return 0)
  for answerIndex in 0 .. answerCount - 1:
    if answerIndex > 0:
      outputBuffer.add ' '
    if answerIndex < candidateValues.len:
      appendOutput(formatFloat(candidateValues[answerIndex], ffDecimal, 5))
    else:
      appendOutput(formatFloat(-float(smallestCost), ffDecimal, 5))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each automaton state becomes one length interval.
The heap keeps only M groups per length.
Missing answers use the cheapest losing move.

## Complexity

Deal costs are found once for every length up to the word length.

| phase | time | space |
|---|---|---|
| deal costs | N times word length | one cost per length |
| automaton | one step per letter | up to 2L states |
| length sweep | M heap moves per length | one heap slot per state |
| final answers | sort of at most L M scores | candidate score list |

| measure | Big O |
|---|---|
| deal costs | O(N L) |
| automaton | O(L) |
| sweep | O(L M log L) |
| space | O(L + L M) |

Checking every substring of every length would cost O(L^2) before scoring. Automaton groups and a bounded heap reduce that to work proportional to the number of answers.
