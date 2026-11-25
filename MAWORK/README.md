# MAWORK — Men at Work (SPOJ)
<https://www.spoj.com/problems/MAWORK/>

## Problem

A driver crosses a city of streets that open and close on fixed schedules. The shortest trip must respect every roadblock on arrival.

The input starts with the case count. Each case gives a grid size, an initial grid of open and blocked cells, and one period digit per cell. Print the earliest arrival time at the bottom-right cell, or `NO`.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Cases | at most 10 |
| Grid side `N` | 2 to 25 |
| Period digit | 0 to 9 |
| Judge time | 9000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

The period cycle stays small enough for a state graph.

Sample input and output:

Input:

```
2
10
.*********
........**
*.******.*
*.******.*
*.******.*
*........*
*.******.*
*.******.*
*........*
********..
0000000000
0000000000
0000000000
0000000000
0000000000
0123456780
0000000000
0000000000
0123456780
0000000000
3
...
**.
**.
021
002
000
```

Output:

```
34
NO
```

## Idea

Track time by its remainder on one shared clock. Think of blinking traffic lights whose periods all realign every 5040 seconds.

The program runs breadth-first search (a shortest-path walk over states) on cell plus time remainder. Five moves leave each state: north, south, west, east, and stay. Each state costs five checks. A search over raw time would revisit the same cell and phase many times.

Takeaway: the clock remainder makes the state graph finite.

## Why It Works

Every cell repeats its status on a common cycle.

1. A cell with period `d` alternates open and blocked in blocks of `d` seconds.
2. The least common multiple of `2d` for digits 1 to 9 is 5040.
3. `isCellOpen` flips the initial status when the phase index is odd.
4. A state packs a cell index and `arrivalTime mod 5040`.
5. Breadth-first search visits states by increasing time, so the first target hit is earliest.

The terms are:

| Term | Meaning |
| --- | --- |
| `cycleLength` | 5040, the shared period |
| `periodLength` | Working and resting block length |
| `currentState` | Cell index times 5040 plus time remainder |
| `seenGeneration` | Visit stamp for the current case |

One stamp per case avoids clearing the whole visited array.

A script checked the small sample grid:

| Cell | Initial | Period | Status at times 0, 1, 2, 3 |
| --- | --- | --- | --- |
| (0, 0) | open | 0 | open, open, open, open |
| (0, 1) | open | 2 | open, open, blocked, blocked |
| (1, 2) | blocked | 2 | blocked, blocked, open, open |
| (2, 2) | open | 0 | open, open, open, open |

The fixed walls isolate the target, so the answer is `NO`.

## Code

**Constants.**

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const cycleLength = 5040
const maxGridSize = 25
const maxCellCount = maxGridSize * maxGridSize
const maxStateCount = maxCellCount * cycleLength
const stayDirection = 4
```

`cycleLength` is the least common multiple of all doubled periods. `maxStateCount` sizes the queue and visit stamps.

**Input and output helpers.**

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The program joins input lines into one buffer. `nextToken` grabs each grid row without copying spaces. Answers collect in one output buffer.

**Cell status.**

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

Period zero keeps the initial status. Other cells flip once per odd phase. One query costs one division.

**Breadth-first search.**

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

The queue holds packed states. Each level adds one second of time. The search stops at the first arrival at the target.

**Final flush.**

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

One write emits all remaining answers. The search leaves no per-case output writes.

## Complexity

The state graph bounds the search.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total characters) | O(Input size) |
| Search | O(5 * N^2 * 5040) | O(N^2 * 5040) |
| Output | O(T) | O(1) |

Each cell has one state per time remainder.

| Measure | Bound |
| --- | --- |
| Time | O(N^2 * 5040) per case |
| Space | O(N^2 * 5040) per case |

At most 3.15 million states fit the fixed arrays.

Searching raw time would repeat states until the schedule gap grows without bound.
