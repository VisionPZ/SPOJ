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
  return value

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
var placementCosts: seq[int] = @[]

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
  memoSize = 0

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
  return best

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
    placementEnd[pos] = placementBits.len

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
outputBuffer.setLen 0
