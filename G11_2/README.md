# G11_2 — Knight Moves (SPOJ)

<https://www.spoj.com/problems/G11_2/>

## Problem

A knight jumps in an L shape across an 8 by 8 chessboard.
Given two squares, report the fewest jumps between them.

Each input line holds two squares separated by one space, until end of file.
A square is a column letter from a through h, then a row digit from 1 through 8.
Print one sentence per pair with the exact wording shown below.

| Item | Bound |
|---|---|
| Board | 8 by 8 squares |
| Test cases | until end of file |
| Judge limit | 12000 ms |

The 64-square board fixes the problem size before any input arrives.

Sample input:

```
e2 e4
a1 b2
b2 c3
a1 h8
a1 h7
h8 a1
b1 c3
f6 f6
```

Sample output:

```
To get from e2 to e4 takes 2 knight moves.
To get from a1 to b2 takes 4 knight moves.
To get from b2 to c3 takes 2 knight moves.
To get from a1 to h8 takes 6 knight moves.
To get from a1 to h7 takes 5 knight moves.
To get from h8 to a1 takes 6 knight moves.
To get from b1 to c3 takes 1 knight moves.
To get from f6 to f6 takes 0 knight moves.
```

## Idea

Treat the board as a subway map with 64 stations.
Build one shortest-route table, then read each answer from it.

Breadth-first search from a square visits squares in increasing jump count.
Each search touches at most 64 vertices and 8 moves per vertex.
A fresh search per query repeats work already done.

One precomputation serves any number of query lines.

## Why It Works

1. Knight jumps form an unweighted graph with one vertex per square.
2. Breadth-first search visits vertices in increasing distance from the source.
3. The first visit to a square stores the shortest jump count.
4. Repeating the search from every source fills the whole table.

| Term | Meaning |
|---|---|
| `distanceTable` | 64 by 64 matrix of shortest jump counts |
| `visitQueue` | fixed 64-entry queue used by one search |
| `squareIndex` | row-major index derived from a square token |

The matrix reduces each query to two character reads and one lookup.

Script-generated example from `gen.py`:

```
e2 e4 2
a1 b2 4
a1 h8 6
```

Those counts match lines one, two and four of the sample.

## Code

**Input and board helpers.** This block reads every line and converts square text to an index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const boardSize = 8
const squareCount = 64
const stepX = [1, 2, 2, 1, -1, -2, -2, -1]
const stepY = [2, 1, -1, -2, -2, -1, 1, 2]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc squareIndex(token: string): int =
  let column = int(token[0]) - 97
  let row = int(token[1]) - 49
  return row * boardSize + column
```

`nextToken` skips whitespace by index and returns two characters.
`squareIndex` maps the letter and digit to one row-major number.
The input string is complete before the table is built.

**All-pairs table.** This block runs one breadth-first search from each square.

```nim
var distanceTable: array[squareCount, array[squareCount, int]]
for source in 0..<squareCount:
  for target in 0..<squareCount:
    distanceTable[source][target] = -1
  var visitQueue: array[squareCount, int]
  var queueHead = 0
  var queueTail = 0
  distanceTable[source][source] = 0
  visitQueue[queueTail] = source
  queueTail += 1
  while queueHead < queueTail:
    let current = visitQueue[queueHead]
    queueHead += 1
    let currentRow = current div boardSize
    let currentColumn = current mod boardSize
    let nextDistance = distanceTable[source][current] + 1
    for moveIndex in 0..7:
      let nextRow = currentRow + stepY[moveIndex]
      let nextColumn = currentColumn + stepX[moveIndex]
      if nextRow >= 0 and nextRow < boardSize and nextColumn >= 0 and nextColumn < boardSize:
        let neighbor = nextRow * boardSize + nextColumn
        if distanceTable[source][neighbor] < 0:
          distanceTable[source][neighbor] = nextDistance
          visitQueue[queueTail] = neighbor
          queueTail += 1
```

The outer loop has exactly 64 iterations.
The queue never holds more than 64 squares.
A negative distance marks a square not yet reached.

**Answer loop.** This block emits the sentence for each input pair.

```nim
var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let fromToken = nextToken(inputData, scanPos)
  if fromToken.len == 0: break
  let toToken = nextToken(inputData, scanPos)
  if toToken.len == 0: break
  appendOutput("To get from ")
  appendOutput(fromToken)
  appendOutput(" to ")
  appendOutput(toToken)
  appendOutput(" takes ")
  appendOutput($(distanceTable[squareIndex(fromToken)][squareIndex(toToken)]))
  appendOutput(" knight moves.\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Both tokens are converted before the table lookup.
The buffer flushes every 128 KiB during long inputs.
A final write clears any remaining text.

## Complexity

The fixed board makes precomputation small and independent of input size.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Precompute | 64 breadth-first searches | 64 by 64 matrix |
| Output | one write per 128 KiB block | block buffer |

The matrix uses constant space because the board never changes.

| Measure | Big O |
|---|---|
| Time | O(64 * 64 * 8 + Q) |
| Space | O(64 * 64 + I) |

A fresh search per query costs O(512) per line instead of one lookup.
