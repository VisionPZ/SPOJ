## Problem

Read a walk of `n` straight sections on a square grid. Each section is 10 metres long and points north, east, south, or west. The walk never visits a point twice. Print the shortest horizontal or vertical segment that joins two break points and is not part of the walk. Print its length, begin index, end index, and direction. Break points are numbered from 0 at home to `n` at the university.

| Limit | Value |
| --- | --- |
| Sections per case | 3 to 250000 |
| Time | 1302 ms |
| Memory | 1536 MB |

A single case may hold a quarter million sections, so the scan must stay linear.

## Idea

Group break points by the row or column that holds them. Sort each group by its coordinate. A shortest shortcut only joins break points that are neighbours in that sorted order. Counting sort builds both orders in linear time because every coordinate stays inside `[-n, n]`. Each break point enters two groups and meets at most two neighbours, so the scan costs constant work per break point.

The walk itself covers a segment when it stays on that row or column between the two points. Neighbouring break points satisfy that condition exactly when their walk indices differ by one. The scan skips those pairs.

## Why It Works

If a shortcut spans a third break point on its line, one of the two shorter sub-segments is also a shortcut and is shorter. A shortest shortcut therefore never spans another break point on its line. It must join neighbours in the sorted order.

Two neighbouring break points on a line form a real shortcut exactly when their walk indices differ by more than one. A difference of one means the walk section between them already lies on that line.

Counting sort needs two index formulas. The term `coordinateOffset = sectionCount + 2` shifts every coordinate into a positive bucket index. The term `bucketCount = 2 * sectionCount + 5` covers every coordinate from `-n` to `n`. The array `lastOnRow[rowSlot]` holds the previous break point on that row in x order.

A script generated this worked example for the route `NNENNWWSS`.

| Break point | Position |
| --- | --- |
| 0 | (0, 0) |
| 1 | (0, 1) |
| 2 | (0, 2) |
| 3 | (1, 2) |
| 4 | (1, 3) |
| 5 | (1, 4) |
| 6 | (0, 4) |
| 7 | (-1, 4) |
| 8 | (-1, 3) |
| 9 | (-1, 2) |

Every candidate shortcut from neighbouring break points follows.

| Length | Begin | End | Direction | Line |
| --- | --- | --- | --- | --- |
| 1 | 2 | 9 | W | row 2 |
| 2 | 2 | 6 | N | column 0 |
| 2 | 4 | 8 | W | row 3 |

The first row wins by length, so the answer is `1 2 9 W`.

## Code

The scanner reads the whole input buffer once. It skips non-digits and consumes the decimal digits of each integer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i.inc
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (ord(inputData[i]) - firstDigitValue)
    i.inc
```

Each loop advances `i` past at most one token. The digit loop runs once per digit, so the cost is linear in the input size. The scanner skips letters, which lets the route scanner consume direction characters separately.

The comparison picks the winner and derives its direction from the two positions.

```nim
proc considerShortcut(lengthValue: int, firstBreak: int, secondBreak: int,
                      horizontal: bool, xPositions: seq[int], yPositions: seq[int],
                      bestLength: var int, bestBegin: var int, bestEnd: var int,
                      bestDirection: var char) =
  var beginBreak = firstBreak
  var endBreak = secondBreak
  if firstBreak > secondBreak:
    beginBreak = secondBreak
    endBreak = firstBreak
  let improves = lengthValue < bestLength or
    (lengthValue == bestLength and beginBreak < bestBegin) or
    (lengthValue == bestLength and beginBreak == bestBegin and endBreak > bestEnd)
  if improves:
    bestLength = lengthValue
    bestBegin = beginBreak
    bestEnd = endBreak
    if horizontal:
      if xPositions[endBreak] > xPositions[beginBreak]:
        bestDirection = 'E'
      else:
        bestDirection = 'W'
    else:
      if yPositions[endBreak] > yPositions[beginBreak]:
        bestDirection = 'N'
      else:
        bestDirection = 'S'
```

The `improves` condition applies the three tie-break rules in order. It updates five variables at once, so a candidate cannot change direction without changing its endpoints. The cost is constant per candidate.

The program reads all lines into one buffer before it parses anything.

```nim
var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var outputBuffer = ""
var i = 0
let testCount = nextInt(inputData, i)
```

The loop runs once per input line. It adds one newline per line, so the buffer keeps the original byte shape. A single bulk read avoids one system call per token.

The walk scan writes the position of every break point.

```nim
  while i < inputData.len and inputData[i] <= ' ':
    i.inc

  var currentX = 0
  var currentY = 0
  xPositions[0] = 0
  yPositions[0] = 0
  for j in 1 .. sectionCount:
    case inputData[i]
    of 'N':
      currentY.inc
    of 'S':
      currentY.dec
    of 'E':
      currentX.inc
    of 'W':
      currentX.dec
    else:
      discard
    i.inc
    xPositions[j] = currentX
    yPositions[j] = currentY
```

The loop bound is `sectionCount`, the closed form for one position per section. The whitespace skip stops at the first direction character. The scan costs one step per section.

Counting sort builds the two coordinate orders.

```nim
  for k in 0 .. sectionCount:
    xCounts[xPositions[k] + coordinateOffset].inc
    yCounts[yPositions[k] + coordinateOffset].inc

  var xRunning = 0
  var yRunning = 0
  for j in 0 .. bucketCount - 1:
    let xBucketSize = xCounts[j]
    let yBucketSize = yCounts[j]
    xCounts[j] = xRunning
    yCounts[j] = yRunning
    xRunning += xBucketSize
    yRunning += yBucketSize

  for k in 0 .. sectionCount:
    let xSlot = xPositions[k] + coordinateOffset
    orderByX[xCounts[xSlot]] = k
    xCounts[xSlot].inc
    let ySlot = yPositions[k] + coordinateOffset
    orderByY[yCounts[ySlot]] = k
    yCounts[ySlot].inc
```

The first and last loops run `sectionCount + 1` times. The middle loop runs `bucketCount` times. Prefix sums turn counts into write slots without a comparison sort. The whole block costs linear time.

The row scan finds horizontal shortcuts.

```nim
  for j in 0 .. sectionCount:
    let k = orderByX[j]
    let rowSlot = yPositions[k] + coordinateOffset
    let previousBreak = lastOnRow[rowSlot]
    if previousBreak >= 0:
      if abs(k - previousBreak) != 1:
        let lengthValue = xPositions[k] - xPositions[previousBreak]
        considerShortcut(lengthValue, previousBreak, k, true,
          xPositions, yPositions, bestLength, bestBegin, bestEnd, bestDirection)
    lastOnRow[rowSlot] = k
```

The loop visits every break point once in x order. The index test rejects pairs that the walk already joins on this row. The array update keeps the neighbour for the next point on the row. The scan costs one step per break point.

The column scan applies the same rule to vertical shortcuts.

```nim
  for j in 0 .. sectionCount:
    let k = orderByY[j]
    let columnSlot = xPositions[k] + coordinateOffset
    let previousBreak = lastOnColumn[columnSlot]
    if previousBreak >= 0:
      if abs(k - previousBreak) != 1:
        let lengthValue = yPositions[k] - yPositions[previousBreak]
        considerShortcut(lengthValue, previousBreak, k, false,
          xPositions, yPositions, bestLength, bestBegin, bestEnd, bestDirection)
    lastOnColumn[columnSlot] = k
```

The loop bound matches the row scan. It uses y order and stores the neighbour per column. The direction flag is false, so the comparison derives a north or south direction.

The output buffer holds all answers and flushes in fixed blocks.

```nim
  outputBuffer.add $bestLength
  outputBuffer.add ' '
  outputBuffer.add $bestBegin
  outputBuffer.add ' '
  outputBuffer.add $bestEnd
  outputBuffer.add ' '
  outputBuffer.add bestDirection
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
```

The flush runs when the buffer reaches `flushBlockBytes`, so write cost stays near one call per block. The final write handles a short tail. Reusing the buffer with `setLen 0` avoids one allocation per flush.

## Complexity

Bulk input costs `O(S)`, where `S` is the total input length. Counting sort costs `O(n)` per case with two bucket arrays of size `2n + 5`. The two neighbour scans cost `O(n)` per case in total. The program uses `O(n)` space per case.

The total cost is `O(S + n)` time and `O(n)` space per case. A naive scan of every break point pair costs `O(n^2)` time and cannot handle a full-size case.
