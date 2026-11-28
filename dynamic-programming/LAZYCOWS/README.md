# LAZYCOWS — Lazy Cows (SPOJ)

<https://www.spoj.com/problems/LAZYCOWS/>

## Problem

Cover every cow cell in a two-row strip with exactly K non-overlapping rectangles whose total area is as small as possible. The rectangles must stay inside the strip and may span one row or both rows.

Input starts with t, the number of test cases. Each case gives N, K, B on one line, then N lines of row and column. Output one line per case with the minimum total area.

| Item | Bound |
|---|---|
| Test cases t | not stated |
| Cows N | 1 ≤ N ≤ 1000 |
| Barns K | 1 ≤ K ≤ N |
| Columns B | 1 ≤ B ≤ 15,000,000 |
| Rows | exactly 2 |
| Judge limit | 9000 ms, 1536 MB |

Only columns holding a cow can be rectangle edges, so at most 1000 positions drive the work.

Sample input:

```
1
8 2 9
1 2
1 6
1 7
1 8
1 9
2 2
2 3
2 4
```

Sample output:

```
10
```

## Idea

Think of painting two rows of panels with brushes. You pay for each painted panel, and a wide brush paints both rows at once. Sweep left to right and remember which brushes are still running.

The program uses dynamic programming over the distinct cow columns. The state records the running barns: none, top only, bottom only, two separate barns, or one two-row barn. Each column charges its running barns for the gap, then adds new barns where cows wait. Cost per column is a handful of table updates, so the sweep runs in O(M × K) time for M cow columns.

Trying every set of rectangles grows exponentially. Treating each cow alone misses the saving from one barn covering many cows.

The sweep turns a geometry problem into a small table of five states.

## Why It Works

1. A barn keeps its corners on cow columns, since moving an edge inward onto the nearest cow only removes empty cells.
2. Two barns cannot share a cell, so at most one barn per row crosses any vertical line.
3. The frontier therefore takes five shapes: empty, top, bottom, two separate barns, or one two-row barn.
4. A two-row barn stays two-row until it ends. Letting one row stop early would make an L-shape, which is not a rectangle.
5. A running barn covers every column of the gap, so the gap costs its row count times the gap width.

The terms below drive each table update:

| Term | Meaning |
|---|---|
| `carriedRows[state]` | rows covered by barns crossing the gap |
| `gapWidth` | columns between this cow column and the last one |
| `startOptions[moveIndex]` | rows paid for when new barns start here |
| `stride` | slots for every barn count inside one state |
| `carriedRows[state] * gapWidth` | area added during the sweep between two columns |

The last row shows why wide gaps cost the same as narrow ones in table updates, only with larger values.

A script traces the best two-barn path through the sample columns:

```
column cow_rows state barns area
     2        3     4     1    2
     3        2     4     1    4
     4        2     0     1    6
     6        1     1     2    7
     7        1     1     2    8
     8        1     1     2    9
     9        1     1     2   10
```

State 4 carries one two-row barn through columns 2 to 4. State 0 ends it, and state 1 carries a top-row barn through columns 6 to 9. The trace reaches area 10, matching the sample.

## Code

**Constants.** Row counts, block size, and the unreachable marker.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infiniteCost = 1000000000
const carriedRows = [0, 1, 1, 2, 2]
const stateCount = 5
```

`carriedRows` maps each state to its covered row count. States 3 and 4 both carry two rows. `infiniteCost` marks cells the sweep cannot reach. `flushBlockBytes` caps output memory at 256 KiB.

**Token reader.** Digits come by index from the one input buffer.

```nim
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scan skips whitespace, then builds the value one digit at a time. `scanPos` is a var parameter, so it survives across calls. No token object is built. Every input value is positive, so no sign branch appears.

**Move table.** One call lists the legal moves from a frontier.

```nim
proc addMove(extraList: var array[0 .. 6, int], stateList: var array[0 .. 6, int],
             startList: var array[0 .. 6, int], moveCount: var int,
             extraBarns: int, nextState: int, startRows: int) =
  extraList[moveCount] = extraBarns
  stateList[moveCount] = nextState
  startList[moveCount] = startRows
  moveCount += 1

proc movesFor(state: int, cowMask: int, extraList: var array[0 .. 6, int],
              stateList: var array[0 .. 6, int], startList: var array[0 .. 6, int]): int =
  var moveCount = 0
  if state == 0:
    if cowMask == 1:
      addMove(extraList, stateList, startList, moveCount, 1, 1, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 4, 2)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 1)
    elif cowMask == 2:
      addMove(extraList, stateList, startList, moveCount, 1, 2, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 4, 2)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 1)
    else:
      addMove(extraList, stateList, startList, moveCount, 1, 4, 2)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 2)
      addMove(extraList, stateList, startList, moveCount, 2, 3, 2)
      addMove(extraList, stateList, startList, moveCount, 2, 1, 2)
      addMove(extraList, stateList, startList, moveCount, 2, 2, 2)
      addMove(extraList, stateList, startList, moveCount, 2, 0, 2)
  elif state == 1:
    if (cowMask and 2) != 0:
      addMove(extraList, stateList, startList, moveCount, 1, 3, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 1, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 2, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 1)
    else:
      addMove(extraList, stateList, startList, moveCount, 0, 1, 0)
      addMove(extraList, stateList, startList, moveCount, 0, 0, 0)
  elif state == 2:
    if (cowMask and 1) != 0:
      addMove(extraList, stateList, startList, moveCount, 1, 3, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 2, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 1, 1)
      addMove(extraList, stateList, startList, moveCount, 1, 0, 1)
    else:
      addMove(extraList, stateList, startList, moveCount, 0, 2, 0)
      addMove(extraList, stateList, startList, moveCount, 0, 0, 0)
  elif state == 3:
    addMove(extraList, stateList, startList, moveCount, 0, 3, 0)
    addMove(extraList, stateList, startList, moveCount, 0, 1, 0)
    addMove(extraList, stateList, startList, moveCount, 0, 2, 0)
    addMove(extraList, stateList, startList, moveCount, 0, 0, 0)
  else:
    addMove(extraList, stateList, startList, moveCount, 0, 4, 0)
    addMove(extraList, stateList, startList, moveCount, 0, 0, 0)
  return moveCount
```

`cowMask` marks rows with cows at the current column, so uncovered rows must get new barns. State 4 only continues or ends, never shrinks, which keeps rectangles rectangular. Each move records extra barns, the next state, and newly paid rows. The table holds at most six moves.

**Case setup.** Read the stream once, sort cows, then merge cows sharing a column.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

var extraOptions: array[0 .. 6, int]
var stateOptions: array[0 .. 6, int]
var startOptions: array[0 .. 6, int]

for caseIndex in 0 ..< caseCount:
  let cowCount = nextInt(inputData, scanPos)
  let barnTarget = nextInt(inputData, scanPos)
  discard nextInt(inputData, scanPos)

  var cowColumns = newSeq[int](cowCount)
  var cowRowBits = newSeq[int](cowCount)
  for cowIndex in 0 ..< cowCount:
    let cowRow = nextInt(inputData, scanPos)
    let cowColumn = nextInt(inputData, scanPos)
    cowColumns[cowIndex] = cowColumn
    if cowRow == 1:
      cowRowBits[cowIndex] = 1
    else:
      cowRowBits[cowIndex] = 2

  for sortIndex in 1 ..< cowCount:
    var cursor = sortIndex
    while cursor > 0 and cowColumns[cursor] < cowColumns[cursor - 1]:
      swap cowColumns[cursor], cowColumns[cursor - 1]
      swap cowRowBits[cursor], cowRowBits[cursor - 1]
      cursor -= 1

  var groupColumns = newSeq[int](cowCount)
  var groupMasks = newSeq[int](cowCount)
  var groupCount = 0
  for cowIndex in 0 ..< cowCount:
    if groupCount > 0 and cowColumns[cowIndex] == groupColumns[groupCount - 1]:
      groupMasks[groupCount - 1] = groupMasks[groupCount - 1] or cowRowBits[cowIndex]
    else:
      groupColumns[groupCount] = cowColumns[cowIndex]
      groupMasks[groupCount] = cowRowBits[cowIndex]
      groupCount += 1
```

`inputData` holds the whole stream, so odd spacing cannot desync the reader. The insertion sort moves columns and row bits together. `groupMasks` holds one row bit per column. The width value is read and discarded, since column positions already carry the geometry.

**Sweep.** One pass over cow columns fills the cost table.

```nim
  let stride = barnTarget + 1
  var currentCosts = newSeq[int](stateCount * stride)
  var nextCosts = newSeq[int](stateCount * stride)
  for costIndex in 0 ..< currentCosts.len:
    currentCosts[costIndex] = infiniteCost
  currentCosts[0] = 0
  var previousColumn = 0

  for groupIndex in 0 ..< groupCount:
    let currentColumn = groupColumns[groupIndex]
    let currentCowMask = groupMasks[groupIndex]
    let gapWidth = currentColumn - previousColumn
    for costIndex in 0 ..< nextCosts.len:
      nextCosts[costIndex] = infiniteCost

    for barnsUsed in 0 .. barnTarget:
      for state in 0 ..< stateCount:
        let oldCost = currentCosts[state * stride + barnsUsed]
        if oldCost >= infiniteCost:
          continue
        let baseCost = oldCost + carriedRows[state] * gapWidth
        let moveCount = movesFor(state, currentCowMask, extraOptions, stateOptions, startOptions)
        for moveIndex in 0 ..< moveCount:
          let newBarnCount = barnsUsed + extraOptions[moveIndex]
          if newBarnCount > barnTarget:
            continue
          let candidate = baseCost + startOptions[moveIndex]
          let targetIndex = stateOptions[moveIndex] * stride + newBarnCount
          if candidate < nextCosts[targetIndex]:
            nextCosts[targetIndex] = candidate

    swap currentCosts, nextCosts
    previousColumn = currentColumn
```

`gapWidth` charges running barns for empty columns before the next cow. `movesFor` supplies the legal moves for that column. `swap` turns the old table into scratch space, so no table is allocated per column. Only states with exactly `barnTarget` matter at the end.

**Answer and flush.** Emit one minimum area per case.

```nim
  var minimumArea = infiniteCost
  for finalState in 0 ..< stateCount:
    let candidate = currentCosts[finalState * stride + barnTarget]
    if candidate < minimumArea:
      minimumArea = candidate

  outputBuffer.add $minimumArea
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

`minimumArea` scans every final frontier, since open barns simply end at the last cow. `outputBuffer.add $minimumArea` appends the digits without a per-line write. The final write covers the tail and stays safe on an empty buffer.

## Complexity

The work splits into input, sorting, the sweep, and output:

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over bytes, then one digit pass | input bytes |
| Sort and group | insertion sort over N cows | N cow pairs |
| Sweep | at most six moves per state and column | 5 × (K + 1) cells |
| Output | one write per 256 KiB block | block buffer |

The sweep holds only two small tables, independent of B and of the strip area.

The overall bounds are:

| Measure | Big O |
|---|---|
| Time | O(M × K) per case, with M distinct cow columns ≤ N |
| Space | O(N + K) per case |

Choosing rectangle sets by brute force takes exponential time, while this five-state sweep stays within O(N × K).
