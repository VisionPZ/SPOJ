# TOURS — Travelling tours (SPOJ)

<https://www.spoj.com/problems/TOURS/>

## Problem

Given one-way streets between places, split all places into directed cycles with the smallest total street length. Each place has one outgoing street and one incoming street, and every cycle holds at least two places.

Input: a test count t, then for each case a line with N and M, then M lines with start, end, and length. Output: one line per case with the minimum total length. Places are numbered from 1 to N.

The statement and judge give these bounds:

| Item | Bound |
|---|---|
| Test cases t | at most 15 |
| Places N | 2 to 200 |
| Street length | at most 10000 |
| Distinct directed streets | at most 39800 |
| Judge limits | 1000 ms, 1536 MB |

N = 200 in 15 cases drives the cubic solver design.

The sample case:

```
2
6 9
1 2 5
2 3 5
3 1 10
3 4 12
4 1 8
4 6 11
5 4 7
5 6 9
6 5 4
5 8
1 2 4
2 1 7
1 3 10
3 2 10
3 4 10
4 5 10
5 3 10
5 4 3
```

Its expected output:

```
42
40
```

The first answer is 42, the second 40.

## Idea

Pick one outgoing street per place and one incoming street per place, like assigning each worker one job and each job one worker. That is the assignment problem. The Hungarian algorithm solves it with row and column potentials. Each step grows the matching by one place and scans at most N columns. One step costs O(N^2) work, so one case costs O(N^3). Listing all cycle covers enumerates factorially many permutations and cannot scale to 200 places. The chosen edges already form disjoint cycles of at least two places, so the program never builds a tour explicitly. The cheapest assignment is the cheapest set of tours.

## Why It Works

Four facts prove the reduction and the solver.

1. One outgoing street per place means choosing a destination for each place.
2. One incoming street per place means every destination is chosen once, so destinations form a permutation.
3. A permutation splits into disjoint directed cycles, and blocking the diagonal forces every cycle to hold at least two places.
4. Hungarian finds the cheapest permutation by fixing potentials and growing a matching one row at a time.

The terms used by the program:

| Term | Meaning |
|---|---|
| `costMatrix` | flat table of street lengths, indexed by row and column |
| `impossibleCost` | price of a missing street or a self-loop |
| `matrixStride` | row width of the flat table |
| `minExtraCost` | cheapest reduced cost found so far for each column |
| `rowPotential` | price offset attached to a row |
| `colPotential` | price offset attached to a column |
| `-colPotential[0]` | final minimum total length |

Potentials keep reduced costs non-negative, so each step reaches a cheapest free column.

A script traces the first sample case over its six places:

```
row/col  1     2     3     4     5     6
1        -     5     -     -     -     -
2        -     -     5     -     -     -
3       10     -     -    12     -     -
4        8     -     -     -     -    11
5        -     -     -     7     -     9
6        -     -     -     -     4     -

row 1: deltas 5, total 5
row 2: deltas 5, total 10
row 3: deltas 10, total 20
row 4: deltas 8, 2, total 30
row 5: deltas 7, 0, 1, total 38
row 6: deltas 4, total 42

final edges: 1->2 (5), 2->3 (5), 3->1 (10), 4->6 (11), 5->4 (7), 6->5 (4)
```

The last line sums to 42, the first sample answer.

## Code

**Reading and scanning.** One loop captures the stream, and the scanner walks it by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxPlaceCount = 200
const matrixStride = maxPlaceCount + 1
const impossibleCost = int64(1 shl 50)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and data[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The read loop ends only at the end of the stream, so blank lines cannot desync the reader. `nextInt` builds each value from digit bytes and advances `scanPos` by index. No sign branch is needed because counts and lengths are non-negative.

**Assignment solver.** Each augmentation grows the matching by one row.

```nim
var costMatrix = newSeq[int64](matrixStride * matrixStride)
var rowPotential = newSeq[int64](matrixStride)
var colPotential = newSeq[int64](matrixStride)
var columnOwner = newSeq[int](matrixStride)
var parentColumn = newSeq[int](matrixStride)
var minExtraCost = newSeq[int64](matrixStride)
var usedColumn = newSeq[bool](matrixStride)

proc minimumCoverCost(placeCount: int): int64 =
  for row in 0 .. placeCount:
    rowPotential[row] = 0
    colPotential[row] = 0
    columnOwner[row] = 0
  for freeRow in 1 .. placeCount:
    columnOwner[0] = freeRow
    var currentColumn = 0
    for column in 0 .. placeCount:
      usedColumn[column] = false
      minExtraCost[column] = impossibleCost
      parentColumn[column] = 0
    while true:
      usedColumn[currentColumn] = true
      let sourceRow = columnOwner[currentColumn]
      let sourceBase = sourceRow * matrixStride
      let sourcePotential = rowPotential[sourceRow]
      var smallestDelta = impossibleCost
      var nextColumn = 0
      for column in 1 .. placeCount:
        if not usedColumn[column]:
          let reducedCost = costMatrix[sourceBase + column] - sourcePotential - colPotential[column]
          if reducedCost < minExtraCost[column]:
            minExtraCost[column] = reducedCost
            parentColumn[column] = currentColumn
          if minExtraCost[column] < smallestDelta:
            smallestDelta = minExtraCost[column]
            nextColumn = column
      for column in 0 .. placeCount:
        if usedColumn[column]:
          rowPotential[columnOwner[column]] += smallestDelta
          colPotential[column] -= smallestDelta
        else:
          minExtraCost[column] -= smallestDelta
      currentColumn = nextColumn
      if columnOwner[currentColumn] == 0: break
    while currentColumn != 0:
      let priorColumn = parentColumn[currentColumn]
      columnOwner[currentColumn] = columnOwner[priorColumn]
      currentColumn = priorColumn
  return -colPotential[0]
```

The loop over `freeRow` adds exactly one matched row per augmentation. `impossibleCost` blocks both missing streets and self-loops, so every cycle holds at least two places. `parentColumn` records the alternating path that ends at a free column. Each update touches only columns inside the current tree, and `-colPotential[0]` returns the total.

**Driver.** One pass fills the matrix and writes answers in blocks.

```nim
var outputBuffer = ""
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let placeCount = nextInt(inputData, scanPos)
  let streetCount = nextInt(inputData, scanPos)
  for row in 0 .. placeCount:
    let rowBase = row * matrixStride
    for column in 0 .. placeCount:
      costMatrix[rowBase + column] = impossibleCost
  for streetIndex in 0 ..< streetCount:
    let fromPlace = nextInt(inputData, scanPos)
    let toPlace = nextInt(inputData, scanPos)
    let streetLength = int64(nextInt(inputData, scanPos))
    let position = fromPlace * matrixStride + toPlace
    if streetLength < costMatrix[position]:
      costMatrix[position] = streetLength
  outputBuffer.add $(minimumCoverCost(placeCount))
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

Each case resets the flat matrix, then keeps the shortest street for repeated pairs. `flushBlockBytes` caps the buffer at 128 KiB. The final `stdout.write` emits the tail and stays a no-op on an empty buffer.

## Complexity

The work splits into input, solver, and output phases:

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over bytes, one digit pass per token | input bytes |
| Matrix reset | N^2 writes per case | 201 by 201 entries |
| Solver | N augmentations of O(N^2) each | arrays of 201 slots |
| Output | one write per 128 KiB block | 128 KiB block |

Input bytes dominate space, and the solver dominates time.

The asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(t × N^3) |
| Space | O(N^2) |

Listing every cover costs O(N!) instead, which cannot run for N = 200.
