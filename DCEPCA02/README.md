# DCEPCA02 — Ant Colony Optimization (SPOJ)

<https://www.spoj.com/problems/DCEPCA02/>

## Problem

Two ant types reproduce across a grid. Every occupied cell sends type A ants into queen A's two directions and type B ants into queen B's two directions. Print the sum of the first arrival times of both types at the target, or `-1` if either type cannot arrive.

Each case has four lines: grid sizes `M N`, start `SX SY`, end `EX EY`, and a four-letter direction string. The first two letters are queen A's directions and the last two are queen B's. Coordinates run from 0, with `SX` and `EX` below `M`, and `SY` and `EY` below `N`.

| item | bound |
|---|---|
| test cases `T` | up to 100 |
| grid sizes `M`, `N` | up to 5000 |
| judge limit | 1000 ms, 1536 MB |

Moving up subtracts one from the second coordinate, down adds one, left subtracts one from the first coordinate, and right adds one.

```
3
5 5
1 1
3 4
LRUD
2 4
0 2
0 3
RULD
2 4
0 2
1 1
URDL
```

```
10
-1
6
```

## Idea

Picture the grid as a city where every intersection broadcasts both kinds of messages; the last hop into the destination decides which message type delivers it. A broadcast fills a diamond of cells over time, so the earliest useful cell next to the target has the smallest Manhattan distance from the start. Two checks per direction give the answer without simulating cells. A breadth-first simulation over the whole grid would waste work on a huge field.

## Why It Works

1. From any occupied cell, both ant types appear in all four directions over time.
2. Hence a cell is occupied once its Manhattan distance from the start is reached.
3. A type A ant arrives at the target only on a final hop in an A direction.
4. That hop starts from a target neighbor in one of queen A's two directions.
5. The earliest arrival is one plus the shortest distance to such a neighbor.

| term | meaning |
|---|---|
| `neighborTime` | earliest arrival using one named direction as the final hop |
| `unreachableTime` | large sentinel for a neighbor outside the grid |
| `firstDirection` | first direction of queen A |
| `thirdDirection` | first direction of queen B |

In sample 1, queen A moves left and right, so the final A hop comes from `(2,4)` or `(4,4)`. The cell `(2,4)` sits four steps from `(1,1)`, giving five. Queen B moves up and down; the neighbor `(3,5)` lies outside the grid, and `(3,3)` also gives five. The sum is ten.

When the start equals the target, both arrival times are zero and that case is handled directly.

## Code

**Input and scanning.** Integers use a digit scanner; direction letters use a separate reader.

```nim
const flushBlockBytes = 1 shl 17
const unreachableTime = 1 shl 29

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

proc nextDirection(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let direction = data[pos]
  pos += 1
  return direction
```

Directions are read as single characters.
The sentinel marks an unusable neighbor.
All tests share one input string.

**Neighbor timing.** Each direction produces one candidate arrival time.

```nim
proc neighborTime(rowLimit: int, columnLimit: int, startRow: int, startColumn: int,
                  endRow: int, endColumn: int, direction: char): int =
  var neighborRow = endRow
  var neighborColumn = endColumn
  case direction
  of 'U':
    neighborColumn -= 1
  of 'D':
    neighborColumn += 1
  of 'L':
    neighborRow -= 1
  of 'R':
    neighborRow += 1
  else:
    return unreachableTime
  if neighborRow < 0 or neighborRow >= rowLimit or
     neighborColumn < 0 or neighborColumn >= columnLimit:
    return unreachableTime
  return abs(neighborRow - startRow) + abs(neighborColumn - startColumn) + 1
```

The neighbor moves opposite to the final hop direction.
Out-of-grid neighbors return the sentinel.
Manhattan distance supplies the broadcast arrival time.

**Case loop.** Two minima form the answer for each test case.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let rowLimit = nextInt(inputData, scanPos)
  let columnLimit = nextInt(inputData, scanPos)
  let startRow = nextInt(inputData, scanPos)
  let startColumn = nextInt(inputData, scanPos)
  let endRow = nextInt(inputData, scanPos)
  let endColumn = nextInt(inputData, scanPos)
  let firstDirection = nextDirection(inputData, scanPos)
  let secondDirection = nextDirection(inputData, scanPos)
  let thirdDirection = nextDirection(inputData, scanPos)
  let fourthDirection = nextDirection(inputData, scanPos)
  if startRow == endRow and startColumn == endColumn:
    appendOutput("0")
  else:
    let firstTime = min(neighborTime(rowLimit, columnLimit, startRow, startColumn,
                                     endRow, endColumn, firstDirection),
                        neighborTime(rowLimit, columnLimit, startRow, startColumn,
                                     endRow, endColumn, secondDirection))
    let secondTime = min(neighborTime(rowLimit, columnLimit, startRow, startColumn,
                                      endRow, endColumn, thirdDirection),
                         neighborTime(rowLimit, columnLimit, startRow, startColumn,
                                      endRow, endColumn, fourthDirection))
    if firstTime >= unreachableTime or secondTime >= unreachableTime:
      appendOutput("-1")
    else:
      appendOutput($(firstTime + secondTime))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each ant type checks exactly two directions.
An unreachable type makes the whole answer `-1`.
One line is emitted per test case.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| per test case | four neighbor checks | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(input size) |

Simulating every ant on a 5000 by 5000 grid would cost far more than four distance checks.

The result does not depend on grid area, only on the start, target, and four directions.
