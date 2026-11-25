# BOXES — Boxes (SPOJ)

<https://www.spoj.com/problems/BOXES/>

## Problem

Given balls sitting in boxes around a circle, find the fewest one-step moves that leave no box holding more than one ball.

Input starts with `t`, the number of cases. Each case gives `n`, then one line of `n` nonnegative ball counts. Output gives one minimum move count per case, on its own line.

The bounds from the statement and judge page:

| Item | Bound |
|---|---|
| Test cases `t` | at most 20 |
| Boxes `n` | 1 ≤ n ≤ 1000 |
| Balls in all boxes | at most n |
| Judge limit | 7273 ms, 1536 MB |

The ball total never exceeds `n`, so some boxes stay empty.

The sample case:

```
1
12
0 0 2 4 3 1 0 0 0 0 0 1
```

```
19
```

The answer is 19 moves.

## Idea

Open the circle at one edge and solve the straight row, like sliding spare balls along a shelf until each slot holds one.

For one opening, the program walks the row once and tracks two numbers: balls seen and slots filled. Their difference counts balls that cross the edge previously passed.

This is a greedy matching (a fixed rule that pairs balls with free slots) over every rotation (the circle read from a chosen box). One walk costs O(n) steps, so one case costs O(n²).

Picking the occupied boxes directly takes exponential time. The row walk replaces that search with one linear pass.

Takeaway: the right opening removes wrap-around, and one pass then gives the exact cost.

## Why It Works

1. Cutting an edge turns the circle into a row of n boxes. In that row, no ball crosses the cut edge.
2. Balls meet free slots in left-to-right order. Crossing two pairings only adds distance, so that order is safe.
3. `ballsSeen` minus `filledSlots` is the flow across the last cut. Each unit of flow costs exactly one move.
4. `filledSlots` rises by at most one per box. The walk fills all slots that `ballsSeen` allows, then obeys `lowerBound` so every ball fits.
5. An optimal circular plan never sends balls all the way around. Some edge carries no flow, and that edge is one of the n cuts.

The walk keeps four running numbers:

| Term | Meaning |
|---|---|
| `ballsSeen` | balls in boxes up to the current cut |
| `filledSlots` | occupied slots up to the current cut |
| `upperBound` | most slots the walk may fill here |
| `lowerBound` | slots still needed to fit every ball |
| `cutCost` | moves charged to this one cut |

Every entry is an integer, so the walk uses constant space.

A script trace of the sample case starts the row at box 10:

```
 cut  box  balls  seen  upper  lower  filled  step  total
   1   10      0      0      0      0       0     0      0
   2   11      0      0      0      1       1     1      1
   3   12      1      1      1      2       2     1      2
   4    1      0      1      1      3       3     2      4
   5    2      0      1      1      4       4     3      7
   6    3      2      3      3      5       5     2      9
   7    4      4      7      6      6       6     1     10
   8    5      3     10      7      7       7     3     13
   9    6      1     11      8      8       8     3     16
  10    7      0     11      9      9       9     2     18
  11    8      0     11     10     10      10     1     19
```

The running total ends at 19, matching the sample output.

## Code

**Constants and digit scanner.** These lines set the write block and parse integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

`nextInt` skips separators and builds each value one digit at a time. `firstDigitValue` turns a character byte into its digit. `flushBlockBytes` sets the 128 KiB write block.

**Row walk.** One call per case tries every cut edge.

```nim
proc minimumMoves(ballCounts: seq[int], ballTotal: int): int =
  let boxCount = ballCounts.len
  var bestCost = high(int)
  for cutIndex in 0 .. (boxCount - 1):
    var boxIndex = cutIndex + 1
    if boxIndex >= boxCount: boxIndex = 0
    var ballsSeen = 0
    var filledSlots = 0
    var cutCost = 0
    for linePosition in 1 .. (boxCount - 1):
      ballsSeen += ballCounts[boxIndex]
      var upperBound = ballsSeen
      if filledSlots + 1 < upperBound: upperBound = filledSlots + 1
      let lowerBound = ballTotal - (boxCount - linePosition)
      if lowerBound > upperBound:
        filledSlots = lowerBound
      else:
        filledSlots = upperBound
      if ballsSeen > filledSlots:
        cutCost += ballsSeen - filledSlots
      else:
        cutCost += filledSlots - ballsSeen
      boxIndex += 1
      if boxIndex >= boxCount: boxIndex = 0
    if cutCost < bestCost: bestCost = cutCost
  return bestCost
```

The outer loop covers `boxCount` cuts; the inner loop stops at `boxCount - 1`. `upperBound` and `lowerBound` keep `filledSlots` inside the feasible range. `cutCost` sums the flow across one cut, and `bestCost` keeps the smallest. No allocation happens inside the loops.

**Input buffer.** All lines land in one string before parsing.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
```

`readLine` appends each line and a newline to `inputData`. `scanPos` advances as `nextInt` reads the counts. No token objects or split calls are built.

**Output path.** Answers accumulate, then flush in blocks.

```nim
for _ in 1 .. caseCount:
  let boxCount = nextInt(inputData, scanPos)
  var ballCounts = newSeq[int](boxCount)
  var ballTotal = 0
  for boxIndex in 0 .. (boxCount - 1):
    ballCounts[boxIndex] = nextInt(inputData, scanPos)
    ballTotal += ballCounts[boxIndex]
  outputBuffer.add $minimumMoves(ballCounts, ballTotal)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs `caseCount` times and reads `boxCount` counts per case. `outputBuffer.add $minimumMoves(ballCounts, ballTotal)` appends digits without a per-line write. `setLen 0` reuses the buffer after each `flushBlockBytes` threshold.

## Complexity

The walk does all the work; input and output stay linear.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one digit pass | input bytes |
| One cut walk | n − 1 steps with constant work | a few integers |
| All cuts | n walks, so n(n − 1) steps | `ballCounts` array |
| Output | one write per 128 KiB block | block buffer |

The n walks dominate; input and output add only linear work.

The asymptotic bounds follow from the two nested loops:

| Measure | Big O |
|---|---|
| Time | O(n²) per case, O(t·n²) total |
| Space | O(n) for counts plus the input buffer |

With n at most 1000, the quadratic cost stays small. Choosing occupied boxes directly takes exponential time, so the quadratic row walk is the affordable choice.
