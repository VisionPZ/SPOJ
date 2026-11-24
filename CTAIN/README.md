## Problem

Each case gives up to four containers that start full. It gives each capacity and each requested final amount. Print the fewest moves that reach the request, or NO when no sequence exists. A move pours a whole content into a roomy container, fills a container from another, or empties one into a drain.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 20 |
| Containers | 1 to 4 |
| Capacity | 1 to 49 |
| Requested amount | 0 to capacity |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The capacity bound of 49 keeps every state in one fixed array.

## Idea

Breadth-first search over water amounts finds the fewest moves. One integer index in base 50 holds all four amounts, so a state is one array slot. A move changes that index by one fixed product, and the search expands each state once.

Searching move sequences repeats states. Breadth-first search visits each state once and keeps its first distance.

Cost per state: at most four drains and twelve pours, each in constant time.

## Why It Works

Every amount is an integer from 0 to its capacity. Base 50 gives each four-amount tuple a unique index below 50^4. The stride of container i is 50^(3-i).

Two index updates generate every allowed move:

- Drain i: subtract amount_i times stride_i.
- Pour i to j: move the smaller of amount_i and room_j, where room_j is capacity_j minus amount_j. Add the moved amount times (stride_j minus stride_i).

Both updates keep the index inside the array. The pour update covers both named pours. When amount_i fits in the room, it pours the whole content. Otherwise it fills container j to the top and leaves a remainder in container i.

The first visit to a state uses the fewest moves. The distance array stores moves plus one, so zero marks an unused slot. After each case, the program clears only the slots it used.

A script in gen.py prints the shortest path for the sample case:

```
start (3, 5, 5)
1 drain 1 -> (0, 5, 5)
2 fill 1 from 2 -> (3, 2, 5)
3 drain 1 -> (0, 2, 5)
4 pour 2 into 1 -> (2, 0, 5)
5 fill 1 from 3 -> (3, 0, 4)
6 drain 1 -> (0, 0, 4)
```

The sixth move reaches the request, which matches the sample answer.

## Code

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

The read loop ends at end of file. The scanner skips blank lines and spaces. The buffer flushes only after 256 KiB.

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

The search loop runs at most once per reachable state. Decoding divides by 50 four times. Clearing only visited slots keeps the cases independent.

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

The loop runs once per case, at most 20 times. Missing containers keep capacity zero. One final write flushes the buffer.

## Complexity

Reading and scanning take O(input size) time and space for one buffer.

Each search takes O(S) time and O(S) space, where S is the number of reachable states. S never exceeds 50^4, or 6,250,000 states. The array uses that bound, so the space stays fixed. Total time is O(20 * S) and total space is O(50^4).

Searching move sequences without storing visited states repeats work and grows with the move count.
