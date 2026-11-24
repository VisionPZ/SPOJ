## Problem

Read a list of test cases. Each case starts with `n` states and a time budget `t`, followed by two `n` by `n` tables of travel times and tolls. State 0 is the port and state `n - 1` is the market. Print the smallest total toll of a route that reaches the market within `t`, followed by that route's travel time.

| Quantity | Bound |
| --- | --- |
| Number of states `n` | 3 to 50 |
| Time budget `t` | less than 1000 |
| Judge time limit | 3000 ms |
| Judge memory limit | 1536 MB |

The toll is the primary goal. The travel time of the chosen route is reported second.

## Idea

Treat each pair of a state and an elapsed time as one node of an expanded graph. A shortest-path relaxation finds the least toll for every arrival time, and the answer takes the earliest such time. Listing every route would grow exponentially, so the expanded graph keeps the search small.

## Why It Works

An expanded node is a pair of a state and an elapsed time. The program stores it as one integer so that every table stays flat.

The packing has three parts:

- The state number multiplied by `timeStride` selects the block for one state.
- `timeStride` is the budget plus one, so it gives one slot per time from 0 to `t`.
- `elapsedTime` picks the slot inside that block.

From an expanded node, the program follows each outgoing edge. The next node is `targetNode`, the next time is `currentTime + travelTimes[rowOffset + targetNode]`, and the added cost is `tollAmounts[rowOffset + targetNode]`. An edge is skipped when its arrival time passes `timeLimit`. The row offset `currentNode * stateCount` points at the current state's row in both flat tables.

The relaxation updates a node only when it finds a strictly smaller toll. Each update pushes the node once into a queue, so the process ends with the least toll for every reachable expanded node. The final scan walks arrival times from 0 upward and updates only on a strict improvement. That scan returns the earliest time among all routes with the least toll.

The sample has four states and a budget of 7. The table below lists the least toll for each state at each exact arrival time, with a dash for unreachable pairs. It comes from a small script that replays the same relaxation.

| State | t=0 | t=1 | t=2 | t=3 | t=4 | t=5 | t=6 | t=7 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | 0 | - | - | - | - | 4 | 14 | 14 |
| 1 | - | - | - | 4 | - | 2 | 7 | 9 |
| 2 | - | - | 2 | - | - | 5 | 12 | 3 |
| 3 | - | - | - | 7 | 7 | - | 6 | 10 |

At the market, state 3, the least toll is 6 and it first appears at time 6. The program prints `6 6`.

## Code

The scanner reads the whole input buffer once and walks it by index. It accepts an optional minus sign, although the problem uses non-negative values.

```nim
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
```

The digit loop runs once per input character, so its cost equals the input length. Skipping separators lets blank lines between cases need no special handling.

The input accumulates in one string through line reads. The output buffer holds completed lines and flushes only after 256 KiB.

```nim
var inputData = ""
var inputLine: TaintedString = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""
var i = 0

while true:
  let stateCount = nextInt(inputData, i)
  let timeLimit = nextInt(inputData, i)
  if stateCount == 0 and timeLimit == 0:
    break
```

The `0 0` pair ends the stream, so the loop has no separate counter. Both buffers keep their capacity across cases.

Each case reads two flat tables of `stateCount * stateCount` cells and prepares one slot per expanded node.

```nim
  let tableSize = stateCount * stateCount
  var travelTimes = newSeq[int](tableSize)
  var tollAmounts = newSeq[int](tableSize)
  for j in 0 .. tableSize - 1:
    travelTimes[j] = nextInt(inputData, i)
  for j in 0 .. tableSize - 1:
    tollAmounts[j] = nextInt(inputData, i)

  let timeStride = timeLimit + 1
  let totalStates = stateCount * timeStride
  let queueCapacity = totalStates + 1
  var minTolls = newSeq[int](totalStates)
  var queuePresent = newSeq[bool](totalStates)
  var stateQueue = newSeq[int](queueCapacity)
  for j in 0 .. totalStates - 1:
    minTolls[j] = infiniteToll
    queuePresent[j] = false
```

The two table loops have `tableSize` iterations each. The queue capacity is `totalStates + 1` because the presence flag allows at most one queued entry per expanded node.

The start node is the port at time 0, with toll 0. All other expanded nodes begin unreachable.

```nim
  var queueHead = 0
  var queueTail = 0
  stateQueue[queueTail] = 0
  queueTail = (queueTail + 1) mod queueCapacity
  queuePresent[0] = true
  minTolls[0] = 0
```

Circular queue indices wrap with `mod`, so the queue never reallocates. The single seed node is `0` under the packing formula.

The relaxation loop drains the queue and tries every outgoing edge of each expanded node.

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

The division and modulo recover the two parts of a packed state. The inner loop has `n` iterations, and each expanded node can improve several times, so the loop costs O(n² t) per case in total.

The answer scan and the buffered write finish the case.

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

The scan has `t + 1` iterations and uses a strict comparison to keep the earliest time. The final write flushes any remaining bytes after the last case.

## Complexity

Reading a case costs O(n²) because both tables have `n²` cells. The relaxation relaxes `n` edges per expanded node, so it costs O(n² t) per case. The answer scan costs O(t). Total time per case is O(n² t), and total space is O(n t) for the flat distance and queue arrays.

Enumerating every route would take time exponential in `n`, because routes may revisit states. The expanded graph reduces that to a polynomial number of states.
