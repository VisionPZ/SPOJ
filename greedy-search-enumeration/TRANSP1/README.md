# TRANSP1 — Transportation (SPOJ)

<https://www.spoj.com/problems/TRANSP1/>

## Problem

Raise the safety of base nexus 1 as much as possible by redirecting at most M transport links. Each other nexus sends its resources to one parent nexus. The safety of a nexus is its own value plus k times the safety of every nexus that sends resources to it. Nexus 1's own link cannot change.

| item | bound |
|---|---|
| nexuses N | 1 to 60 |
| changes M | 0 to N |
| factor k | 0.3 to less than 1 |
| cost Ci | positive real |
| test cases | ten with a blank line between |
| judge limit | 2000 ms, 1536 MB |

Output one line per case with the best safety rounded to two decimals.

Sample input:

```
4 1 0.5
2 3 1 3
10.0 10.0 10.0 10.0
```

Sample output:

```
30.00
```

## Idea

Each link can be redirected straight to the base, like moving a whole branch of a tree to its shallowest position. That shortens the path for every nexus in the branch and raises base safety. Try every possible first redirected link on the cycle through the base, then place the remaining changes with a tree knapsack. Each subtree stores two numbers, so a change deep in the tree costs one dimension instead of an exponential search.

| term | meaning |
|---|---|
| `cycleNodes` | nexuses on the cycle that contains the base |
| `cutPosition` | first cycle link redirected to the base |
| `childrenOf` | nexuses whose link points to a given nexus |
| `forbiddenCuts` | cycle links that must stay in place for this try |
| `AffinePair` | scaled and fixed parts of a subtree value |

The affine pair lets one subtree serve every possible depth.

## Why It Works

1. Following links from any nexus eventually reaches the base.
2. The cycle through the base fixes a gain factor of 1 / (1 - k^L), where L is its length.
3. Redirecting the first cycle link to the base shortens that cycle to two nexuses.
4. Every other redirect also targets the base, since the base has the smallest depth.
5. Removing the base's own outgoing link turns the rest into a tree rooted at the base.
6. A subtree value at depth D equals k^D times its scaled part plus its fixed part.
7. Cutting a child moves it to depth one, so its contribution becomes k times its scaled part plus its fixed part.
8. Keeping only pairs that win at some depth removes redundant knapsack states.

| term | meaning |
|---|---|
| `scaledPart` | coefficient multiplied by k raised to the subtree depth |
| `fixedPart` | contribution that does not depend on that depth |
| `cycleGain` | 1 / (1 - k^cycleLength) |
| `depthPowers` | k raised to each possible depth |

The gain factor and the tree value together give the final safety.

A worked example for the sample case with one allowed change:

```
cycle through base: 1 -> 2 -> 3 -> 1, length 3
no change: base safety 160/7 = 22.8571
redirect nexus 2 to the base: cycle length 2, gain 4/3
tree value 22.5, safety 22.5 * 4/3 = 30
```

The trace returns the sample answer.

## Code

**Input and scanner.** The reader loads each case and builds the cycle through the base.

```nim
import math
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

type
  AffinePair = object
    scaledPart: float64
    fixedPart: float64

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  var fractionalPart = 0
  var fractionalDigits = 0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionalPart = fractionalPart * 10 + int(data[pos]) - firstDigitValue
      fractionalDigits += 1
      pos += 1
  var scale = 1.0
  if fractionalDigits > 0:
    for digitIndex in 0 .. fractionalDigits - 1:
      scale = scale * 10.0
  return float64(wholePart) + float64(fractionalPart) / scale
```

Real values arrive with a decimal point.
Nexus numbers shift from one-based input to zero-based indexes.
An empty scan position ends the input.

**Subtree states.** Sorting and projection keep the knapsack frontier small.

```nim
var keepFactor: float64
var nodeCosts: seq[float64]
var childrenOf: seq[seq[int]]
var forbiddenCuts: seq[bool]
var cycleFlags: seq[bool]
var cachedFrontiers: seq[seq[seq[AffinePair]]]
var cacheReady: seq[bool]
var maximumBudget = 0
var depthPowers: seq[float64]

proc comesFirst(leftPair: AffinePair, rightPair: AffinePair): bool =
  if leftPair.scaledPart == rightPair.scaledPart:
    return leftPair.fixedPart > rightPair.fixedPart
  return leftPair.scaledPart > rightPair.scaledPart

proc sortPairs(pairs: var seq[AffinePair], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  var leftIndex = lowIndex
  var rightIndex = highIndex
  let pivotPair = pairs[(lowIndex + highIndex) div 2]
  while leftIndex <= rightIndex:
    while comesFirst(pairs[leftIndex], pivotPair):
      leftIndex += 1
    while comesFirst(pivotPair, pairs[rightIndex]):
      rightIndex -= 1
    if leftIndex <= rightIndex:
      swap pairs[leftIndex], pairs[rightIndex]
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex:
    sortPairs(pairs, lowIndex, rightIndex)
  if leftIndex < highIndex:
    sortPairs(pairs, leftIndex, highIndex)

proc prunePairs(candidatePairs: seq[AffinePair]): seq[AffinePair] =
  var sortedPairs = candidatePairs
  if sortedPairs.len > 1:
    sortPairs(sortedPairs, 0, sortedPairs.len - 1)
  var skyLine = newSeq[AffinePair]()
  var bestFixed = -1e300
  for candidate in sortedPairs:
    if candidate.fixedPart > bestFixed + 1e-12:
      skyLine.add candidate
      bestFixed = candidate.fixedPart
  if skyLine.len <= depthPowers.len:
    return skyLine
  var bestIndexes = newSeq[int](depthPowers.len)
  var bestValues = newSeq[float64](depthPowers.len)
  for depthIndex in 0 .. depthPowers.len - 1:
    bestIndexes[depthIndex] = -1
    bestValues[depthIndex] = -1e300
  for pairIndex in 0 .. skyLine.len - 1:
    let currentPair = skyLine[pairIndex]
    for depthIndex in 0 .. depthPowers.len - 1:
      let projectedValue = depthPowers[depthIndex] * currentPair.scaledPart +
                           currentPair.fixedPart
      if projectedValue > bestValues[depthIndex] + 1e-12:
        bestValues[depthIndex] = projectedValue
        bestIndexes[depthIndex] = pairIndex
  var envelope = newSeq[AffinePair]()
  for pairIndex in bestIndexes:
    if pairIndex >= 0:
      envelope.add skyLine[pairIndex]
  return envelope
```

The skyline removes pairs beaten in both parts.
The envelope keeps only pairs that win at one depth.
Subtrees outside the cycle are cached across tries.

**Tree knapsack.** Each child either keeps its link or moves to the base.

```nim
proc buildFrontier(nodeIndex: int): seq[seq[AffinePair]] =
  if not cycleFlags[nodeIndex] and cacheReady[nodeIndex]:
    return cachedFrontiers[nodeIndex]
  let budgetLimit = maximumBudget
  result = newSeq[seq[AffinePair]](budgetLimit + 1)
  result[0].add AffinePair(scaledPart: nodeCosts[nodeIndex], fixedPart: 0.0)
  for childIndex in childrenOf[nodeIndex]:
    let childFrontier = buildFrontier(childIndex)
    var nextFrontier = newSeq[seq[AffinePair]](budgetLimit + 1)
    for budget in 0 .. budgetLimit:
      var combined = newSeq[AffinePair]()
      for usedCuts in 0 .. budget:
        for parentPair in result[budget - usedCuts]:
          for childPair in childFrontier[usedCuts]:
            combined.add AffinePair(
              scaledPart: parentPair.scaledPart + keepFactor * childPair.scaledPart,
              fixedPart: parentPair.fixedPart + childPair.fixedPart)
        if usedCuts + 1 <= budget and not forbiddenCuts[childIndex]:
          for parentPair in result[budget - usedCuts - 1]:
            for childPair in childFrontier[usedCuts]:
              combined.add AffinePair(
                scaledPart: parentPair.scaledPart,
                fixedPart: parentPair.fixedPart + keepFactor * childPair.scaledPart +
                           childPair.fixedPart)
      nextFrontier[budget] = prunePairs(combined)
    result = nextFrontier
  if not cycleFlags[nodeIndex]:
    cachedFrontiers[nodeIndex] = result
    cacheReady[nodeIndex] = true
```

Budgets count exact changes, so none are wasted.
A banned cycle link cannot be redirected in this try.
Caching avoids rebuilding untouched subtrees.

**Driver and output.** Every cycle cut gives one candidate safety.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let nexusCount = nextInt(inputData, scanPos)
  if nexusCount == 0:
    break
  let modificationLimit = nextInt(inputData, scanPos)
  let keepFactorInput = nextReal(inputData, scanPos)
  var originalParents = newSeq[int](nexusCount)
  for nexusIndex in 0 .. nexusCount - 1:
    originalParents[nexusIndex] = nextInt(inputData, scanPos) - 1
  nodeCosts = newSeq[float64](nexusCount)
  for nexusIndex in 0 .. nexusCount - 1:
    nodeCosts[nexusIndex] = nextReal(inputData, scanPos)

  var cycleNodes = newSeq[int]()
  var currentNode = 0
  while true:
    cycleNodes.add currentNode
    currentNode = originalParents[currentNode]
    if currentNode == 0:
      break

  keepFactor = keepFactorInput
  cycleFlags = newSeq[bool](nexusCount)
  for cycleNode in cycleNodes:
    cycleFlags[cycleNode] = true
  cachedFrontiers = newSeq[seq[seq[AffinePair]]](nexusCount)
  cacheReady = newSeq[bool](nexusCount)
  maximumBudget = modificationLimit
  depthPowers = newSeq[float64](nexusCount + 1)
  for depthIndex in 0 .. nexusCount:
    depthPowers[depthIndex] = pow(keepFactor, float64(depthIndex))
  var bestSafety = -1.0
  for cutPosition in 1 .. cycleNodes.len:
    var effectiveParents = newSeq[int](nexusCount)
    effectiveParents[0] = -1
    for nexusIndex in 1 .. nexusCount - 1:
      effectiveParents[nexusIndex] = originalParents[nexusIndex]
    var cycleCuts = 0
    if cutPosition < cycleNodes.len:
      effectiveParents[cycleNodes[cutPosition]] = 0
      cycleCuts = 1
    let remainingBudget = modificationLimit - cycleCuts
    if remainingBudget < 0:
      continue
    childrenOf = newSeq[seq[int]](nexusCount)
    for nexusIndex in 1 .. nexusCount - 1:
      childrenOf[effectiveParents[nexusIndex]].add nexusIndex
    forbiddenCuts = newSeq[bool](nexusCount)
    for cycleIndex in 1 .. cutPosition - 1:
      forbiddenCuts[cycleNodes[cycleIndex]] = true
    maximumBudget = modificationLimit
    let rootFrontier = buildFrontier(0)
    var cycleLength = cycleNodes.len
    if cutPosition < cycleNodes.len:
      cycleLength = cutPosition + 1
    let cycleGain = 1.0 / (1.0 - pow(keepFactor, float64(cycleLength)))
    for budget in 0 .. remainingBudget:
      for answerPair in rootFrontier[budget]:
        let safetyValue = cycleGain * (answerPair.scaledPart + answerPair.fixedPart)
        if safetyValue > bestSafety:
          bestSafety = safetyValue

  appendOutput(formatFloat(bestSafety, ffDecimal, 2))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The base's own link stays fixed.
One buffered line is written per case.
The largest candidate becomes the answer.

## Complexity

Tree knapsack work dominates each try.

| phase | time | space |
|---|---|---|
| input read | one pass over links and costs | one input string |
| pruning | sort and project each frontier | pairs per budget |
| knapsack | one pass over children and budgets | frontiers per node |
| output | one line per case | block buffer |

Each node keeps at most one pair per depth after projection.

| measure | Big O |
|---|---|
| time | O(L * N^2 * M^2) worst case |
| space | O(N * M * N) for cached frontiers |

Trying every link without affine pairs would explode across nested cuts.

The cycle gain and the cached tree knapsack give the best safety.
