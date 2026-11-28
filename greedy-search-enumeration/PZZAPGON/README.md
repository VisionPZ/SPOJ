# PZZAPGON — Pizza and pigeons (SPOJ)

<https://www.spoj.com/problems/PZZAPGON/>

## Problem

Sum a list of grid moves from the starting point and report the straight-line distance back, rounded up to the next whole number. Print one integer.

The first line gives the number of moves. Each later line holds tokens like 4W or 3S, where a count is followed by one of N, S, E or W. The move count is below 100.

| item | bound |
|---|---|
| moves | fewer than 100 |
| direction letters | N, S, E, W |
| judge limit | 1000 ms, 1536 MB |

The straight-line distance is the Euclidean norm of the final displacement.

Sample input:

```
3
4W 4N
3E 5S
2W 4N
```

Sample output:

```
5
```

## Idea

Picture the final address as a point on graph paper. North and south change one coordinate, east and west change the other. The pigeon flies along the diagonal back to the start, so the answer is the diagonal length rounded up.

The real algorithm accumulates signed displacement in two counters, then computes a ceiling square root by integer binary search. Each move costs constant work. Walking one grid step at a time would cost time proportional to the total step count, which can be large. The takeaway is that only the net displacement matters.

## Why It Works

1. Moves along the same axis cancel by signed addition.
2. Squared distance is the sum of the two squared net displacements.
3. The required distance is the smallest integer whose square is at least that sum.
4. Doubling finds an upper bound, and binary search finds the smallest valid value.
5. Integer arithmetic avoids floating point error at the rounding boundary.

| term | meaning |
|---|---|
| `northSouth` | net displacement along the north south axis |
| `eastWest` | net displacement along the east west axis |
| `squaredDistance` | sum of the two squared displacements |
| `highRoot` | smallest known ceiling candidate |
| `lowRoot` | largest value whose square is too small |

For the sample the net displacement is three west and three north. The squared distance is 18, so the ceiling square root is 5.

A zero displacement yields squared distance zero, which returns zero directly.

## Code

**Input and scanner.** The reader loads all moves and parses counts and direction letters.

```nim
const flushBlockBytes = 1 shl 17

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

The scanner skips spaces and letters before each count.
The following letter selects the move axis.
Buffered output writes the single answer once.

**Displacement accumulation.** Each token changes one of two signed counters.

```nim
let instructionCount = nextInt(inputData, scanPos)
var northSouth: int64 = 0
var eastWest: int64 = 0
for instructionIndex in 0 .. instructionCount - 1:
  let stepCount = int64(nextInt(inputData, scanPos))
  while scanPos < inputData.len and inputData[scanPos] != 'N' and inputData[scanPos] != 'S' and inputData[scanPos] != 'E' and inputData[scanPos] != 'W':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let directionChar = inputData[scanPos]
  scanPos += 1
  case directionChar:
    of 'N':
      northSouth += stepCount
    of 'S':
      northSouth -= stepCount
    of 'E':
      eastWest += stepCount
    of 'W':
      eastWest -= stepCount
    else:
      discard
```

North and east add, while south and west subtract.
Countdown parsing stops at the first direction letter.
Both counters use int64 for large step totals.

**Ceiling square root.** A doubling bound and a binary search produce the rounded distance.

```nim
let squaredDistance = northSouth * northSouth + eastWest * eastWest
var highRoot: int64 = 0
while highRoot * highRoot < squaredDistance:
  if highRoot == 0:
    highRoot = 1
  else:
    highRoot = highRoot * 2
var lowRoot: int64 = 0
while highRoot - lowRoot > 1:
  let midRoot = (lowRoot + highRoot) div 2
  if midRoot * midRoot >= squaredDistance:
    highRoot = midRoot
  else:
    lowRoot = midRoot
appendOutput($highRoot)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Doubling ends with a square at least as large as the target.
Binary search then shrinks that bound to the exact ceiling.
The answer is written as one line.

## Complexity

Each move is parsed once, and the square root search is logarithmic in the distance.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| displacement | constant work per move | two int64 counters |
| square root | logarithmic in the distance | constant extra space |

| measure | Big O |
|---|---|
| time | O(m + log d) for m moves and distance d |
| space | O(1) beyond input and output |

Stepping through every grid unit would scale with the step counts instead of the move count.
Summing net displacement keeps the work proportional to the number of tokens.
