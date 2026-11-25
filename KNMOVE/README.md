# KNMOVE — Knight Move (SPOJ)

<https://www.spoj.com/problems/KNMOVE/>

## Problem

A knight starts at square (a, b) on a 1000 by 1000 board and must reach square (1, 1). Report the fewest knight moves for each query. Rows and columns run from 1 to 1000.

The input starts with the query count t. Each following line gives one pair a, b. Print one move count per query, in input order.

| item | bound |
|---|---|
| queries t | 1 to 1000 |
| row a | 1 to 1000 |
| column b | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

Every query lies on the board.

Sample input:

```
2
3 5
7 4
```

Sample output:

```
2
3
```

The two lines answer the two knight positions in order.

## Idea

Search outward from the target once, like ripples spreading from a drain, and read every answer from a stored distance table. Breadth-first search on the whole board gives the exact move count from each square to the corner. Each cell costs eight neighbour checks, and each query then costs one lookup. Running a search per query would repeat a million-cell walk up to a thousand times. Precompute once, then answer all queries with table reads.

## Why It Works

1. A knight moves by offsets (1, 2) or (2, 1), with either sign on each part.
2. Breadth-first search visits squares in nondecreasing move count.
3. Starting the search at (1, 1) makes each stored distance the answer for that square.
4. The bounds test keeps every step inside the board.
5. A query converts its pair into one flat index and reads the stored distance.

| term | meaning |
|---|---|
| `boardCells` | total squares, 1000 times 1000 |
| `distances` | stored move count for each square |
| `queue` | squares waiting to be expanded |
| `queueHead` | read position in the queue |
| `queueTail` | write position in the queue |
| `cellIndex` | flat index of one square |

The ripple gives these sample values and one near-corner case.

| query | row and column offset | stored distance |
|---|---|---|
| (1, 1) | (0, 0) | 0 |
| (3, 5) | (2, 4) | 2 |
| (7, 4) | (6, 3) | 3 |
| (2, 2) | (1, 1) | 4 |

Square (2, 2) needs four moves because the shorter detour would leave the board.

## Code

**Input, scanner and output helper.** The whole stream is read once before any search.

```nim
const flushBlockBytes = 1 shl 17
const boardSize = 1000
const boardCells = boardSize * boardSize
const rowOffsets = [1, 1, -1, -1, 2, 2, -2, -2]
const columnOffsets = [2, -2, 2, -2, 1, -1, 1, -1]

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

The two offset arrays encode all eight legal knight steps.
The integer scanner skips spaces and line breaks.
Output accumulates in one buffer.

**Breadth-first search and query answers.** The search runs once from the corner.

```nim
var distances = newSeq[int16](boardCells)
for cellIndex in 0 .. boardCells - 1:
  distances[cellIndex] = -1
var queue = newSeq[int](boardCells)
var queueHead = 0
var queueTail = 0
distances[0] = 0
queue[0] = 0
queueTail = 1
while queueHead < queueTail:
  let cellIndex = queue[queueHead]
  queueHead += 1
  let rowIndex = cellIndex div boardSize
  let columnIndex = cellIndex mod boardSize
  for moveIndex in 0 .. 7:
    let nextRow = rowIndex + rowOffsets[moveIndex]
    let nextColumn = columnIndex + columnOffsets[moveIndex]
    if nextRow >= 0 and nextRow < boardSize and nextColumn >= 0 and nextColumn < boardSize:
      let nextIndex = nextRow * boardSize + nextColumn
      if distances[nextIndex] < 0:
        distances[nextIndex] = distances[cellIndex] + int16(1)
        queue[queueTail] = nextIndex
        queueTail += 1

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let rowPosition = nextInt(inputData, scanPos)
  let columnPosition = nextInt(inputData, scanPos)
  let cellIndex = (rowPosition - 1) * boardSize + (columnPosition - 1)
  appendOutput($int(distances[cellIndex]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

An unvisited square has distance minus one.
Each new square is enqueued exactly once.
Every query writes one buffered line.

## Complexity

One search serves the whole input.

| phase | time | space |
|---|---|---|
| input read | one pass over the query list | one input string |
| board search | eight neighbour checks per square | distance table and queue |
| output | one line per query | block buffer |

The board has exactly a million squares.

| measure | Big O |
|---|---|
| time | O(boardCells times 8 + t) |
| space | O(boardCells) |

A search repeated for each query costs O(t times boardCells) instead of O(boardCells).
The single precomputation keeps all thousand queries within the limit.
