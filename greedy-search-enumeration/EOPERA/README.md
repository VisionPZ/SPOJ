# EOPERA — Exchange Operations (SPOJ)

<https://www.spoj.com/problems/EOPERA/>

## Problem

Twelve cells hold the numbers 0 through 11. A move swaps the zero with another cell at a fixed distance, and both cells must stay inside the same block. Compute the fewest moves that restore the sorted order.

Input: a count `T`, then `T` lines. Each line holds twelve space-separated numbers, a permutation of 0 through 11. The statement guarantees every case can be sorted.

Output: one integer per case, the minimum number of moves.

The bounds from the statement and judge:

| Item | Bound |
|---|---|
| sequence length | 12 |
| tile values | 0 through 11 |
| jump distances | 1, 3, 6, 12 |
| block sizes | 3, 6, 12 |
| judge time limit | 2574 ms |
| memory limit | 1536 MB |
| source limit | 50000 B |

The board has only twelve cells, so the program can search states directly.

The sample case:

```
2
1 10 2 3 0 5 7 4 8 6 9 11
6 4 1 0 3 5 9 7 2 10 11 8
```

```
8
9
```

## Idea

Walk the zero across the board like a traveler who tracks the distance to every destination. A running score adds the remaining distance of all other tiles.

Those rules form a graph with twelve vertices and twenty undirected edges. A move slides the zero along one edge and swaps it with the tile there.

The algorithm is iterative deepening A*, called IDA*. The score adds, for every tile except zero, the shortest edge count from that tile's cell to its home cell. Each move updates one term in constant time, and each state considers at most four moves.

Plain breadth-first search stores every state up to the answer length. At depth twenty that means millions of states, while IDA* follows only paths that can still beat the current bound.

Each pass raises the bound to the shortest failing path. The first pass that reaches sorted order proves the minimum.

Search by bounds, and let the distance score cut the dead ends.

## Why It Works

1. A legal move joins cells at distance 1, 3, or 6. The block test keeps both cells inside one block of size 3, 6, or 12. The value 12 is only the last block size.
2. A move changes one tile's distance to home by a single step, closer or farther. The sum over the other eleven tiles drops by at most one, so it never exceeds the moves still needed.
3. Swapping back along the edge used in the previous move returns to the earlier state. Skipping that edge cannot remove an optimal path.
4. Passes use bounds in increasing order. A goal found at bound L rules out every path shorter than L.

The main terms:

| Term | Meaning |
|---|---|
| `positionDistance` | fewest legal zero moves between two cells |
| `heuristicValue` | sum of those distances for every tile except zero |
| `currentBound` | longest path the current pass may follow |
| `bestCandidate` | shortest failing path returned by a state's children |

The score is a lower bound, so pruning by the bound keeps every optimal path.

A script traced the first sample case from the distance table:

```
blank cell: 4
cell  tile  distance to home
0     1     1
1     10    2
2     2     0
3     3     0
5     5     0
6     7     1
7     4     2
8     8     0
9     6     1
10    9     1
11    11    0
sum of distances: 8
bounds tried: 8
nodes visited: 12
exact answer: 8
```

The score already equals the answer here, so one pass finishes the case.

## Code

**Board constants.** These values are fixed before any input is read.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const tileCount = 12
const jumpSizes = [1, 3, 6, 12]
const unreachableDistance = 1000
```

The jump list comes straight from the statement. `flushBlockBytes` sets the 128 KiB output block.

**Legal moves and cell distances.** Built once, before the test cases.

```nim
proc buildPositionDistances() =
  for firstPosition in 0 .. tileCount - 1:
    for secondPosition in 0 .. tileCount - 1:
      positionDistance[firstPosition][secondPosition] = unreachableDistance
    positionDistance[firstPosition][firstPosition] = 0
  for firstPosition in 0 .. tileCount - 1:
    for secondPosition in firstPosition + 1 .. tileCount - 1:
      for stepIndex in 0 .. 2:
        if abs(firstPosition - secondPosition) != jumpSizes[stepIndex]: continue
        if firstPosition div jumpSizes[stepIndex + 1] != secondPosition div jumpSizes[stepIndex + 1]: continue
        neighbors[firstPosition][neighborCounts[firstPosition]] = secondPosition
        neighbors[secondPosition][neighborCounts[secondPosition]] = firstPosition
        inc neighborCounts[firstPosition]
        inc neighborCounts[secondPosition]
        positionDistance[firstPosition][secondPosition] = 1
        positionDistance[secondPosition][firstPosition] = 1
        break
  for viaPosition in 0 .. tileCount - 1:
    for firstPosition in 0 .. tileCount - 1:
      for secondPosition in 0 .. tileCount - 1:
        let throughDistance = positionDistance[firstPosition][viaPosition] + positionDistance[viaPosition][secondPosition]
        if throughDistance < positionDistance[firstPosition][secondPosition]:
          positionDistance[firstPosition][secondPosition] = throughDistance
```

The pair loop ends at `tileCount - 1`, so no cell pairs with itself. The second condition uses the next jump size as the block size. Three nested relaxations finish in constant time on twelve cells.

**Token reader.** Digits are scanned by index, so no token object is built.

```nim
proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scan position survives across calls, so spacing cannot desync the reader. A digit byte becomes `int(data[scanPos]) - firstDigitValue` without a parse call.

**Score.** The sum skips the zero cell.

```nim
proc startingHeuristic(blankPosition: int): int =
  var total = 0
  for positionIndex in 0 .. tileCount - 1:
    if positionIndex != blankPosition:
      total += positionDistance[positionIndex][tileState[positionIndex]]
  return total
```

Each term is a shortest edge count. One pass over twelve cells sets the first bound.

**Bounded search.** One recursive pass at a fixed bound.

```nim
proc searchSolution(blankPosition, previousPosition, heuristicValue, depth: int): int =
  if heuristicValue == 0:
    solvedDepth = depth
    return depth
  if depth + heuristicValue > currentBound:
    return depth + heuristicValue
  var orderedTargets: array[4, int]
  var orderedHeuristics: array[4, int]
  var orderedCount = 0
  let neighborTotal = neighborCounts[blankPosition]
  for neighborIndex in 0 .. neighborTotal - 1:
    let targetPosition = neighbors[blankPosition][neighborIndex]
    if targetPosition == previousPosition: continue
    let movedTile = tileState[targetPosition]
    let nextHeuristic = heuristicValue - positionDistance[targetPosition][movedTile] + positionDistance[blankPosition][movedTile]
    var insertAt = orderedCount
    while insertAt > 0 and nextHeuristic < orderedHeuristics[insertAt - 1]:
      orderedHeuristics[insertAt] = orderedHeuristics[insertAt - 1]
      orderedTargets[insertAt] = orderedTargets[insertAt - 1]
      insertAt -= 1
    orderedHeuristics[insertAt] = nextHeuristic
    orderedTargets[insertAt] = targetPosition
    orderedCount += 1
  var bestCandidate = high(int)
  for moveIndex in 0 .. orderedCount - 1:
    let targetPosition = orderedTargets[moveIndex]
    swap tileState[blankPosition], tileState[targetPosition]
    let candidate = searchSolution(targetPosition, blankPosition, orderedHeuristics[moveIndex], depth + 1)
    swap tileState[blankPosition], tileState[targetPosition]
    if solvedDepth >= 0: return solvedDepth
    if candidate < bestCandidate: bestCandidate = candidate
  return bestCandidate
```

A state with a zero score is the goal. The previous cell never reappears as a target. The score changes by one term, so each move costs constant work.

**Bound loop.** Raises the limit until a pass finds the goal.

```nim
proc solveCase(blankPosition: int): int =
  let initialHeuristic = startingHeuristic(blankPosition)
  if initialHeuristic == 0: return 0
  solvedDepth = -1
  currentBound = initialHeuristic
  var previousBound = currentBound - 1
  while solvedDepth < 0:
    if currentBound <= previousBound: currentBound = previousBound + 1
    previousBound = currentBound
    currentBound = searchSolution(blankPosition, -1, initialHeuristic, 0)
  return solvedDepth
```

The first bound is the score from `startingHeuristic`. The guard forces progress when a pass fails without a larger candidate.

**Driver.** One read of everything, and writes in 128 KiB blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
buildPositionDistances()
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  for positionIndex in 0 .. tileCount - 1:
    tileState[positionIndex] = nextInt(inputData, scanPos)
  var blankPosition = 0
  for positionIndex in 0 .. tileCount - 1:
    if tileState[positionIndex] == 0: blankPosition = positionIndex
  appendOutput($(solveCase(blankPosition)))

stdout.write outputBuffer
```

Lines are appended to `inputData`, so odd spacing cannot shift the token stream. The last write flushes the tail, even when nothing remains.

## Complexity

The costs break down by phase:

| Phase | Time | Space |
|---|---|---|
| input read | one pass over lines, then one digit pass | input bytes |
| distance table | twelve cubed relaxation steps | 144 integers |
| one search pass | at most four moves per visited state | two four-slot arrays |
| output | one write per 128 KiB block | block buffer |

Every phase stays small because the board has twelve cells.

The asymptotic bounds for an answer of length L:

| Measure | Big O |
|---|---|
| time per pass | O(4 ^ L) |
| total time | O(4 ^ L) |
| space | O(12 ^ 2) plus input and output buffers |

Breadth-first search also takes O(4 ^ L) time. It stores every state at depth L and lacks the ordering that lets IDA* stop early.
