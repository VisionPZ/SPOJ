# BALLLSTA — Ball Stack (SPOJ)

<https://www.spoj.com/problems/BALLLSTA/>

## Problem

A triangular stack has row i holding i balls, each with an integer value. Taking a ball requires taking the two balls directly above it.

Find the largest total value of any legal set, or zero by taking nothing. Each case gives a row count, then that many rows of values; a zero row count ends the input.

Output one maximum per case.

Write `S(i,j)` for the best total when ball j in column i is taken, counting only the first i columns. Write `C(i,j)` for the sum of the first j balls in column i. The forms `S(i-1,j)` and `S(i,j+1)` shift the column or the position in that same notation.

| item | bound |
|---|---|
| rows per case | 1 to 1000 |
| ball value | -100000 to 100000 |
| test cases | until a line containing zero |
| judge limit | 1071 ms, 1536 MB |

Half a million balls per case makes any subset enumeration impossible.

Sample input:

```
4
3
-5 3
-8 2 -8
3 9 -2 7
2
-2
1 -10
3
1
-5 3
6 -4 1
0
```

Sample output:

```
7
0
6
```

## Idea

Tilt the triangle into columns, like turning a ladder on its side. Ball j in column i then needs the ball directly above it and the ball at the same height in column i-1.

If ball j is the lowest taken ball in its column, the first j balls of that column are forced. Their sum is `C(i,j)`, and `S(i,j)` also needs `S(i-1,j)`. Taking a lower ball instead gives `S(i,j+1)`, so the recurrence takes the larger of the two choices.

A suffix scan of each column computes all its states in linear time. Enumerating legal subsets costs exponential work.

## Why It Works

1. Column i holds the values at row i, row i+1, and so on down the stack.
2. A ball in column i and position j rests on position j-1 of that column and position j of column i-1.
3. Taking that ball forces every ball above it in its column, whose total is `C(i,j)`.
4. It also forces the matching ball in the previous column, worth `S(i-1,j)`.
5. Taking further balls below j in the same column is covered by `S(i,j+1)`.
6. Hence `S(i,j)` is the maximum of the sum of those two terms and `S(i,j+1)`.

| term | meaning |
|---|---|
| `ballValues` | all ball values stored by row and column |
| `prefixSums` | running column totals `C(i,j)` |
| `previousBest` | `S(i-1,j)` from the prior column |
| `currentBest` | `S(i,j)` for the current column |
| `bestPrize` | largest state value seen so far |

The bottom state uses a large negative sentinel, so it cannot be selected.

A script-generated trace uses the first sample case, tilted into four columns.

| column | prefix sums | best states |
|---|---|---|
| 1 | 3, -2, -10, -7 | 3, -2, -7, -7 |
| 2 | 3, 5, 14 | 7, 7, 7 |
| 3 | -8, -10 | -1, -3 |
| 4 | 7 | 6 |

The largest state is 7, matching the first sample answer.

## Code

**Input and scanning.** The reader accepts signed values and stores balls by row.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sign branch is needed because ball values can be negative.
Row offsets turn the triangular input into one flat value array.
All cases are parsed through the same scanner and one buffer.

**Column sweep.** Each column builds prefix sums, then scans from bottom to top.

```nim
var rowCount = nextInt(inputData, scanPos)
while rowCount != 0:
  var rowOffsets = newSeq[int](rowCount + 1)
  for rowIndex in 0 .. rowCount:
    rowOffsets[rowIndex] = rowIndex * (rowIndex + 1) div 2
  var ballValues = newSeq[int64](rowOffsets[rowCount])
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. rowIndex:
      ballValues[rowOffsets[rowIndex] + columnIndex] = int64(nextInt(inputData, scanPos))
  var previousBest = newSeq[int64](rowCount + 2)
  var prefixSums = newSeq[int64](rowCount + 2)
  var bestPrize: int64 = 0
  var columnIndex = 0
  while columnIndex < rowCount:
    let columnLength = rowCount - columnIndex
    var runningTotal: int64 = 0
    for ballPosition in 1 .. columnLength:
      let sourceRow = columnIndex + ballPosition - 1
      runningTotal = runningTotal + ballValues[rowOffsets[sourceRow] + columnIndex]
      prefixSums[ballPosition] = runningTotal
    var currentBest = newSeq[int64](columnLength + 2)
    currentBest[columnLength + 1] = -(int64(1) shl 60)
    var ballPosition = columnLength
    while ballPosition >= 1:
      let takeThroughHere = previousBest[ballPosition] + prefixSums[ballPosition]
      if takeThroughHere > currentBest[ballPosition + 1]:
        currentBest[ballPosition] = takeThroughHere
      else:
        currentBest[ballPosition] = currentBest[ballPosition + 1]
      if currentBest[ballPosition] > bestPrize:
        bestPrize = currentBest[ballPosition]
      ballPosition -= 1
    previousBest = currentBest
    columnIndex += 1
  appendOutput($bestPrize)
  outputBuffer.add '\n'
  rowCount = nextInt(inputData, scanPos)
stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner scan keeps the best state at or below each position.
Sixty-four-bit totals hold the largest possible stack sum.
A zero row count ends the loop and flushes the answers.

## Complexity

Every ball contributes to one prefix sum and one state update.

| phase | time | space |
|---|---|---|
| input read | one pass over all ball values | one flat value array |
| column sweep | two updates per ball | two state rows |
| output | one line per case | block buffer |

The phase table shows that total work tracks the number of balls.

| measure | Big O |
|---|---|
| time | O(N^2) per case |
| space | O(N^2) for values, O(N) for states |

Enumerating every legal subset costs O(2^(N^2)) per case, while the sweep costs O(N^2).
