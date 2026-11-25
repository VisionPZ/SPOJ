# FISHER — Fishmonger (SPOJ)
<https://www.spoj.com/problems/FISHER/>

## Problem

A fishmonger drives fish from the port to the market through many small states. Every border crossing costs a toll, and the fish spoil after a fixed number of minutes.

Each case starts with two integers n and t. State 0 is the port and state n-1 is the market. Next come n rows of travel times, then n rows of tolls, each row holding n integers. A blank line separates tables, and the pair `0 0` ends the stream. Print the smallest total toll, then a space, then that route's travel time.

The judge limits are:

| Item | Value |
| --- | --- |
| States n | 3 to 50 |
| Time budget t | less than 1000 |
| Time limit | 3 s |
| Memory limit | 1536 MB |

The toll comes first, so time is a constraint rather than the goal.

The sample input reads:

```text
4 7
0 5 2 3
5 0 2 3
3 1 0 2
3 3 2 0

0 2 2 7
2 0 1 2
2 2 0 5
7 2 5 0

0 0
```

The sample output reads:

```text
6 6
```

## Idea

Treat each state and each elapsed minute as one stop, like adding time rows to a timetable. This expanded graph (one node per state-time pair) lets a shortest-path search minimize tolls while respecting the deadline. Each edge relaxation costs one arithmetic step, and each expanded node has n outgoing edges. Listing every route would grow exponentially, because routes may revisit states. Takeaway: add time to the node, then relax edges.

## Why It Works

1. An expanded node packs a state and an arrival time into one integer.
2. The stride `timeLimit + 1` gives one slot per time from 0 through t.
3. Node `targetNode * timeStride + arrivalTime` names the state after one crossing.
4. An edge is skipped when its arrival time exceeds the budget.
5. Relaxation keeps only a strictly smaller toll for each expanded node.
6. The final scan walks arrival times upward and keeps the first least toll, so it reports the earliest time.

The table names each quantity in the packing.

| Term | Meaning |
| --- | --- |
| timeStride | budget plus one, the size of one state's time block |
| currentState | packed node, split by division and modulo |
| rowOffset | `currentNode * stateCount`, the start of one table row |
| candidateToll | toll so far plus the crossed border's toll |

These four quantities define one packed node.

A script replayed the relaxation for the sample. The market's least toll at each exact arrival time is:

| Arrival time | 3 | 4 | 5 | 6 | 7 |
| --- | --- | --- | --- | --- | --- |
| Least toll | 7 | 7 | not reached | 6 | 10 |

The smallest toll is 6, and it first appears at time 6. The program prints `6 6`.

## Code

**Scanner and buffers.** The code reads the whole input once and parses integers by index.

```nim
const infiniteToll = high(int) div 4
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] != '-' and
      (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var signValue = 1
  if i < dataLength and inputData[i] == '-':
    signValue = -1
    i += 1
  var numberValue = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    numberValue = numberValue * 10 + (int(inputData[i]) - 48)
    i += 1
  return signValue * numberValue

var inputData = ""
var inputLine: TaintedString = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""
var i = 0
```

The digit loop visits each input character once. Skipping separators lets blank lines between cases need no special branch. The sign branch preserves negative values even though the statement uses non-negative ones. Both buffers keep their capacity across cases.

**Case header and tables.** The driver reads the two flat tables until it meets `0 0`.

```nim
while true:
  let stateCount = nextInt(inputData, i)
  let timeLimit = nextInt(inputData, i)
  if stateCount == 0 and timeLimit == 0:
    break

  let tableSize = stateCount * stateCount
  var travelTimes = newSeq[int](tableSize)
  var tollAmounts = newSeq[int](tableSize)
  for j in 0 .. tableSize - 1:
    travelTimes[j] = nextInt(inputData, i)
  for j in 0 .. tableSize - 1:
    tollAmounts[j] = nextInt(inputData, i)
```

The `0 0` pair ends the stream, so the loop needs no separate case counter. Each table loop has `stateCount` squared iterations. Storing tables flat avoids a nested sequence per row.

**Expanded node setup.** The program reserves one slot per state-time pair.

```nim
  let timeStride = timeLimit + 1
  let totalStates = stateCount * timeStride
  let queueCapacity = totalStates + 1
  var minTolls = newSeq[int](totalStates)
  var queuePresent = newSeq[bool](totalStates)
  var stateQueue = newSeq[int](queueCapacity)
  for j in 0 .. totalStates - 1:
    minTolls[j] = infiniteToll
    queuePresent[j] = false

  var queueHead = 0
  var queueTail = 0
  stateQueue[queueTail] = 0
  queueTail = (queueTail + 1) mod queueCapacity
  queuePresent[0] = true
  minTolls[0] = 0
```

The queue holds at most one entry per expanded node, so its capacity is `totalStates + 1`. The seed node is `0` under the packing formula. Circular indices wrap with modulo, so the queue never reallocates. All unvisited nodes start at `infiniteToll`.

**Relaxation.** The queue drains expanded nodes and tries every outgoing crossing.

```nim
  while queueHead != queueTail:
    let currentState = stateQueue[queueHead]
    queueHead = (queueHead + 1) mod queueCapacity
    queuePresent[currentState] = false
    let currentNode = currentState div timeStride
    let currentTime = currentState mod timeStride
    let baseToll = minTolls[currentState]
    let rowOffset = currentNode * stateCount
    for targetNode in 0 .. stateCount - 1:
      let arrivalTime = currentTime + travelTimes[rowOffset + targetNode]
      if arrivalTime > timeLimit:
        continue
      let candidateToll = baseToll + tollAmounts[rowOffset + targetNode]
      let targetState = targetNode * timeStride + arrivalTime
      if candidateToll < minTolls[targetState]:
        minTolls[targetState] = candidateToll
        if not queuePresent[targetState]:
          queuePresent[targetState] = true
          stateQueue[queueTail] = targetState
          queueTail = (queueTail + 1) mod queueCapacity
```

Division and modulo recover the two halves of a packed state. The inner loop has n iterations, one per target state. The presence flag prevents duplicate queue entries. Each improvement costs constant arithmetic.

**Answer and flush.** The final scan picks the earliest least-toll arrival.

```nim
  let destinationBase = (stateCount - 1) * timeStride
  var bestToll = infiniteToll
  var bestTime = 0
  for elapsedTime in 0 .. timeLimit:
    let reachedToll = minTolls[destinationBase + elapsedTime]
    if reachedToll < bestToll:
      bestToll = reachedToll
      bestTime = elapsedTime

  outputBuffer.add $bestToll
  outputBuffer.add ' '
  outputBuffer.add $bestTime
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan has `t + 1` iterations and updates only on a strict improvement. That strict rule keeps the earliest time among equal tolls. The final write flushes any bytes left below the block size.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read two tables | O(n²) | O(n²) |
| Relax expanded nodes | O(n² t) | O(n t) |
| Scan answer times | O(t) | O(1) |

The relaxed search dominates each case.

Each expanded node relaxes n edges, so the search dominates a case.

| Measure | Bound |
| --- | --- |
| Per case | O(n² t) time |
| Per case | O(n t) space |
| Queue operations | O(1) amortized each |

Listing every route takes time exponential in n, because routes may revisit states. The expanded graph reduces the search to a polynomial number of states.
