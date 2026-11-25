# PAVEMENT — Pavement Blood (SPOJ)
<https://www.spoj.com/problems/PAVEMENT/>

## Problem

A path is an N by 3 grid of tiles with a blood value on each tile. One step covers a 2 by 2 block, no tile is used twice, and rows may be skipped. Report the largest total value reachable by any set of steps.

The first line gives N. The next N lines give three integers each. Print one integer, the maximum total.

| Constraint | Value |
| --- | --- |
| Rows N | 1 to 100000 |
| Tile value | -1000000000 to 1000000000 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

A step uses two adjacent rows and one of the two column pairs.

The sample input and its expected output follow byte for byte.

```
7
7 1 11
6 3 9
-4 -2 8
-8 -10 17
5 4 -3
-1 2 0
3 9 -3
```

```
50
```

The three chosen steps sit in rows 1-2, 3-4 and 6-7, so they share no tile.

## Idea

Choosing steps is like picking non-adjacent coupons from a strip: each row pair offers two coupons, and one pick blocks the neighbouring row pair. Dynamic programming keeps the best total for the row pair after the current one. Each row costs one comparison and one sum. Enumerating every subset of steps costs O(2^N) and fails for N = 100000. Keep two rolling best totals and scan the rows once from the bottom.

## Why It Works

1. A 2 by 2 step spans rows i and i + 1.
2. Two steps whose start rows differ by one share a tile in row i + 1.
3. Both column pairs contain the middle column, so no column choice removes that clash.
4. Steps with start rows at least two apart never share a tile.
5. At each start row only the better of the two column pairs matters.
6. The best total either skips this row pair or takes it and jumps two rows.

The terms below fix the meaning of each stored value.

| Term | Meaning |
| --- | --- |
| `leftPair` | value of columns 1-2 across the current row pair |
| `rightPair` | value of columns 2-3 across the current row pair |
| `skipNext` | best total starting one row later |
| `takeNext` | best total starting two rows later |
| `stepRow` | start row under consideration |

Rolling two totals replaces an array of N partial answers.

A script check of the sample lists the value of each row pair.

| Start row | Better 2 by 2 value |
| --- | --- |
| 1 | 24 |
| 2 | 18 |
| 3 | 13 |
| 4 | 8 |
| 5 | 10 |
| 6 | 13 |

Taking row pairs 1, 3 and 6 gives 24 + 13 + 13, which is 50.

Each pair sum uses `int64`, so four values near one billion cannot overflow the accumulator. With N = 1 no step fits, and the two rolling totals stay at zero.

## Code

**Input and signed scanner.** The reader handles the header and all three tile columns, including negative values.

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
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

A leading minus flips the sign before the digit loop runs. The scanner walks one shared input buffer by index.

**Buffered output.** One string collects the answer and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Writes never happen per tile. A single final flush emits the one answer line.

**Reverse row scan.** The loop keeps two best totals and picks the better column pair at each row.

```nim
let rowCount = nextInt(inputData, scanPos)
var leftColumn = newSeq[int](rowCount)
var middleColumn = newSeq[int](rowCount)
var rightColumn = newSeq[int](rowCount)
for rowIndex in 0 .. rowCount - 1:
  leftColumn[rowIndex] = nextInt(inputData, scanPos)
  middleColumn[rowIndex] = nextInt(inputData, scanPos)
  rightColumn[rowIndex] = nextInt(inputData, scanPos)
var skipNext: int64 = 0
var takeNext: int64 = 0
var stepRow = rowCount - 2
while stepRow >= 0:
  var leftPair = int64(leftColumn[stepRow]) + int64(middleColumn[stepRow]) + int64(leftColumn[stepRow + 1]) + int64(middleColumn[stepRow + 1])
  var rightPair = int64(middleColumn[stepRow]) + int64(rightColumn[stepRow]) + int64(middleColumn[stepRow + 1]) + int64(rightColumn[stepRow + 1])
  if rightPair > leftPair:
    leftPair = rightPair
  var withStep = leftPair + skipNext
  if withStep < takeNext:
    withStep = takeNext
  skipNext = takeNext
  takeNext = withStep
  stepRow -= 1
appendOutput($takeNext)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Scanning upward from the last row pair keeps `skipNext` and `takeNext` current. The better column pair is added to the total two rows later. The final value is written once through the buffer.

## Complexity

The scan touches each row once with constant work per row.

| Phase | Time | Space |
| --- | --- | --- |
| read input | one pass over 3N values | three column arrays |
| reverse scan | one pass over N rows | two integer totals |
| output | one line | block buffer |

Each row contributes a bounded amount of work, so the table stays small.

| Measure | Big O |
| --- | --- |
| time | O(N) |
| space | O(N) |

A brute force over step subsets needs O(2^N) checks, while the rolling scan needs O(N). Two rolling totals and a reverse pass give the full answer in linear time.
