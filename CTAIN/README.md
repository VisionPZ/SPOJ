# CTAIN — Containers (SPOJ)

<https://www.spoj.com/problems/CTAIN/>

## Problem

A warehouse starts with up to four containers full of water. A worker pours, fills, and drains them to reach a requested set of amounts in as few moves as possible.

Input: one integer for the case count, a blank line, then one case per block. Each case gives the container count, the capacities, and the requested final amounts, with a blank line between cases.

Output: the fewest moves that reach the request, or `NO` when no sequence works.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Test cases | at most 20 |
| Containers | 1 to 4 |
| Capacity | 1 to 49 |
| Requested amount | 0 to capacity |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The capacity bound of 49 keeps every state in one fixed array.

The sample input and output:

```
2

3
3 5 5
0 0 4

2
20 25
10 16

```

```
6
NO
```

## Idea

Search states in order of moves, like finding the fewest transfers between jars by walking a map of every possible fill. Breadth-first search visits each state once and keeps its first distance.

The program packs all four amounts into one integer index in base 50. Each legal move changes that index by a fixed product, so generating neighbours costs constant work.

Each state expands at most four drains and twelve pours. Searching move sequences without storing visited states repeats work and grows with the move count.

The base-50 index makes the whole search one array walk.

## Why It Works

Every amount is an integer from zero to its capacity.

1. Base 50 gives each four-amount tuple a unique index below `50^4`, because every capacity is below 50.
2. The stride of container i is `50^(3-i)`, so changing one amount changes the index by a multiple of that stride.
3. A drain subtracts `amount × stride`. A pour moves the smaller of the amount and the free room, then adds the moved volume times the stride difference.
4. The first visit to a state uses the fewest moves, so the stored distance is already minimal.

The index formulas are as follows:

| Term | Meaning |
| --- | --- |
| `strides` | `[125000, 2500, 50, 1]`, the base-50 place values |
| drained index | `currentState - amountI × strides[i]` |
| room | `capacities[j] - amounts[j]` |
| poured index | `currentState - moved × strides[i] + moved × strides[j]` |
| `distances` | moves plus one, so zero marks an unused slot |

After each case, the program clears only the slots it visited.

A script finds the shortest path for the first sample case:

```
start (3,5,5)
1 drain 1        -> (0,5,5)
2 pour 2 to 1    -> (3,2,5)
3 drain 1        -> (0,2,5)
4 pour 2 to 1    -> (2,0,5)
5 pour 3 to 1    -> (3,0,4)
6 drain 1        -> (0,0,4)
```

The sixth move reaches the request, which matches the sample answer.

## Code

**Input and buffers.** One buffer holds the stream, and the output flushes in blocks.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const stateSpaceSize = 6250000
const strides = [125000, 2500, 50, 1]

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop runs once per input line and ends at the end of the file. The scanner skips the blank lines between cases. The buffer flushes only after 256 KiB.

**Search arrays and breadth-first search.** Decoding divides by 50 four times, and clearing touches only visited slots.

```nim
var distances = newSeq[int](stateSpaceSize)
var queue = newSeq[int](stateSpaceSize)
var visitedStates = newSeq[int](0)

proc minimalMoves(targets: array[4, int], capacities: array[4, int], containerCount: int): int =
  var targetState = 0
  var startState = 0
  for i in 0..<containerCount:
    targetState += targets[i] * strides[i]
    startState += capacities[i] * strides[i]
  if startState == targetState:
    return 0
  let firstVisited = visitedStates.len
  distances[startState] = 1
  queue[0] = startState
  visitedStates.add startState
  var head = 0
  var tail = 1
  var answer = -1
  block search:
    while head < tail:
      let currentState = queue[head]
      head += 1
      let nextDistance = distances[currentState] + 1
      var decoded = currentState
      let amount3 = decoded mod 50
      decoded = decoded div 50
      let amount2 = decoded mod 50
      decoded = decoded div 50
      let amount1 = decoded mod 50
      decoded = decoded div 50
      let amount0 = decoded
      var amounts = [amount0, amount1, amount2, amount3]
      for i in 0..<containerCount:
        let amountI = amounts[i]
        if amountI == 0:
          continue
        let drainedState = currentState - amountI * strides[i]
        if distances[drainedState] == 0:
          if drainedState == targetState:
            answer = nextDistance - 1
            break search
          distances[drainedState] = nextDistance
          queue[tail] = drainedState
          tail += 1
          visitedStates.add drainedState
        for j in 0..<containerCount:
          if j == i:
            continue
          let room = capacities[j] - amounts[j]
          if room == 0:
            continue
          let moved = if amountI < room: amountI else: room
          let pouredState = currentState - moved * strides[i] + moved * strides[j]
          if distances[pouredState] == 0:
            if pouredState == targetState:
              answer = nextDistance - 1
              break search
            distances[pouredState] = nextDistance
            queue[tail] = pouredState
            tail += 1
            visitedStates.add pouredState
  for i in firstVisited..<visitedStates.len:
    distances[visitedStates[i]] = 0
  visitedStates.setLen firstVisited
  return answer
```

The search loop runs once per reachable state. Each neighbour is one drain or one pour, and both updates stay inside the array. The clear loop restores only the slots this case touched.

**Case driver.** Missing containers keep a capacity of zero, so the same arrays serve every case.

```nim
let caseCount = nextInt(inputData, scanPos)
for k in 0..<caseCount:
  let containerCount = nextInt(inputData, scanPos)
  var capacities = [0, 0, 0, 0]
  var targets = [0, 0, 0, 0]
  for i in 0..<containerCount:
    capacities[i] = nextInt(inputData, scanPos)
  for i in 0..<containerCount:
    targets[i] = nextInt(inputData, scanPos)
  let answer = minimalMoves(targets, capacities, containerCount)
  if answer < 0:
    appendOutput("NO")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per case, at most 20 times. A negative answer prints `NO`. One final write flushes the buffer.

## Complexity

The search visits each reachable state once and generates a bounded neighbour set.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| State encode | O(4) per case | O(1) |
| Breadth-first search | O(S) per case | O(S) arrays |
| Neighbour generation | O(1) per neighbour | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(S) | O(6250000) |

Here S is the number of reachable states, never more than `50^4`.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(20 × S) across all cases |
| Space | O(50^4) fixed |

Searching move sequences without storing visited states repeats work and grows with the move count.
