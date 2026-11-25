<https://www.spoj.com/problems/CSLIKAR/>

## Problem

Water spreads across a grid each minute while a hedgehog moves toward the den. Input gives the dimensions and a map using `.`, `*`, `X`, `D` and `S`. Output the shortest safe arrival time or `KAKTUS`.
| item | bound |
|---|---|
| rows and columns | up to 50 |
| starts and dens | exactly one each |
| movement | four neighbours per minute |
| judge limit | 100 ms, 1536 MB |

Water never enters the den or a rock. The hedgehog cannot enter a cell flooded in the same minute.

Sample input:

```
3 6
D...*.
.X.X..
....S.
```

Sample output:

```
6
```

## Idea

Compute when water reaches each cell first, like marking the high-water mark on every square. Then run a second breadth-first search that only enters a cell strictly before its water time. Two linear searches replace a minute-by-minute replay with repeated scans.

Each cell is queued at most once per search. A naive simulation could revisit the whole grid every minute.

The water timetable turns a timing rule into a simple comparison.

## Why It Works

1. Water starts at every `*` cell with time zero.
2. Water spreads to four neighbours unless the cell is a rock or the den.
3. Breadth-first order gives the earliest water time for each cell.
4. The hedgehog starts at time zero and also uses breadth-first order.
5. A move to a cell at time `t+1` requires `t+1` below that cell's water time.
6. The den has an infinite water time, so it stays reachable through water-free routes.

| term | meaning |
|---|---|
| `waterTimes` | earliest flooding minute for each cell |
| `hedgehogTimes` | earliest safe arrival minute for each cell |
| `infiniteTime` | sentinel for cells water cannot reach |
| `escapeTime` | arrival minute at the den |

For the sample, water blocks the direct upper route. The hedgehog takes six moves around the rocks to reach the den.

The comparison is strict, which rejects cells flooded in the same minute. All times are integers, so no rounding applies.

## Code

**Reader and map storage.** The scanner loads dimensions and map characters.

```nim
const flushBlockBytes = 1 shl 17
const infiniteTime = 1000000000

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

Line breaks are skipped while reading cells.
The map is stored as one flat character array.
The output buffer collects a single result line.

**Setup and neighbours.** Queues and sentinels are prepared before both searches.

```nim
let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
var cells = newSeq[char](rowCount * columnCount)
for cellIndex in 0 .. rowCount * columnCount - 1:
  while scanPos < inputData.len and (inputData[scanPos] == '\n' or inputData[scanPos] == '\r' or inputData[scanPos] == ' '):
    scanPos += 1
  cells[cellIndex] = inputData[scanPos]
  scanPos += 1

var waterTimes = newSeq[int](rowCount * columnCount)
var hedgehogTimes = newSeq[int](rowCount * columnCount)
for cellIndex in 0 .. rowCount * columnCount - 1:
  waterTimes[cellIndex] = infiniteTime
  hedgehogTimes[cellIndex] = -1
var waterQueue = newSeq[int](rowCount * columnCount)
var hedgehogQueue = newSeq[int](rowCount * columnCount)
var waterHead = 0
var waterTail = 0
var hedgehogHead = 0
var hedgehogTail = 0
var startCell = -1
var denCell = -1
for cellIndex in 0 .. rowCount * columnCount - 1:
  if cells[cellIndex] == '*':
    waterTimes[cellIndex] = 0
    waterQueue[waterTail] = cellIndex
    waterTail += 1
  elif cells[cellIndex] == 'S':
    startCell = cellIndex
  elif cells[cellIndex] == 'D':
    denCell = cellIndex

hedgehogQueue[hedgehogTail] = startCell
hedgehogTail += 1
hedgehogTimes[startCell] = 0
```

Initial water cells get time zero.
The start cell enters the hedgehog queue.
Neighbour indices handle the four grid directions.

**Neighbour lookup.** Four directions map to flat cell indices.

```nim
proc rowOf(cellIndex: int): int =
  return cellIndex div columnCount

proc columnOf(cellIndex: int): int =
  return cellIndex mod columnCount

proc neighbourIndex(cellIndex: int, direction: int): int =
  let currentRow = rowOf(cellIndex)
  let currentColumn = columnOf(cellIndex)
  if direction == 0:
    if currentRow == 0:
      return -1
    return cellIndex - columnCount
  if direction == 1:
    if currentRow == rowCount - 1:
      return -1
    return cellIndex + columnCount
  if direction == 2:
    if currentColumn == 0:
      return -1
    return cellIndex - 1
  if currentColumn == columnCount - 1:
    return -1
  return cellIndex + 1
```

Out-of-grid steps return minus one.
Rows and columns come from the flat index.
All later searches share this helper.

**Water search.** A breadth-first pass records the flood timetable.

```nim
while waterHead < waterTail:
  let currentCell = waterQueue[waterHead]
  waterHead += 1
  let arrivalTime = waterTimes[currentCell]
  for direction in 0 .. 3:
    let neighbourCell = neighbourIndex(currentCell, direction)
    if neighbourCell == -1:
      continue
    if cells[neighbourCell] == 'X' or cells[neighbourCell] == 'D':
      continue
    if waterTimes[neighbourCell] != infiniteTime:
      continue
    waterTimes[neighbourCell] = arrivalTime + 1
    waterQueue[waterTail] = neighbourCell
    waterTail += 1
```

Rocks and the den block water completely.
Each cell receives its earliest flood minute.
The queue advances in increasing time.

**Hedgehog search.** A second pass respects the timetable.

```nim
var escapeTime = -1
while hedgehogHead < hedgehogTail and escapeTime == -1:
  let currentCell = hedgehogQueue[hedgehogHead]
  hedgehogHead += 1
  let arrivalTime = hedgehogTimes[currentCell]
  for direction in 0 .. 3:
    let neighbourCell = neighbourIndex(currentCell, direction)
    if neighbourCell == -1:
      continue
    if cells[neighbourCell] == 'X':
      continue
    if hedgehogTimes[neighbourCell] != -1:
      continue
    if arrivalTime + 1 >= waterTimes[neighbourCell]:
      continue
    hedgehogTimes[neighbourCell] = arrivalTime + 1
    hedgehogQueue[hedgehogTail] = neighbourCell
    hedgehogTail += 1
    if neighbourCell == denCell:
      escapeTime = arrivalTime + 1
      break

if escapeTime == -1:
  appendOutput("KAKTUS")
else:
  appendOutput($escapeTime)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A cell is accepted only when arrival beats its flood time.
Reaching the den ends the search immediately.
An empty queue reports `KAKTUS`.

## Complexity

Both searches visit each cell once.

| phase | time | space |
|---|---|---|
| input read | one pass over the map | one input string |
| water search | one visit per cell | flood times and queue |
| hedgehog search | one visit per cell | arrival times and queue |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(R * C) |
| space | O(R * C) |

Replaying every minute over the whole grid would cost more when water spreads slowly.

Two passes give the answer directly.
