<https://www.spoj.com/problems/GAMEFIL/>

## Problem

Given a live-cell pattern on a toroidal grid, count how many previous patterns evolve into it under Conway's Life rules. Report zero as a Garden of Eden.

Each test case starts with `m n`, the row and column counts. The next line holds `k`, the number of live cells. Then `k` lines each hold a zero-based row and column. A line `0 0` ends the input. Output `Case i:` followed by the count and `possible ancestors.`, or `Garden of Eden.` when the count is zero.

| item | bound |
|---|---|
| grid cells | `m * n` at most 16 |
| rows and columns | positive integers |
| live cells | `0` to `m * n` |
| judge limit | 1000 ms, 1536 MB |

The grid wraps at both edges, so a cell can meet the same neighbor through more than one direction.

Sample input:

```
2 3
2
0 0
0 1
3 3
4
0 0
0 1
0 2
1 1
3 3
5
0 0
1 0
1 2
2 1
2 2
0 0
```

Sample output:

```
Case 1: 3 possible ancestors.
Case 2: 1 possible ancestors.
Case 3: Garden of Eden.
```

## Idea

Treat the parent pattern like a combination lock with one dial per cell, then try every combination. Brute-force enumeration over all cell subsets is exact because the grid has at most 16 cells. Each candidate needs one pass to add neighbor counts and one pass to apply the Life rules. A list of precomputed neighbors avoids repeated offset arithmetic. The takeaway is that a small state space makes direct counting simpler than search.

## Why It Works

1. A binary mask encodes a parent pattern with one bit per cell.
2. Adding each occupied cell's eight offsets to its neighbors gives every cell's neighbor count.
3. An occupied cell with two or three neighbors survives; an empty cell with exactly three is born.
4. The resulting mask equals the target for exactly the valid parents.
5. Counting all masks therefore gives the exact answer.

| term | meaning |
|---|---|
| `targetMask` | bits of the live cells in the given pattern |
| `neighborTable` | eight wrapped neighbor indices per cell |
| `neighborCounts` | occupied neighbors of each cell in one candidate |
| `nextMask` | pattern produced by the Life rules |
| `ancestorCount` | number of candidates whose next mask matches |

Each mask is checked once, so no valid parent is missed.

A 2 by 3 parent with live cells `(0,0)` and `(1,2)` has mask `33`. Its neighbor-count grid is `2 3 3` above `3 3 2`. The Life rules turn it into all six cells, so that parent matches a full target.

Wrapped neighbors keep their multiplicity, so a 1 by 1 cell counts itself eight times. No rounding is needed because every value is an integer.

## Code

**Input and scanning.** The reader loads all input and parses integers with a hand scanner.

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
```

Whitespace and line breaks do not affect token parsing.
The zero case stops the dataset loop.
The scanner advances one character per accepted digit.

**Output helper.** One buffer collects the report lines and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs leave the buffer through a single write path.
Short outputs flush once at the end.

**Parent enumeration.** Each mask is expanded into neighbor counts and then into a child pattern.

```nim
var caseNumber = 0
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  caseNumber += 1
  let cellCount = rowCount * columnCount
  let liveCellCount = nextInt(inputData, scanPos)
  var targetMask = 0
  for liveIndex in 0 .. liveCellCount - 1:
    let liveRow = nextInt(inputData, scanPos)
    let liveColumn = nextInt(inputData, scanPos)
    targetMask = targetMask or (1 shl (liveRow * columnCount + liveColumn))
  var neighborTable = newSeq[seq[int]](cellCount)
  for cellRow in 0 .. rowCount - 1:
    for cellColumn in 0 .. columnCount - 1:
      var neighborList = newSeq[int](8)
      var offsetIndex = 0
      for offsetRow in -1 .. 1:
        for offsetColumn in -1 .. 1:
          if offsetRow == 0 and offsetColumn == 0:
            continue
          let wrapRow = (cellRow + offsetRow + rowCount) mod rowCount
          let wrapColumn = (cellColumn + offsetColumn + columnCount) mod columnCount
          neighborList[offsetIndex] = wrapRow * columnCount + wrapColumn
          offsetIndex += 1
      neighborTable[cellRow * columnCount + cellColumn] = neighborList
  var neighborCounts = newSeq[int](cellCount)
  var ancestorCount = 0
  for parentMask in 0 .. (1 shl cellCount) - 1:
    for cellIndex in 0 .. cellCount - 1:
      neighborCounts[cellIndex] = 0
    for cellIndex in 0 .. cellCount - 1:
      if (parentMask and (1 shl cellIndex)) != 0:
        for offsetIndex in 0 .. 7:
          neighborCounts[neighborTable[cellIndex][offsetIndex]] += 1
    var nextMask = 0
    for cellIndex in 0 .. cellCount - 1:
      let occupied = (parentMask and (1 shl cellIndex)) != 0
      let neighborTotal = neighborCounts[cellIndex]
      let survives = occupied and (neighborTotal == 2 or neighborTotal == 3)
      let born = (not occupied) and neighborTotal == 3
      if survives or born:
        nextMask = nextMask or (1 shl cellIndex)
    if nextMask == targetMask:
      ancestorCount += 1
  appendOutput("Case " & $caseNumber & ": ")
  if ancestorCount == 0:
    appendOutput("Garden of Eden.\n")
  else:
    appendOutput($ancestorCount & " possible ancestors.\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The neighbor table is built once per case.
Counts are reset before each candidate mask.
The report uses the exact sample wording.

## Complexity

The neighbor table is built once per case, then every mask is expanded and compared.

| phase | time | space |
|---|---|---|
| input read | one pass over the case tokens | one input string |
| neighbor table | eight offsets per cell | eight indices per cell |
| mask scan | `2^(m*n)` masks times `m*n` cells | counts for `m*n` cells |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | `O(m*n*2^(m*n))` |
| space per case | `O(m*n)` |

A fresh neighbor scan per candidate would repeat offset work, while the table removes it.

The wrap table keeps enumeration exact for every grid size in the statement.
