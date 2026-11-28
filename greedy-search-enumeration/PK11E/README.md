# PK11E — Queen Game (SPOJ)

<https://www.spoj.com/problems/PK11E/>

## Problem

Several queens sit on a chessboard and players move one queen up, left, or up-left per turn; the player who moves last wins. Decide whether the first player wins with perfect play.

Input starts with the test count. Each test gives rows, columns, and queen count, then one row and column per queen. Rows start at 1, columns start at 1, and columns reach 10 to the power 15. Print `YES` for a first-player win and `NO` otherwise.

| item | bound |
|---|---|
| rows | 1 to 25 |
| columns | 1 to 10^15 |
| queens per test | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

The small row count makes a per-row Grundy table practical.

Sample input:

```
3
5 5 1
2 3
5 5 2
4 4
4 4
5 5 3
1 2
2 1
2 2
```

Sample output:

```
NO
NO
YES
```

## Idea

Treat each queen as a separate pile game, like several heaps in Nim that share one move counter. A queen's options depend only on its row and column, so its Grundy value is fixed. XOR the values of all queens; a nonzero result means the first player wins.

The table stores one value per row and nearby column. Each cell takes a mex over earlier cells, and later columns repeat with a short period. Naive game-tree search explodes with 1000 queens, while XOR needs one lookup per queen.

The periodic tail turns a column of 10^15 into a small table index.

## Why It Works

1. Subtract one from each coordinate; the queen now sits on two piles.
2. A legal move reduces one pile or reduces both piles by the same amount.
3. This is Wythoff's game, an impartial game, so disjoint queens combine by XOR.
4. Grundy values for a fixed small pile grow linearly and repeat after a preperiod.
5. `grundyValue` maps a huge column back into the stored cycle before returning a value.

| term | meaning |
|---|---|
| `grundyTable` | Grundy value for each small pile pair |
| `periodSteps` | repeat length for each small pile size |
| `preperiodStarts` | first column where the repeat begins |
| `nimSum` | XOR of all queen values in one test |

Symmetry keeps the smaller pile below 25, so only those rows need storage.

The sample's third test has queens at (1,2), (2,1), and (2,2).

```
queen (1,2) -> piles (0,1) -> Grundy 1
queen (2,1) -> piles (1,0) -> Grundy 1
queen (2,2) -> piles (1,1) -> Grundy 2
XOR -> 1 xor 1 xor 2 = 2 -> YES
```

The trace matches the third sample line.

## Code

**Constants.** The small pile bound, table width, and cycle lengths are fixed.

```nim
const flushBlockBytes = 1 shl 17
const sideLimit = 24
const tableLimit = 3000
const markLimit = 4200
const periodSteps: array[0..24, int] = [1, 3, 3, 6, 12, 24, 12, 24, 24, 24, 24, 48, 48, 96, 96, 96, 192, 192, 384, 384, 384, 768, 768, 768, 768]
const preperiodStarts: array[0..24, int] = [0, 0, 0, 8, 9, 27, 37, 92, 102, 127, 224, 277, 347, 382, 613, 693, 771, 865, 919, 1032, 1165, 1252, 1293, 1373, 1732]
```

The widest cycle is 768 columns long.

The preperiod never reaches 1800 columns.

**Table build.** Stamp marks separate options for one cell from permanent row values.

```nim
var temporaryMarks = newSeq[int](markLimit + 1)
var permanentMarks = newSeq[bool](markLimit + 1)
var stampCounter = 0
for sideIndex in 0 .. sideLimit:
  for markIndex in 0 .. markLimit:
    permanentMarks[markIndex] = false
  for columnIndex in 0 .. tableLimit:
    stampCounter += 1
    for smallerSide in 0 .. sideIndex - 1:
      temporaryMarks[grundyTable[smallerSide][columnIndex]] = stampCounter
    var diagonalStep = 1
    while diagonalStep <= sideIndex and diagonalStep <= columnIndex:
      temporaryMarks[grundyTable[sideIndex - diagonalStep][columnIndex - diagonalStep]] = stampCounter
      diagonalStep += 1
    var candidateValue = 0
    while permanentMarks[candidateValue] or temporaryMarks[candidateValue] == stampCounter:
      candidateValue += 1
    grundyTable[sideIndex][columnIndex] = candidateValue
    permanentMarks[candidateValue] = true
```

Each cell takes the smallest unmarked value.

Rows are built in order, so every referenced cell is ready.

**Huge columns.** The periodic tail replaces a direct table lookup.

```nim
proc grundyValue(firstPile: int64, secondPile: int64): int64 =
  var smallerPile = firstPile
  var largerPile = secondPile
  if smallerPile > largerPile:
    swap smallerPile, largerPile
  let sideIndex = int(smallerPile)
  if largerPile <= int64(tableLimit):
    return int64(grundyTable[sideIndex][int(largerPile)])
  let periodLength = int64(periodSteps[sideIndex])
  let cycleStart = int64(preperiodStarts[sideIndex])
  let tableIndex = cycleStart + (largerPile - cycleStart) mod periodLength
  return largerPile + int64(grundyTable[sideIndex][int(tableIndex)] - int(tableIndex))
```

The offset stays constant inside one cycle.

Both piles fit in 64-bit integers.

**Game resolution.** All queens combine through one XOR accumulator.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let queenCount = nextInt(inputData, scanPos)
  var nimSum: int64 = 0
  for queenIndex in 1 .. queenCount:
    let queenRow = int64(nextInt(inputData, scanPos))
    let queenColumn = int64(nextInt(inputData, scanPos))
    nimSum = nimSum xor grundyValue(queenRow - 1, queenColumn - 1)
```

Rows and columns are read but not used beyond parsing.

Each queen adds exactly one Grundy value.

## Complexity

The table is built once, then every queen costs one lookup.

| phase | time | space |
|---|---|---|
| table build | one mex scan per small cell | 25 rows of table values |
| game resolution | one lookup per queen | one input string |
| output | one line per test | block buffer |

The table build dominates because it runs before any test is read.

| measure | Big O |
|---|---|
| time | O(25 * tableLimit^2) once, then O(Q) |
| space | O(25 * tableLimit) |

Q is the number of queens across all tests.

Exploring game trees for 1000 queens is infeasible, while XOR over a fixed table is linear.
