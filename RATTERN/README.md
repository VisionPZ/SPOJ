# RATTERN — The Room Pattern (SPOJ)

<https://www.spoj.com/problems/RATTERN/>

## Problem

A room grid marks each square white, black, or already paved. Cover the remaining squares with whole tiles whose colors match the grid, at the lowest total cost.

Input: `t`, then `t` cases. Each case gives `N M K`, then `N` rows of `M` numbers, then `K` lines in the form `form cost painting`. A number of 0 means white, 1 means black, and 2 means already paved. Painting length is 1 for form 1, 2 for form 2, and 3 for forms 3 and 4. Output one line per case: the minimum cost, or `-1` when no tiling exists.

The bounds from the statement:

| Item | Bound |
|---|---|
| Room sides `N`, `M` | 1 to 8 |
| Tile types `K` | 1 to 10 |
| Tile cost | at most 10000 |
| Squares per tile | 1 to 3 |
| Judge limit | 17 s, 1536 MB |

A room holds at most 64 squares, so one 64-bit word holds the covered set.

The sample case:

```
1
4 3 3
2 2 2
2 0 0
2 1 2
2 2 2
2 10 0 0
1 5 1
4 6 0 0 1
```

```
15
```

## Idea

Fill the first empty square first, like solving a crossword left to right. The algorithm is recursive exact cover with memoization. A 64-bit mask records covered squares. Each call tries every rotation of every tile type anchored at the first open square. A state costs at most 40 placements, since ten types have at most four rotations each. Testing every subset would cost 2^64 checks, while memoization pays once per reachable mask. A gcd check drops remaining counts that no tile size can sum to. Pack the board into one word, fill the first gap, and cache every state.

## Why It Works

1. A quarter turn keeps the cell count and the numbered colors of a tile. The shape library stores only distinct rotations.
2. The first open square must belong to the next tile, since earlier squares are covered. Anchoring the tile's first cell there loses no tiling.
3. One bitwise test rejects overlapping placements. Squares marked 2 start with their bits set.
4. A mask always has the same cheapest completion, so memoization returns it at once.
5. If all tile sizes share a divisor, the remaining count must also be a multiple. The gcd check rejects other counts without search.

The main terms and formulas:

| Term | Meaning |
|---|---|
| `allMask` | bits for every square in the room |
| `firstOpen` | index of the lowest uncovered square |
| `sizeGcd` | greatest common divisor of available tile sizes |
| `placementBits` | squares covered by one anchored tile |

The gcd rule prunes whole branches before any tile is placed.

A script-traced worked example from the generator:

```
step 1: first open cell (1, 1), color 0
  tile cost 10, covers [(1, 1), (1, 2)], remaining [(2, 1)]
  choose cost 10, running total 10
step 2: first open cell (2, 1), color 1
  tile cost 5, covers [(2, 1)], remaining []
  choose cost 5, running total 15
answer 15
```

The two chosen tiles cost 10 and 5, so the answer is 15.

## Code

**Constants and token reader.** This block sets fixed bounds and parses integers from one buffer.

```nim
import sequtils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const impossibleCost = 1 shl 28
const formCellCount: array[0..4, int] = [0, 1, 2, 3, 3]
const hashMultiplier = 11400714819323198485'u64

type
  CellSpec = object
    rowOffset: int
    colOffset: int
    paintIndex: int

  ShapeRotation = object
    cells: array[0..2, CellSpec]
    count: int

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value```

`firstDigitValue` turns a digit byte into its value. `flushBlockBytes` caps the output buffer at 128 KiB. The scanner skips separators and builds each integer digit by digit. Reading the whole stream once keeps parsing to one pass.

**Rotation library and per-case state.** This block defines shapes and the arrays reused by every case.

```nim
proc sameRotation(left, right: ShapeRotation): bool =
  if left.count != right.count: return false
  for idx in 0 .. left.count - 1:
    if left.cells[idx].rowOffset != right.cells[idx].rowOffset: return false
    if left.cells[idx].colOffset != right.cells[idx].colOffset: return false
    if left.cells[idx].paintIndex != right.cells[idx].paintIndex: return false
  return true

proc makeRotations(base: seq[CellSpec]): seq[ShapeRotation] =
  var current = base
  result = @[]
  for turn in 0 .. 3:
    var minRow = 100
    var minCol = 100
    for cell in current:
      if cell.rowOffset < minRow: minRow = cell.rowOffset
      if cell.colOffset < minCol: minCol = cell.colOffset
    var normalized: ShapeRotation
    normalized.count = current.len
    for idx in 0 .. current.len - 1:
      normalized.cells[idx].rowOffset = current[idx].rowOffset - minRow
      normalized.cells[idx].colOffset = current[idx].colOffset - minCol
      normalized.cells[idx].paintIndex = current[idx].paintIndex
    for idx in 1 .. current.len - 1:
      var held = normalized.cells[idx]
      var prev = idx - 1
      while prev >= 0 and (normalized.cells[prev].rowOffset > held.rowOffset or
          (normalized.cells[prev].rowOffset == held.rowOffset and
           normalized.cells[prev].colOffset > held.colOffset)):
        normalized.cells[prev + 1] = normalized.cells[prev]
        prev -= 1
      normalized.cells[prev + 1] = held
    var duplicate = false
    for existing in result:
      if sameRotation(existing, normalized): duplicate = true
    if not duplicate: result.add normalized
    var rotated: seq[CellSpec] = @[]
    for cell in current:
      var turned = cell
      turned.rowOffset = cell.colOffset
      turned.colOffset = -cell.rowOffset
      rotated.add turned
    current = rotated

proc buildShapeLibrary(): array[5, seq[ShapeRotation]] =
  var single: seq[CellSpec] = @[]
  single.add CellSpec(rowOffset: 0, colOffset: 0, paintIndex: 0)
  var domino: seq[CellSpec] = @[]
  domino.add CellSpec(rowOffset: 0, colOffset: 0, paintIndex: 0)
  domino.add CellSpec(rowOffset: 0, colOffset: 1, paintIndex: 1)
  var straight: seq[CellSpec] = @[]
  straight.add CellSpec(rowOffset: 0, colOffset: 0, paintIndex: 0)
  straight.add CellSpec(rowOffset: 0, colOffset: 1, paintIndex: 1)
  straight.add CellSpec(rowOffset: 0, colOffset: 2, paintIndex: 2)
  var angle: seq[CellSpec] = @[]
  angle.add CellSpec(rowOffset: 0, colOffset: 0, paintIndex: 0)
  angle.add CellSpec(rowOffset: 0, colOffset: 1, paintIndex: 1)
  angle.add CellSpec(rowOffset: 1, colOffset: 1, paintIndex: 2)
  result[1] = makeRotations(single)
  result[2] = makeRotations(domino)
  result[3] = makeRotations(straight)
  result[4] = makeRotations(angle)

const shapeLibrary = buildShapeLibrary()

proc gcdValues(left, right: int): int =
  var first = left
  var second = right
  while second != 0:
    let remainder = first mod second
    first = second
    second = remainder
  return first

var neededColor: array[0..63, int]
var sizeGcd = 1
var placementStart: array[0..63, int]
var placementEnd: array[0..63, int]
var allMask: uint64
var placementBits: seq[uint64] = @[]
var placementCells: seq[array[0..2, int]] = @[]
var placementColors: seq[array[0..2, int]] = @[]
var placementCounts: seq[int] = @[]
var placementCosts: seq[int] = @[]```

`sameRotation` compares sorted cell offsets and paint indexes. `makeRotations` generates four quarter turns and keeps distinct ones. The four flat arrays hold placements without per-cell objects.

**Memo table.** This block caches the best cost for each covered mask.

```nim
var memoKeys: seq[uint64] = @[]
var memoValues: seq[int] = @[]
var memoUsed: seq[bool] = @[]
var memoCapacity = 4096
var memoSize = 0
var memoHits: seq[int] = @[]

proc memoReset() =
  memoKeys.setLen(memoCapacity)
  memoValues.setLen(memoCapacity)
  memoUsed = repeat(false, memoCapacity)
  memoHits.setLen(0)
  memoSize = 0

proc memoIndex(mask: uint64): int =
  let mixed = mask * hashMultiplier
  return int((mixed shr 40) and uint64(memoCapacity - 1))

proc memoInsertKnown(mask: uint64, value: int) =
  var slot = memoIndex(mask)
  while memoUsed[slot]:
    if memoKeys[slot] == mask:
      memoValues[slot] = value
      return
    slot = (slot + 1) and (memoCapacity - 1)
  memoUsed[slot] = true
  memoKeys[slot] = mask
  memoValues[slot] = value
  memoHits.add slot
  memoSize += 1

proc memoGrow() =
  let oldKeys = memoKeys
  let oldValues = memoValues
  let oldUsed = memoUsed
  let oldCapacity = memoCapacity
  memoCapacity = oldCapacity shl 1
  memoKeys.setLen(memoCapacity)
  memoValues.setLen(memoCapacity)
  memoUsed = repeat(false, memoCapacity)
  memoHits.setLen(0)
  memoSize = 0
  for slot in 0 .. oldCapacity - 1:
    if oldUsed[slot]: memoInsertKnown(oldKeys[slot], oldValues[slot])

proc memoGet(mask: uint64, foundValue: var int): bool =
  var slot = memoIndex(mask)
  while memoUsed[slot]:
    if memoKeys[slot] == mask:
      foundValue = memoValues[slot]
      return true
    slot = (slot + 1) and (memoCapacity - 1)
  return false

proc memoPut(mask: uint64, value: int) =
  if memoSize * 10 >= memoCapacity * 7: memoGrow()
  memoInsertKnown(mask, value)

proc memoClear() =
  for slot in memoHits: memoUsed[slot] = false
  memoHits.setLen(0)
  memoSize = 0```

`memoIndex` mixes the mask and takes high bits. Linear probing resolves collisions. `memoClear` resets only slots written this case, and `memoGrow` doubles capacity at 70 percent load.

**Recursive solver.** This block finds the cheapest completion from a covered mask.

```nim
proc solveMask(mask: uint64, remainingCount: int): int =
  if mask == allMask: return 0
  if remainingCount mod sizeGcd != 0: return -1
  var cached = 0
  if memoGet(mask, cached): return cached
  var firstOpen = 0
  while ((mask shr uint(firstOpen)) and 1'u64) == 1'u64:
    firstOpen += 1
  var best = impossibleCost
  var index = placementStart[firstOpen]
  while index < placementEnd[firstOpen]:
    if (mask and placementBits[index]) == 0'u64:
      var fits = true
      for cellIdx in 0 .. placementCounts[index] - 1:
        if neededColor[placementCells[index][cellIdx]] != placementColors[index][cellIdx]:
          fits = false
          break
      if fits:
        let rest = solveMask(mask or placementBits[index], remainingCount - placementCounts[index])
        if rest >= 0 and rest < impossibleCost:
          let total = rest + placementCosts[index]
          if total < best: best = total
    index += 1
  if best >= impossibleCost: best = -1
  memoPut(mask, best)
  return best```

The loop stops at the first open square. A placement must leave all its cells uncovered and match every required color. A remaining count that fails `sizeGcd` returns -1 before any recursion.

**Placement builder.** This block lists legal anchored tiles for every square.

```nim
proc buildPlacements(roomRows, roomCols, tileCount: int, inputData: string, scanPos: var int) =
  var tileForms: seq[int] = @[]
  var tileCosts: seq[int] = @[]
  var tilePaints: seq[array[0..2, int]] = @[]
  sizeGcd = 0
  for tileIdx in 0 .. tileCount - 1:
    tileForms.add nextInt(inputData, scanPos)
    tileCosts.add nextInt(inputData, scanPos)
    var paint: array[0..2, int]
    for cellIdx in 0 .. formCellCount[tileForms[tileIdx]] - 1:
      paint[cellIdx] = nextInt(inputData, scanPos)
    tilePaints.add paint
    sizeGcd = gcdValues(sizeGcd, formCellCount[tileForms[tileIdx]])
  placementBits.setLen(0)
  placementCells.setLen(0)
  placementColors.setLen(0)
  placementCounts.setLen(0)
  placementCosts.setLen(0)
  for pos in 0 .. roomRows * roomCols - 1:
    placementStart[pos] = placementBits.len
    let anchorRow = pos div roomCols
    let anchorCol = pos mod roomCols
    for tileIdx in 0 .. tileCount - 1:
      let form = tileForms[tileIdx]
      let cost = tileCosts[tileIdx]
      let paint = tilePaints[tileIdx]
      for rotation in shapeLibrary[form]:
        let anchor = rotation.cells[0]
        var bits = 0'u64
        var cellIndexes: array[0..2, int]
        var cellColors: array[0..2, int]
        var valid = true
        for cellIdx in 0 .. rotation.count - 1:
          let absRow = anchorRow + rotation.cells[cellIdx].rowOffset - anchor.rowOffset
          let absCol = anchorCol + rotation.cells[cellIdx].colOffset - anchor.colOffset
          if absRow < 0 or absRow >= roomRows or absCol < 0 or absCol >= roomCols:
            valid = false
            break
          let absIndex = absRow * roomCols + absCol
          cellIndexes[cellIdx] = absIndex
          cellColors[cellIdx] = paint[rotation.cells[cellIdx].paintIndex]
          bits = bits or (1'u64 shl absIndex)
        if valid:
          placementBits.add bits
          placementCells.add cellIndexes
          placementColors.add cellColors
          placementCounts.add rotation.count
          placementCosts.add cost
    placementEnd[pos] = placementBits.len```

`anchor` is the tile cell with the smallest row and column offset. That cell must land on the first open square. Bounds checks discard placements that cross a wall.

**Driver.** This block reads input, runs each case, and writes answers in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
memoReset()

for caseIdx in 0 .. caseCount - 1:
  let roomRows = nextInt(inputData, scanPos)
  let roomCols = nextInt(inputData, scanPos)
  let tileCount = nextInt(inputData, scanPos)
  let cellTotal = roomRows * roomCols
  if cellTotal == 64: allMask = not 0'u64
  else: allMask = (1'u64 shl cellTotal) - 1'u64
  var covered = 0'u64
  var needCount = 0
  for cellIdx in 0 .. cellTotal - 1:
    let value = nextInt(inputData, scanPos)
    neededColor[cellIdx] = value
    if value == 2: covered = covered or (1'u64 shl cellIdx)
    else: needCount += 1
  buildPlacements(roomRows, roomCols, tileCount, inputData, scanPos)
  memoClear()
  let answer = solveMask(covered, needCount)
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0```

The mask of a full 64-square room uses `not 0'u64`, since shifting by 64 wraps. Each answer goes into one output buffer, flushed every 128 KiB.

## Complexity

The work splits into shape setup, placement building, and memoized search.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one digit pass | input bytes |
| Shape setup | four turns per form, once | 14 rotations |
| Placement build | at most 40 placements per square | at most 2560 placements |
| Memoized search | one pass per reachable mask | one entry per mask |
| Output | one write per 128 KiB block | 128 KiB |

The search dominates, and both placement building and output stay small.

| Measure | Big O |
|---|---|
| Time | O(S x P), where S is reachable masks and P is placements per state |
| Space | O(S + N x M) |

Trying every subset of 64 squares costs O(2^64) time, while memoization pays once per reachable mask.
