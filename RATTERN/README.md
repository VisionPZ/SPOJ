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

Fill the first empty square first, like solving a crossword left to right. The algorithm is recursive exact cover with memoization. A 64-bit mask records covered squares. Each call tries every rotation of every tile type anchored at the first open square. A state costs at most 40 placements, since ten types have at most four rotations each. A fixed hash table caches each reachable mask with a case stamp, so old entries never return. Testing every subset would cost 2^64 checks, while memoization pays once per reachable mask. A gcd check drops remaining counts that no tile size can sum to.

Pack the board into one word, fill the first gap, and cache every state.

## Why It Works

1. A quarter turn keeps the cell count and the numbered colors of a tile. The shape library stores only distinct rotations.
2. The first open square must belong to the next tile, since earlier squares are covered. Anchoring the tile's first cell there loses no tiling.
3. One bitwise test rejects overlapping placements. Squares marked 2 start with their bits set.
4. A mask always has the same cheapest completion, so the cache returns it at once.
5. Each cache slot stores the stamp of its case, so a new case ignores old entries.
6. If all tile sizes share a divisor, the remaining count must also be a multiple.

The main terms and formulas:

| Term | Meaning |
|---|---|
| `allMask` | bits for every square in the room |
| `firstOpen` | index of the lowest uncovered square |
| `sizeGcd` | greatest common divisor of available tile sizes |
| `memoStamp` | number of the current case in the cache |

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

**Constants and token reader.** This block sets bounds and parses integers from one buffer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const impossibleCost = 1 shl 28
const maxCellCount = 64
const maxRoomSide = 8
const maxTileCount = 1000
const memoSlotCount = 1 shl 19
const memoSlotMask = memoSlotCount - 1
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
  var negative = false
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var magnitude: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    magnitude = magnitude * 10 + int64(int(data[pos]) - firstDigitValue)
    if magnitude > 2000000000: magnitude = 2000000000
    pos += 1
  if negative: return -int(magnitude)
  return int(magnitude)```

`firstDigitValue` turns a digit byte into its value. `flushBlockBytes` caps the output buffer at 128 KiB. The scanner reads a sign and builds each integer digit by digit. Values are capped before conversion, so a long token cannot overflow.

**Rotation library and per-case state.** This block builds shapes at run time and defines the reused arrays.

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

var shapeLibrary: array[5, seq[ShapeRotation]]

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

`shapeLibrary` is filled after input read, so no compile-time sequence constant is needed. `sameRotation` compares sorted cell offsets and paint indexes. The flat arrays hold placements without per-cell objects.

**Stamped cache.** This block caches the best cost for each covered mask.

```nim
var memoKeys: seq[uint64] = @[]
var memoValues: seq[int] = @[]
var memoStamps: seq[uint32] = @[]
var memoStamp = 1'u32
var memoSize = 0

proc memoInit() =
  memoKeys.setLen(memoSlotCount)
  memoValues.setLen(memoSlotCount)
  memoStamps.setLen(memoSlotCount)
  memoStamp = 1'u32
  memoSize = 0

proc memoNextCase() =
  memoStamp += 1'u32
  if memoStamp == 0'u32:
    for slot in 0 .. memoSlotCount - 1: memoStamps[slot] = 0'u32
    memoStamp = 1'u32
  memoSize = 0

proc memoIndex(mask: uint64): int =
  let mixed = mask * hashMultiplier
  return int((mixed shr 40) and uint64(memoSlotMask))

proc memoGet(mask: uint64, foundValue: var int): bool =
  var slot = memoIndex(mask)
  var probes = 0
  while memoStamps[slot] == memoStamp:
    if memoKeys[slot] == mask:
      foundValue = memoValues[slot]
      return true
    slot = (slot + 1) and memoSlotMask
    probes += 1
    if probes >= memoSlotCount: return false
  return false

proc memoPut(mask: uint64, value: int) =
  if memoSize * 10 >= memoSlotCount * 7: return
  var slot = memoIndex(mask)
  var probes = 0
  while memoStamps[slot] == memoStamp:
    if memoKeys[slot] == mask:
      memoValues[slot] = value
      return
    slot = (slot + 1) and memoSlotMask
    probes += 1
    if probes >= memoSlotCount: return
  memoStamps[slot] = memoStamp
  memoKeys[slot] = mask
  memoValues[slot] = value
  memoSize += 1```

`memoInit` allocates the table once. `memoNextCase` advances the stamp, so old entries need no clearing. Probing stops after one full sweep, so a full table cannot hang.

**Recursive solver.** This block finds the cheapest completion from a covered mask.

```nim
proc solveMask(mask: uint64, remainingCount: int): int =
  if mask == allMask: return 0
  if sizeGcd > 0 and remainingCount mod sizeGcd != 0: return -1
  var cached = 0
  if memoGet(mask, cached): return cached
  var firstOpen = 0
  while firstOpen < maxCellCount and ((mask shr uint(firstOpen)) and 1'u64) == 1'u64:
    firstOpen += 1
  if firstOpen >= maxCellCount: return -1
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

The loop stops at the first open square. A placement must leave all its cells uncovered and match every required color. The `sizeGcd` check runs only when a tile size exists, so an empty tile list never divides by zero.

**Placement builder.** This block lists legal anchored tiles for every square.

```nim
proc buildPlacements(roomRows, roomCols, tileCount: int, inputData: string, scanPos: var int) =
  var tileForms: seq[int] = @[]
  var tileCosts: seq[int] = @[]
  var tilePaints: seq[array[0..2, int]] = @[]
  sizeGcd = 0
  for tileIdx in 0 .. tileCount - 1:
    let rawForm = nextInt(inputData, scanPos)
    let safeForm = if rawForm >= 1 and rawForm <= 4: rawForm else: 0
    tileForms.add safeForm
    tileCosts.add nextInt(inputData, scanPos)
    var paint: array[0..2, int]
    for cellIdx in 0 .. formCellCount[safeForm] - 1:
      paint[cellIdx] = nextInt(inputData, scanPos)
    if safeForm == 0:
      for cellIdx in 0 .. 2: paint[cellIdx] = nextInt(inputData, scanPos)
    tilePaints.add paint
    sizeGcd = gcdValues(sizeGcd, formCellCount[safeForm])
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
          if absIndex >= maxCellCount:
            valid = false
            break
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

`safeForm` keeps a form inside the four known shapes, so table lookups stay in range. `anchor` is the tile cell with the smallest row and column offset. Bounds checks discard placements that cross a wall or a 64-bit index.

**Driver.** This block reads input, runs each case, and writes answers in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var caseCount = nextInt(inputData, scanPos)
if caseCount < 0: caseCount = 0
if caseCount > 2000000: caseCount = 2000000
var outputBuffer = ""
memoInit()
shapeLibrary = buildShapeLibrary()

for caseIdx in 0 .. caseCount - 1:
  var roomRows = nextInt(inputData, scanPos)
  var roomCols = nextInt(inputData, scanPos)
  var tileCount = nextInt(inputData, scanPos)
  if roomRows < 0: roomRows = 0
  if roomCols < 0: roomCols = 0
  if roomRows > maxRoomSide: roomRows = maxRoomSide
  if roomCols > maxRoomSide: roomCols = maxRoomSide
  if tileCount < 0: tileCount = 0
  if tileCount > maxTileCount: tileCount = maxTileCount
  let cellTotal = roomRows * roomCols
  if cellTotal <= 0: allMask = 0'u64
  elif cellTotal >= maxCellCount: allMask = not 0'u64
  else: allMask = (1'u64 shl cellTotal) - 1'u64
  var covered = 0'u64
  var needCount = 0
  for cellIdx in 0 .. cellTotal - 1:
    let value = nextInt(inputData, scanPos)
    if cellIdx < maxCellCount:
      neededColor[cellIdx] = value
      if value == 2: covered = covered or (1'u64 shl cellIdx)
      else: needCount += 1
  buildPlacements(roomRows, roomCols, tileCount, inputData, scanPos)
  memoNextCase()
  let answer = solveMask(covered, needCount)
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0```

Room sides, tile counts, and the case count are capped before indexing. `allMask` uses `not 0'u64` for a full room, since shifting by 64 wraps. Each answer goes into one output buffer, flushed every 128 KiB.

## Complexity

The work splits into shape setup, placement building, and cached search.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one digit pass | input bytes |
| Shape setup | four turns per form, once | 14 rotations |
| Placement build | at most 40 placements per square | at most 2560 placements |
| Cached search | one pass per reachable mask | one fixed table |
| Output | one write per 128 KiB block | 128 KiB |

The search dominates, and both placement building and output stay small.

| Measure | Big O |
|---|---|
| Time | O(S x P), where S is reachable masks and P is placements per state |
| Space | O(S + N x M) |

Trying every subset of 64 squares costs O(2^64) time, while caching pays once per reachable mask.
