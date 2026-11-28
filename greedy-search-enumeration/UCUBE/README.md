# UCUBE — The Unstable Cube (SPOJ)

<https://www.spoj.com/problems/UCUBE/>

## Problem

Six flat pictures show the first painted block seen from each side of an N by N by N cube. Find the most blocks that can remain while all six pictures still match.

Input: `t`, then `t` cases. Each case starts with `N`. Then `N` lines follow, each holding six strings of `N` characters in the order front, left, back, right, top, bottom. A letter means a block of that color. A dot means the whole sight line is empty. The input always describes some real cube.

Output: one line per case with the maximum number of blocks.

| item | bound |
|---|---|
| cube side `N` | 1 to 10 |
| cells per cube | at most 1000 |
| sight lines per view | `N` squared |
| judge limit | 1000 ms, 1536 MB |

The 1000-cell grid bounds the work. The case count only repeats that small pass.

Sample input:

```
2
3
.R. YYR .Y. RYY .Y. .R.
GRB YGR BYG RBY GYB GRB
.R. YRR .Y. RRY .R. .Y.
2
ZZ ZZ ZZ ZZ ZZ ZZ
ZZ ZZ ZZ ZZ ZZ ZZ
```

Sample output:

```
11
8
```

## Idea

Start with every cell present, then erase only the cells a picture proves impossible. Think of crossing names off a list. A picture names the first block on a line. A cell needing two different names cannot stay.

The algorithm is iterative constraint propagation. Each photo cell scans at most `N` depths, so one pass costs six times `N` cubed steps. A handful of passes finish because a cell changes state at most twice: once from undecided to colored, and once from colored to empty.

Testing every subset of cells would cost two to the N cubed steps. That reaches two to the 1000 at the largest size, so it cannot run.

Takeaway: keep every possible block and peel off only the proven-impossible ones.

## Why It Works

1. A dot pixel empties every cell on its sight line. The scan clears those cells before any color is assigned.
2. A letter pixel requires the first surviving cell on its line to carry that letter. Otherwise the picture would show a different color.
3. When that first cell carries another letter, no closer cell exists. The cell cannot stay, so the scan removes it and looks deeper.
4. Removal only exposes deeper cells on the same lines. Each cell is removed once, so the passes stop.
5. Every removed cell is impossible in any valid cube. The survivors satisfy every picture, so their count is the maximum.

The state of a cell and the cost of one scan:

| term | meaning |
|---|---|
| `cubeStates` | holds `#` for undecided, a letter for a decided color, or `.` for empty |
| `rayCellIndices` | holds the cube cell met at each depth of one sight line |
| `viewCell` | turns a picture row, column and depth into cube coordinates |
| `changeDetected` | records any coloring or removal, so another pass must run |

The table separates state from work. A cell loses its block only after a real contradiction.

A script traces the two-by-two case built from three colored blocks:

```
view order: front left back right top bottom
row 0 C. .C .C C. A. CB
row 1 AB AB BA BA CB A.
after clear-through rays, candidates: 4
round 1 first-block demands:
  cell 0 colors ABC removed
  cell 1 colors A kept
  cell 2 colors C kept
  cell 4 colors B kept
round 2 first-block demands:
  cell 1 colors A kept
  cell 2 colors C kept
  cell 4 colors B kept
surviving cells: 3
```

Cell 0 sits closest to three viewers, which ask for A, B and C. No single color satisfies all three, so the cell leaves. Three blocks remain, matching the sample rule.

## Code

**Constants and token readers.** These fix the buffer sizes and read numbers and picture strings without allocating token objects.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSide = 10
const maxSideSquared = 100
const viewCount = 6
const cubeCapacity = 1000
const rayCapacity = 6000
const emptyMark = '.'
const unknownMark = '#'

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc nextToken(inputData: string, scanPos: var int): string =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  let tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos += 1
  return inputData[tokenStart .. scanPos - 1]
```

The ray array holds six times 100 times 10 entries. `scanPos` advances by index, so no substring is parsed.

**Coordinate map.** This turns each picture pixel and depth into one of the 1000 cube cells.

```nim
proc viewCell(viewIndex, viewRow, viewCol, viewDepth, cubeSize: int): tuple[x, y, z: int] =
  case viewIndex
  of 0: result = (viewCol, cubeSize - 1 - viewRow, viewDepth)
  of 1: result = (viewDepth, cubeSize - 1 - viewRow, cubeSize - 1 - viewCol)
  of 2: result = (cubeSize - 1 - viewCol, cubeSize - 1 - viewRow, cubeSize - 1 - viewDepth)
  of 3: result = (cubeSize - 1 - viewDepth, cubeSize - 1 - viewRow, viewCol)
  of 4: result = (viewCol, cubeSize - 1 - viewDepth, cubeSize - 1 - viewRow)
  else: result = (viewCol, viewDepth, viewRow)
```

Rows run top to bottom and depth runs from the viewer inward. The last branch covers the bottom view.

**Stream read and block writer.** The driver reads stdin once and writes answers in large blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

proc appendAnswer(answerValue: int) =
  outputBuffer.add $answerValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One `readLine` loop captures every byte. The 256 KiB block keeps write calls rare.

**Case setup.** Buffers live outside the case loop and only the live portion is reset.

```nim
var viewGrid: array[0 .. viewCount - 1, array[0 .. maxSide - 1, string]]
var cubeStates: array[0 .. cubeCapacity - 1, char]
var rayCellIndices: array[0 .. rayCapacity - 1, int]

for caseIndex in 0 ..< caseCount:
  let cubeSize = nextInt(inputData, scanPos)
  for viewRow in 0 ..< cubeSize:
    for viewIndex in 0 ..< viewCount:
      viewGrid[viewIndex][viewRow] = nextToken(inputData, scanPos)

  for cellX in 0 ..< cubeSize:
    for cellY in 0 ..< cubeSize:
      for cellZ in 0 ..< cubeSize:
        cubeStates[(cellX * cubeSize + cellY) * cubeSize + cellZ] = unknownMark
```

Input arrives row by row, with six strings per row. Reusing the buffers avoids clearing 7000 slots per case.

**Ray build and dot clearing.** This stores each sight line once and empties the cells behind dot pixels.

```nim
  for viewIndex in 0 ..< viewCount:
    for viewRow in 0 ..< cubeSize:
      for viewCol in 0 ..< cubeSize:
        let rayBase = (viewIndex * maxSideSquared + viewRow * cubeSize + viewCol) * cubeSize
        for viewDepth in 0 ..< cubeSize:
          let cellCoords = viewCell(viewIndex, viewRow, viewCol, viewDepth, cubeSize)
          let cellPosition = (cellCoords.x * cubeSize + cellCoords.y) * cubeSize + cellCoords.z
          rayCellIndices[rayBase + viewDepth] = cellPosition
          if viewGrid[viewIndex][viewRow][viewCol] == emptyMark:
            cubeStates[cellPosition] = emptyMark
```

`rayBase` gives each ray a fixed slice of `rayCellIndices`. Every dot ray clears its slice in one scan.

**Propagation loop.** This pass colors the first free cell or removes a cell with the wrong color.

```nim
  var changeDetected = true
  while changeDetected:
    changeDetected = false
    for viewIndex in 0 ..< viewCount:
      for viewRow in 0 ..< cubeSize:
        for viewCol in 0 ..< cubeSize:
          let expectedColor = viewGrid[viewIndex][viewRow][viewCol]
          if expectedColor == emptyMark:
            continue
          let rayBase = (viewIndex * maxSideSquared + viewRow * cubeSize + viewCol) * cubeSize
          for viewDepth in 0 ..< cubeSize:
            let cellPosition = rayCellIndices[rayBase + viewDepth]
            let currentState = cubeStates[cellPosition]
            if currentState == emptyMark:
              continue
            if currentState == unknownMark:
              cubeStates[cellPosition] = expectedColor
              changeDetected = true
              break
            if currentState == expectedColor:
              break
            cubeStates[cellPosition] = emptyMark
            changeDetected = true
```

The scan stops at a matching color and keeps going after a removal. Each cell changes at most twice.

**Count and tail flush.** The last loop counts survivors and the final write covers the block remainder.

```nim
  var remainingBlocks = 0
  for cellX in 0 ..< cubeSize:
    for cellY in 0 ..< cubeSize:
      for cellZ in 0 ..< cubeSize:
        let cellPosition = (cellX * cubeSize + cellY) * cubeSize + cellZ
        if cubeStates[cellPosition] != emptyMark:
          remainingBlocks += 1
  appendAnswer(remainingBlocks)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The count visits only cells inside the cube. One tail write covers the final partial block.

## Complexity

The work splits into a one-time read, a small case setup, a few propagation passes and one write path.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes and tokens | input bytes |
| case setup | `N` cubed resets plus six times `N` squared ray entries | 1000 cells and 6000 indices |
| propagation | a few passes over six times `N` squared rays of depth `N` | buffers reused |
| output write | one write per 256 KiB block | block buffer |

The buffers are fixed at 1000 cells and 6000 ray slots, independent of the case count.

| measure | Big O |
|---|---|
| time | O(p times `N` cubed) per case, for p passes |
| space | O(`N` cubed) for cells and ray indices, plus input and block buffers |

Each cell changes at most twice, so p stays small. Checking all subsets would cost two to the N cubed steps, which is impossible at N = 10.
