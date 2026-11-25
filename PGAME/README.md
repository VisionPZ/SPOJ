# PGAME — Pheversos Game (SPOJ)

<https://www.spoj.com/problems/PGAME/>

## Problem

Two players alternate taking a cell from the beginning or end of a row, adding its value to their own score. Blocked rows hide their beginning, so only the right end can be taken. Report the winner and the winner's score under optimal play.

Each test starts with row count, column count, and blocked-row count, then the blocked indices and the board values. A line of three zeros ends the input. Print one winner line per test.

| item | bound |
|---|---|
| rows N | 1 to 1000 |
| columns M | 1 to 1000 |
| blocked rows K | 0 to N-1 |
| cell value | signed 32-bit integer |
| judge limit | 1000 ms, 1536 MB |

The winner always has a strictly larger score, so no tie line is needed.

Sample input:

```
2 2 2
1 2
500 10
3 10
3 3 2
1 3
0 1 2
3 7 4
0 0 9
0 0 0
```

Sample output:

```
second 503
first 17
```

## Idea

Imagine each row as a stack of coins with a hidden bottom lid. Three reductions shrink the board without changing the result, like cancelling repeated terms in an expression.

First fuse a peak and its two neighbors into one number. Then drop a fruitless pair next to a lid. Finally take the remaining values in descending order with alternating signs. This is Idziaszek's algorithm for the generalized coins-in-a-row game, and minimax over all board states is far slower.

## Why It Works

1. The greatest available value is always optimal to take, so remaining values are taken in descending order.
2. Three adjacent values x, M, y with M at least both neighbors fuse into x - M + y.
3. Fusion keeps the score difference unchanged under optimal play.
4. A blocked row has an anchored start, and a fruitless adjacent pair can be removed.
5. Alternating signs over the sorted survivors give the first player's advantage.

| term | meaning |
|---|---|
| `fusedStack` | running reduced values of one row |
| `globalSign` | sign of a fruitless pair, set by total cell parity |
| `remainingValues` | fused values awaiting the greedy sort |
| `advantage` | first player's score minus second player's score |

Script-generated trace for the first sample case:

| row | read order | fused value | pair removal |
|---|---|---|---|
| one | 10, 500 | none | 10 - 500 = -490 |
| two | 10, 3 | none | none |

Sorted survivors are 10 and 3, so the advantage is -490 + 10 - 3 = -483.
The total is 523, giving (523 + 483) / 2 = 503 for the second player.

## Code

**Input, signed scanner, and output buffer.** Cell values may be negative.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const blockedBeginning = true

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

proc compareDescending(leftValue: int64, rightValue: int64): int =
  if leftValue > rightValue:
    return -1
  if leftValue < rightValue:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner keeps a minus sign when present.
The comparator avoids subtraction overflow on int64 values.
Board values are summed in int64 too.

**Row reduction and winner selection.** Each row is processed once from an available end.

```nim
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let blockedCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0 and blockedCount == 0:
    break
  var isBlocked = newSeq[bool](rowCount)
  for blockIndex in 0 .. blockedCount - 1:
    let blockedRow = nextInt(inputData, scanPos) - 1
    if blockedRow >= 0 and blockedRow < rowCount:
      isBlocked[blockedRow] = blockedBeginning
  var boardValues = newSeq[int](rowCount * columnCount)
  var totalScore: int64 = 0
  for cellIndex in 0 .. boardValues.len - 1:
    boardValues[cellIndex] = nextInt(inputData, scanPos)
    totalScore = totalScore + int64(boardValues[cellIndex])
  let totalCells = rowCount * columnCount
  let globalSign = if totalCells mod 2 == 0: int64(1) else: int64(-1)
  var advantage: int64 = 0
  var remainingValues = newSeq[int64](0)
  for rowIndex in 0 .. rowCount - 1:
    var fusedStack = newSeq[int64](0)
    if isBlocked[rowIndex]:
      var columnIndex = columnCount - 1
      while columnIndex >= 0:
        let cellValue = int64(boardValues[rowIndex * columnCount + columnIndex])
        fusedStack.add cellValue
        while fusedStack.len >= 3 and fusedStack[fusedStack.len - 3] <= fusedStack[fusedStack.len - 2] and fusedStack[fusedStack.len - 2] >= fusedStack[fusedStack.len - 1]:
          let leftValue = fusedStack[fusedStack.len - 3]
          let middleValue = fusedStack[fusedStack.len - 2]
          let rightValue = fusedStack[fusedStack.len - 1]
          fusedStack[fusedStack.len - 3] = leftValue - middleValue + rightValue
          fusedStack.setLen(fusedStack.len - 2)
        columnIndex -= 1
      while fusedStack.len >= 2 and fusedStack[fusedStack.len - 2] <= fusedStack[fusedStack.len - 1]:
        let leftValue = fusedStack[fusedStack.len - 2]
        let rightValue = fusedStack[fusedStack.len - 1]
        advantage = advantage + globalSign * (leftValue - rightValue)
        fusedStack.setLen(fusedStack.len - 2)
    else:
      for columnIndex in 0 .. columnCount - 1:
        let cellValue = int64(boardValues[rowIndex * columnCount + columnIndex])
        fusedStack.add cellValue
        while fusedStack.len >= 3 and fusedStack[fusedStack.len - 3] <= fusedStack[fusedStack.len - 2] and fusedStack[fusedStack.len - 2] >= fusedStack[fusedStack.len - 1]:
          let leftValue = fusedStack[fusedStack.len - 3]
          let middleValue = fusedStack[fusedStack.len - 2]
          let rightValue = fusedStack[fusedStack.len - 1]
          fusedStack[fusedStack.len - 3] = leftValue - middleValue + rightValue
          fusedStack.setLen(fusedStack.len - 2)
    for fusedValue in fusedStack:
      remainingValues.add fusedValue
  remainingValues.sort(compareDescending)
  var currentSign: int64 = 1
  for remainingValue in remainingValues:
    advantage = advantage + currentSign * remainingValue
    currentSign = -currentSign
  let advantageSize = if advantage < 0: -advantage else: advantage
  let winnerScore = (totalScore + advantageSize) div 2
  if advantage > 0:
    appendOutput("first ")
  else:
    appendOutput("second ")
  appendOutput($winnerScore)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Blocked rows are read right to left, ending at the anchor.
Fusion uses a stack and removes the top two elements after a merge.
The final scan turns the advantage into the winner's score.

## Complexity

Each cell is pushed once and can be popped once during fusion.

| phase | time | space |
|---|---|---|
| board read | one pass over N M cells | one value per cell |
| row reduction | O(N M) stack work | one stack per row |
| survivor sort | O(N M log(N M)) | one list of survivors |

| measure | Big O |
|---|---|
| time | O(N M log(N M)) |
| space | O(N M) |

Minimax over board states would grow exponentially with the cell count.

The reductions make one sort the only superlinear step.
