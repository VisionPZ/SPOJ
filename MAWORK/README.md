## Problem

Read several test cases. Each case gives an N by N grid of open and blocked cells at time zero. A second N by N grid gives each cell a period digit from 0 to 9. A positive digit d makes the cell alternate between blocked and open every d time units. Zero freezes the cell. A car starts at the top-left cell at time zero. Each move to a neighbour or stay costs one unit. The destination cell must be open at arrival. Print the earliest arrival time at the bottom-right cell, or print NO.

| Quantity | Bound |
| --- | --- |
| Test cases | 10 |
| Grid side | 25 |
| Period digit | 9 |
| Time limit | 9000 ms |
| Memory limit | 1536 MB |

The small grid hides a long time cycle that drives the design.

## Idea

Track time by its remainder modulo 5040. That number is the least common multiple of 2d for every digit d from 1 to 9. A cell state depends only on its cell index, its period digit, and time modulo 2d. So a search state is one cell plus one time remainder. Breadth-first search over these states returns the first arrival time. It checks five moves per state. A search over raw time would revisit the same cell and phase at many different times.

Cost: five neighbour checks for each cell and remainder pair.

## Why It Works

A cell with digit d and initial state s is open at time t when the parity of t div d matches s. The cell state repeats every 2d units. The grid repeats every 5040 units, the least common multiple of 2, 4, 6, 8, 10, 12, 14, 16 and 18. Two visits to the same cell and remainder have identical future moves. The later visit can be dropped. Breadth-first search visits states in time order, so the first arrival is minimal.

- `phaseIndex = (arrivalTime mod cycleLength) div duration` finds the alternating block at arrival.
- `nextState = nextCell * cycleLength + (arrivalTime mod cycleLength)` packs a cell and a remainder into one number.
- `seenGeneration[nextState]` stores the test case number of the first visit.

A script-generated trace shows the two edge shapes:

```
2x2 all open, all period 0
t=0 reachable (0,0); t=1 (0,1),(1,0); t=2 (1,1)
answer 2

3x3 sample: (1,2) has period 2 and starts open
t=0 (0,2) period 1 open=True  (1,2) period 2 open=True
t=1 (0,2) period 1 open=False  (1,2) period 2 open=True
t=2 (0,2) period 1 open=True  (1,2) period 2 open=False
t=3 (0,2) period 1 open=False  (1,2) period 2 open=False
t=4 (0,2) period 1 open=True  (1,2) period 2 open=True
t=5 (0,2) period 1 open=False  (1,2) period 2 open=True
t=6 (0,2) period 1 open=True  (1,2) period 2 open=False
t=7 (0,2) period 1 open=False  (1,2) period 2 open=False
arriving at (1,2) from (0,2) always takes an odd time, so the car is stuck
answer NO
```

The car reaches (1,2) only at odd times, when that cell is blocked.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const cycleLength = 5040
const maxGridSize = 25
const maxCellCount = maxGridSize * maxGridSize
const maxStateCount = maxCellCount * cycleLength
const stayDirection = 4
```

Seven constants fix the buffers and the time cycle. Digit 8 needs a 16 unit cycle, so the full grid needs 5040. The constants cost no runtime work.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  let tokenStart = position
  while position < data.len and data[position] > ' ':
    position += 1
  return data[tokenStart .. position - 1]
```

The input loop reads every line into one buffer. The token reader keeps leading zeros in schedule rows, which integer scanning would lose. Scanning costs one pass over the input.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One output buffer collects the answers. It flushes every 256 KiB and reuses the same storage. Each answer costs one string add.

```nim
var initialOpen = newSeq[bool](maxCellCount)
var periodLength = newSeq[int](maxCellCount)
var seenGeneration = newSeq[int](maxStateCount)
var stateQueue = newSeq[int](maxStateCount)
var generation = 0

proc isCellOpen(cellIndex: int, arrivalTime: int): bool =
  let duration = periodLength[cellIndex]
  if duration == 0:
    return initialOpen[cellIndex]
  let phaseIndex = (arrivalTime mod cycleLength) div duration
  if phaseIndex mod 2 == 1:
    return not initialOpen[cellIndex]
  return initialOpen[cellIndex]
```

Four arrays are allocated once at the maximum size. The generation mark avoids clearing 3.15 million entries per case. The open test costs one division and one remainder.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let gridSize = nextInt(inputData, scanPos)
  let cellCount = gridSize * gridSize
  for rowIndex in 0..<gridSize:
    let gridLine = nextToken(inputData, scanPos)
    for columnIndex in 0..<gridSize:
      let cellIndex = rowIndex * gridSize + columnIndex
      initialOpen[cellIndex] = gridLine[columnIndex] == '.'
  for rowIndex in 0..<gridSize:
    let scheduleLine = nextToken(inputData, scanPos)
    for columnIndex in 0..<gridSize:
      let cellIndex = rowIndex * gridSize + columnIndex
      periodLength[cellIndex] = int(scheduleLine[columnIndex]) - firstDigitValue
  generation += 1
  let targetCell = cellCount - 1
  var answer = -1
  if isCellOpen(0, 0):
    var head = 0
    var tail = 0
    stateQueue[tail] = 0
    tail += 1
    seenGeneration[0] = generation
    var currentTime = 0
    while head < tail and answer < 0:
      let levelEnd = tail
      while head < levelEnd and answer < 0:
        let currentState = stateQueue[head]
        head += 1
        let cellIndex = currentState div cycleLength
        let rowIndex = cellIndex div gridSize
        let columnIndex = cellIndex mod gridSize
        let arrivalTime = currentTime + 1
        for direction in 0..stayDirection:
          var nextRow = rowIndex
          var nextColumn = columnIndex
          if direction == 0:
            nextRow -= 1
          elif direction == 1:
            nextRow += 1
          elif direction == 2:
            nextColumn -= 1
          elif direction == 3:
            nextColumn += 1
          if nextRow < 0 or nextRow >= gridSize or nextColumn < 0 or nextColumn >= gridSize:
            continue
          let nextCell = nextRow * gridSize + nextColumn
          if not isCellOpen(nextCell, arrivalTime):
            continue
          if nextCell == targetCell:
            answer = arrivalTime
            break
          let nextState = nextCell * cycleLength + (arrivalTime mod cycleLength)
          if seenGeneration[nextState] != generation:
            seenGeneration[nextState] = generation
            stateQueue[tail] = nextState
            tail += 1
      currentTime += 1
  if answer < 0:
    appendOutput("NO")
  else:
    appendOutput($answer)
  outputBuffer.add '\n'
```

The parse loop reads two N by N blocks per case. The target check runs before the seen test, so the first arrival wins. The queue holds one entry per state, and the search stops when that queue empties. Five moves cost five checks per state.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

The last flush writes any remaining answers. It runs once after all cases. The cost is one stream write.

## Complexity

Parsing costs O(N squared) per case. The search visits at most N squared times 5040 states and checks five moves each. The seen array and the queue hold N squared times 5040 entries. Total time and space are O(N squared times C), with C equal to 5040. A raw-time search has no fixed bound and revisits identical cell and phase pairs.
