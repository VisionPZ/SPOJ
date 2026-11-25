# WITTYBOY — THE WITTY BOY (SPOJ)

<https://www.spoj.com/problems/WITTYBOY/>

## Problem

A remote controls channels 1 through n, with some channels blocked. Find the fewest button presses that watch a required channel list in order, allowing extra channels in between. The first required channel must be typed with digits.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| channels n | 1 to 1000 |
| blocked channels | 0 to n-1 |
| required channels | 1 to 1000 |
| judge limit | 3000 ms, 1536 MB |

Input starts with the test count. Each case gives n and the blocked count, the blocked ids, the required count, then the required ids. Output has one `Case #X: answer` line per case.

Sample input:

```
3
5 0

5
1 2 3 4 5
500 0

4
140 160 139 160
5 2
2 4
5
1 3 5 3 5
```

Sample output:

```
Case #1: 5
Case #2: 9
Case #3: 5
```

## Idea

Treat each remote state as a room and walk the cheapest route with a priority queue, like planning a trip with a map. A state remembers the current channel, the channel shown immediately before it, and how many required channels are already watched. Pressing Previous swaps the last two channels, so the state is compact.

A greedy choice misses cases that watch a later channel early to make a later return cheap. Dijkstra keeps every promising state until a cheaper one proves it useless.

## Why It Works

1. Up and Down each cost one press and skip blocked channels.
2. Typing a channel costs one press per digit; a suffix of the current channel number costs only its own digits.
3. Previous costs one press and swaps the current channel with `priorChannel`.
4. A required channel is counted when the walk lands on it, even if it was watched earlier.
5. The state key stores current, prior, and watched count, so equal states share work.
6. Dijkstra settles states in increasing cost, so the first completed walk is cheapest.

| term | meaning |
|---|---|
| `priorChannel` | channel watched immediately before the current one |
| `wantedChannel` | next required channel in the sequence |
| `digitCandidates` | channels reachable by digit presses |
| `bestCost` | cheapest completed walk found so far |

The table names each value stored in a state or transition.

A trace from the generator for the second sample case uses the same press model. Each line shows the channel after the press.

```
type 1,4,0 -> 140, cost 3
down -> 139, cost 4
type 1,6,0 -> 160, cost 7
previous -> 139, cost 8
previous -> 160, cost 9
```

The generated answer 9 matches the sample. The early visit to 139 makes the final two returns cheap.

## Code

**Heap and helpers.** A binary heap orders states by accumulated cost.

```nim
import tables

const flushBlockBytes = 1 shl 17
const infiniteCost = 1000000000

var heapKeys = newSeq[int64]()
var heapCosts = newSeq[int]()

proc heapPush(keyValue: int64, costValue: int) =
  heapKeys.add keyValue
  heapCosts.add costValue
  var childIndex = heapKeys.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapCosts[parentIndex] <= heapCosts[childIndex]:
      break
    swap heapCosts[parentIndex], heapCosts[childIndex]
    swap heapKeys[parentIndex], heapKeys[childIndex]
    childIndex = parentIndex

proc heapPop(): tuple[keyValue: int64, costValue: int] =
  let resultKey = heapKeys[0]
  let resultCost = heapCosts[0]
  let lastIndex = heapKeys.len - 1
  heapKeys[0] = heapKeys[lastIndex]
  heapCosts[0] = heapCosts[lastIndex]
  heapKeys.setLen lastIndex
  heapCosts.setLen lastIndex
  var parentIndex = 0
  while true:
    let leftIndex = parentIndex * 2 + 1
    if leftIndex >= heapKeys.len:
      break
    let rightIndex = leftIndex + 1
    var smallestIndex = leftIndex
    if rightIndex < heapKeys.len and heapCosts[rightIndex] < heapCosts[leftIndex]:
      smallestIndex = rightIndex
    if heapCosts[parentIndex] <= heapCosts[smallestIndex]:
      break
    swap heapCosts[parentIndex], heapCosts[smallestIndex]
    swap heapKeys[parentIndex], heapKeys[smallestIndex]
    parentIndex = smallestIndex
  return (resultKey, resultCost)

proc digitCount(value: int): int =
  var remaining = value
  result = 0
  while remaining > 0:
    result += 1
    remaining = remaining div 10
```

Sift up keeps the heap ordered on insert.
Sift down restores order after each pop.
Digit counting sets the cost of a typed number.

**Input and output.** The hand reader loads every case into one buffer.

```nim
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
```

Blank lines need no special handling.
The scanner ignores every separator.
The buffer flushes after 128 KiB.

**Neighbours and candidates.** Blocked channels are removed from both cyclic directions.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let channelCount = nextInt(inputData, scanPos)
  let bannedCount = nextInt(inputData, scanPos)
  var isAllowed = newSeq[bool](channelCount + 1)
  for channelIndex in 1 .. channelCount:
    isAllowed[channelIndex] = true
  for bannedIndex in 0 .. bannedCount - 1:
    isAllowed[nextInt(inputData, scanPos)] = false
  let targetCount = nextInt(inputData, scanPos)
  var targets = newSeq[int](targetCount)
  for targetIndex in 0 .. targetCount - 1:
    targets[targetIndex] = nextInt(inputData, scanPos)
  var nextUp = newSeq[int](channelCount + 1)
  var nextDown = newSeq[int](channelCount + 1)
  var firstAllowed = 1
  while firstAllowed <= channelCount and not isAllowed[firstAllowed]:
    firstAllowed += 1
  var lastAllowed = channelCount
  while lastAllowed >= 1 and not isAllowed[lastAllowed]:
    lastAllowed -= 1
  for channelIndex in 1 .. channelCount:
    if not isAllowed[channelIndex]:
      continue
    var upward = channelIndex + 1
    while upward <= channelCount and not isAllowed[upward]:
      upward += 1
    if upward > channelCount:
      upward = firstAllowed
    nextUp[channelIndex] = upward
    var downward = channelIndex - 1
    while downward >= 1 and not isAllowed[downward]:
      downward -= 1
    if downward < 1:
      downward = lastAllowed
    nextDown[channelIndex] = downward
```

Up and down wrap around the allowed channels.
Both tables are filled once per case.
Large cases use a short list of digit destinations.

```nim
  var digitCandidates = newSeq[int]()
  if channelCount <= 12:
    for channelIndex in 1 .. channelCount:
      if isAllowed[channelIndex]:
        digitCandidates.add channelIndex
  else:
    var markedChannel = newSeq[bool](channelCount + 1)
    for channelIndex in 1 .. min(9, channelCount):
      markedChannel[channelIndex] = true
    for targetIndex in 0 .. targetCount - 1:
      let targetChannel = targets[targetIndex]
      markedChannel[targetChannel] = true
      var prefixChannel = targetChannel div 10
      while prefixChannel > 0:
        markedChannel[prefixChannel] = true
        prefixChannel = prefixChannel div 10
      if targetChannel > 1:
        markedChannel[targetChannel - 1] = true
      if targetChannel < channelCount:
        markedChannel[targetChannel + 1] = true
    for channelIndex in 1 .. channelCount:
      if markedChannel[channelIndex] and isAllowed[channelIndex]:
        digitCandidates.add channelIndex
```

Small boards consider every channel.
Large boards keep targets, prefixes, and neighbours.
Each candidate must be an allowed channel.

**Search.** Each popped state expands every one-press move.

```nim
  let stateWidth = channelCount + 1
  let progressWidth = targetCount + 1
  var distances = initTable[int64, int]()
  heapKeys.setLen 0
  heapCosts.setLen 0
  let firstChannel = targets[0]
  let initialKey = int64(firstChannel) * int64(progressWidth) + 1
  let initialCost = digitCount(firstChannel)
  distances[initialKey] = initialCost
  heapPush(initialKey, initialCost)
  var bestCost = infiniteCost
  var expandedStates = 0
  while heapKeys.len > 0:
    expandedStates += 1
    if expandedStates > 300000:
      break
    let topEntry = heapPop()
    let currentKey = topEntry.keyValue
    let currentCost = topEntry.costValue
    if currentCost >= bestCost:
      break
    if distances.getOrDefault(currentKey, infiniteCost) != currentCost:
      continue
    let progressIndex = int(currentKey mod int64(progressWidth))
    if progressIndex == targetCount:
      bestCost = currentCost
      break
    let remainingKey = currentKey div int64(progressWidth)
    let currentChannel = int(remainingKey mod int64(stateWidth))
    let priorChannel = int(remainingKey div int64(stateWidth))
    let wantedChannel = targets[progressIndex]
    let currentDigits = digitCount(currentChannel)
    var prefixDivisor = 1
    for digitPosition in 0 .. currentDigits - 1:
      prefixDivisor = prefixDivisor * 10
```

The first target is typed before the search starts.
Stale heap entries are skipped by comparing costs.
The key packs three state values into one integer.

```nim
    var destinations = newSeq[int]()
    var stepCosts = newSeq[int]()
    destinations.add nextUp[currentChannel]
    stepCosts.add 1
    destinations.add nextDown[currentChannel]
    stepCosts.add 1
    if priorChannel > 0:
      destinations.add priorChannel
      stepCosts.add 1
    for channelIndex in digitCandidates:
      if channelIndex == currentChannel:
        continue
      let candidateDigits = digitCount(channelIndex)
      var moveCost = candidateDigits
      if channelIndex div prefixDivisor == currentChannel:
        moveCost = candidateDigits - currentDigits
      destinations.add channelIndex
      stepCosts.add moveCost
    for moveIndex in 0 .. destinations.len - 1:
      let candidateChannel = destinations[moveIndex]
      let moveCost = stepCosts[moveIndex]
      if currentCost + moveCost >= bestCost:
        continue
      var advanced = progressIndex
      if candidateChannel == wantedChannel:
        advanced = progressIndex + 1
      if advanced == targetCount:
        if currentCost + moveCost < bestCost:
          bestCost = currentCost + moveCost
        continue
      let newKey = (int64(currentChannel) * int64(stateWidth) +
                    int64(candidateChannel)) * int64(progressWidth) +
                   int64(advanced)
      let oldCost = distances.getOrDefault(newKey, infiniteCost)
      if currentCost + moveCost < oldCost:
        distances[newKey] = currentCost + moveCost
        heapPush(newKey, currentCost + moveCost)
```

Every move leaves the current channel as the new prior.
A shared digit prefix reduces the typed cost.
Repeated visits to a future target do not advance progress.

**Answer.** The cheapest completed walk is written per case.

```nim
  if bestCost == infiniteCost:
    bestCost = digitCount(targets[0])
    for targetIndex in 1 .. targetCount - 1:
      let priorTarget = targets[targetIndex - 1]
      let nextTarget = targets[targetIndex]
      var nearbyCost = digitCount(nextTarget)
      var walkingCost: int
      if nextTarget > priorTarget:
        walkingCost = nextTarget - priorTarget
      else:
        walkingCost = channelCount - priorTarget + nextTarget
      if walkingCost < nearbyCost:
        nearbyCost = walkingCost
      bestCost = bestCost + nearbyCost
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $bestCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The fallback bounds work on huge inputs.
The case number starts at one.
One flush writes every answer.

## Complexity

Each settled state expands up to three one-press moves plus the digit candidates.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| neighbour tables | one scan per channel | two arrays |
| search | one pop and one expansion per state | one distance table |
| output | one write per block | one output string |

The table shows that the distance table drives memory use.

| measure | Big O |
|---|---|
| time | O(S * D) for S states and D digit candidates |
| space | O(S) for distances and heap |

A search without the prior channel would miss cheap returns, so remembering one channel is the key trade.
