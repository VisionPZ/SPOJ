# WARE — The Warehouse (SPOJ)

<https://www.spoj.com/problems/WARE/>

## Problem

An agent stands on a box in an n by n warehouse and must reach the box below the exit. Each move to an adjacent box costs one step, and toppling the box under the agent also costs one step. Find the fewest steps, or report impossibility.

A box of height 2, 3 or 4 occupies one cell. When it topples in a direction, it lies across that many consecutive cells in that direction. Those cells must all be empty, the old cell becomes empty, and the agent lands one step ahead on the fallen box. A fallen box cannot topple again, and no box may topple onto the exit cell.

Each block starts with n and the 1-based start row and column. The next n lines contain n characters each: '.' for empty, '2', '3' or '4' for box heights, and 'E' for the exit. A block with n = 0 ends the input. Print one line per block with the step count or `Impossible.`. Here `Impossible.` is an exact output string defined by this contract.

The bounds size the board:

| item | bound |
|---|---|
| board side n | 1 to 8 |
| box height | 2, 3 or 4 meters |
| start row and column | 1 to n |
| judge limit | 1000 ms, 1536 MB |

At most 64 cells fit in one board, so whole configurations are small enough to store.

Sample input:

```
5 5 3
.2..E
...2.
4....
....4
..2..
0 0 0
```

Sample output:

```
18
```

## Idea

Treat each whole warehouse layout as one square on a giant floor plan. Breadth-first search walks from layout to layout, like finding the shortest route through a maze. Its walls change behind you. The first appearance of the exit is the shortest escape.

Pack each cell into four bits. Codes 0 through 5 mark empty, fallen, heights 2, 3, 4 and the exit. Adding 6 marks the cell under the agent, so one state holds both the board and the agent position in four 64-bit words.

From each state, generate four walks onto occupied neighbors and four topples when the standing box has a clear run. An open-addressed hash set rejects repeated layouts. Each generated edge costs one step, so breadth-first search returns the minimum.

## Why It Works

1. Four bits hold every cell code, and 16 cells fit in one 64-bit word, so four words hold the largest 8 by 8 board.
2. The marker offset of 6 records the agent inside a cell code without a separate position array in the hash key.
3. Walking onto a neighbor requires an occupied cell; height differences do not block a walk.
4. Toppling requires height consecutive empty cells in one of the four directions, and the exit is never empty.
5. After a topple, the old cell becomes empty and the covered cells become fallen boxes, which can be walked on but never toppled again.
6. Breadth-first search expands states in nondecreasing step count, so the first exit state gives the minimum.
7. `seenUsed` stores every visited layout once, which stops cycles caused by walking back and forth.

Terms and formulas:

| term | meaning |
|---|---|
| `cellCode` | four-bit content of one cell, including the agent marker |
| `underlyingCode` | cell content with the agent marker removed |
| `queueCells` | packed layouts waiting in the breadth-first queue |
| `seenWords` | hash table storing previously visited layouts |
| `answerSteps` | step count of the first exit state found |

The packed state keeps both queue and hash table small.

The sample trace from gen.py:

```
sample answer 18
comment answer 27
single cell 0
no moves Impossible.
```

The statement sample needs 18 steps and the eight-by-eight example needs 27. A start already on the exit needs 0. A lone box cannot escape.

## Code

**Packing and cell access.** Constants define the code alphabet and four-bit cells.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const cellsPerWord = 16
const bitsPerCell = 4
const cellMask = 15'u64
const markerOffset = 6
const emptyCell = 0
const fallenCell = 1
const exitCell = 5
const directionRows = [1, -1, 0, 0]
const directionColumns = [0, 0, 1, -1]

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextCellChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let foundChar = data[pos]
  pos += 1
  return foundChar

proc mixWord(wordValue: uint64): uint64 =
  var mixed = wordValue
  mixed = mixed xor (mixed shr 30)
  mixed = mixed * 0xbf58476d1ce4e5b9'u64
  mixed = mixed xor (mixed shr 27)
  mixed = mixed * 0x94d049bb133111eb'u64
  mixed = mixed xor (mixed shr 31)
  return mixed

proc cellCode(cells: array[4, uint64], index: int): int =
  let wordIndex = index div cellsPerWord
  let shiftAmount = (index mod cellsPerWord) * bitsPerCell
  return int((cells[wordIndex] shr uint(shiftAmount)) and cellMask)

proc setCellCode(cells: var array[4, uint64], index: int, code: int) =
  let wordIndex = index div cellsPerWord
  let shiftAmount = uint((index mod cellsPerWord) * bitsPerCell)
  let cleared = cells[wordIndex] and not (cellMask shl shiftAmount)
  cells[wordIndex] = cleared or (uint64(code) shl shiftAmount)

proc underlyingCode(code: int): int =
  if code > exitCell: return code - markerOffset
  return code
```

Board characters read one at a time because their count comes from n.
Shifting by four bits per cell keeps word boundaries aligned.
Removing the marker gives the box height before a topple.

**Visited set.** The hash table stores whole layouts with open addressing.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let boardSize = nextInt(inputData, scanPos)
  let startRow = nextInt(inputData, scanPos) - 1
  let startColumn = nextInt(inputData, scanPos) - 1
  if boardSize == 0 and startRow == -1 and startColumn == -1:
    break
  var startCells: array[4, uint64]
  for cellIndex in 0 .. boardSize * boardSize - 1:
    let cellChar = nextCellChar(inputData, scanPos)
    var code = emptyCell
    case cellChar
    of '2': code = 2
    of '3': code = 3
    of '4': code = 4
    of 'E': code = exitCell
    else: code = emptyCell
    setCellCode(startCells, cellIndex, code)
  var startPosition = startRow * boardSize + startColumn
  let standingCode = cellCode(startCells, startPosition)
  if standingCode != emptyCell:
    setCellCode(startCells, startPosition, standingCode + markerOffset)
  var tableCapacity = 1 shl 14
  var seenWords = newSeq[uint64](tableCapacity * 4)
  var seenUsed = newSeq[bool](tableCapacity)
  var usedCount = 0

  proc findSlot(cells: array[4, uint64]): int =
    var hashValue = mixWord(cells[0])
    for wordIndex in 1 .. 3:
      hashValue = hashValue xor mixWord(cells[wordIndex] + hashValue)
    var slotIndex = int(hashValue and uint64(tableCapacity - 1))
    while seenUsed[slotIndex]:
      var matches = true
      for wordIndex in 0 .. 3:
        if seenWords[slotIndex * 4 + wordIndex] != cells[wordIndex]:
          matches = false
          break
      if matches:
        return slotIndex
      slotIndex = (slotIndex + 1) and (tableCapacity - 1)
    return slotIndex

  proc markVisited(cells: array[4, uint64]): bool =
    let slotIndex = findSlot(cells)
    if seenUsed[slotIndex]:
      return false
    seenUsed[slotIndex] = true
    for wordIndex in 0 .. 3:
      seenWords[slotIndex * 4 + wordIndex] = cells[wordIndex]
    usedCount += 1
    return true

  proc ensureCapacity() =
    if usedCount * 4 < tableCapacity * 3:
      return
    let oldCapacity = tableCapacity
    tableCapacity = tableCapacity shl 1
    var resizedWords = newSeq[uint64](tableCapacity * 4)
    var resizedUsed = newSeq[bool](tableCapacity)
    for oldSlot in 0 .. oldCapacity - 1:
      if seenUsed[oldSlot]:
        var hashValue = mixWord(seenWords[oldSlot * 4])
        for wordIndex in 1 .. 3:
          hashValue = hashValue xor mixWord(seenWords[oldSlot * 4 + wordIndex] + hashValue)
        var newSlot = int(hashValue and uint64(tableCapacity - 1))
        while resizedUsed[newSlot]:
          newSlot = (newSlot + 1) and (tableCapacity - 1)
        resizedUsed[newSlot] = true
        for wordIndex in 0 .. 3:
          resizedWords[newSlot * 4 + wordIndex] = seenWords[oldSlot * 4 + wordIndex]
    seenWords = resizedWords
    seenUsed = resizedUsed
```

The start cell receives the agent marker when it holds a box.
Capacity grows by powers of two and every stored layout is rehashed.
The boolean array distinguishes an empty slot from an all-zero layout.

**Walk transitions.** Four neighbors produce new layouts in one step each.

```nim
  discard markVisited(startCells)
  var queueCells = newSeq[uint64](4 * 65536)
  var queuePositions = newSeq[int](65536)
  var queueDepths = newSeq[int](65536)
  var queueHead = 0
  var queueTail = 0
  for wordIndex in 0 .. 3:
    queueCells[queueTail * 4 + wordIndex] = startCells[wordIndex]
  queuePositions[queueTail] = startPosition
  queueDepths[queueTail] = 0
  queueTail += 1
  var answerSteps = -1
  while queueHead < queueTail and answerSteps == -1:
    var currentCells: array[4, uint64]
    for wordIndex in 0 .. 3:
      currentCells[wordIndex] = queueCells[queueHead * 4 + wordIndex]
    let currentPosition = queuePositions[queueHead]
    let currentDepth = queueDepths[queueHead]
    queueHead += 1
    if underlyingCode(cellCode(currentCells, currentPosition)) == exitCell:
      answerSteps = currentDepth
      break
    let currentRow = currentPosition div boardSize
    let currentColumn = currentPosition mod boardSize
    for directionIndex in 0 .. 3:
      let neighborRow = currentRow + directionRows[directionIndex]
      let neighborColumn = currentColumn + directionColumns[directionIndex]
      if neighborRow < 0 or neighborRow >= boardSize:
        continue
      if neighborColumn < 0 or neighborColumn >= boardSize:
        continue
      let neighborIndex = neighborRow * boardSize + neighborColumn
      let neighborCode = cellCode(currentCells, neighborIndex)
      if neighborCode == emptyCell:
        continue
      let neighborBase = underlyingCode(neighborCode)
      var nextCells = currentCells
      setCellCode(nextCells, currentPosition,
        underlyingCode(cellCode(currentCells, currentPosition)))
      setCellCode(nextCells, neighborIndex, neighborBase + markerOffset)
      if neighborBase == exitCell:
        answerSteps = currentDepth + 1
        break
      ensureCapacity()
      if markVisited(nextCells):
        if queueTail >= queuePositions.len:
          queueCells.setLen(queueCells.len * 2)
          queuePositions.setLen(queuePositions.len * 2)
          queueDepths.setLen(queueDepths.len * 2)
        for wordIndex in 0 .. 3:
          queueCells[queueTail * 4 + wordIndex] = nextCells[wordIndex]
        queuePositions[queueTail] = neighborIndex
        queueDepths[queueTail] = currentDepth + 1
        queueTail += 1
    if answerSteps != -1:
      break
```

The queue stores layouts, positions and depths in three flat arrays.
Walking onto the exit ends the search at the next depth.
New states enter the queue only after passing the visited check.

**Topple transitions.** A clear run creates fallen boxes and moves the marker one cell.

```nim
    let standingHeight = underlyingCode(cellCode(currentCells, currentPosition))
    if standingHeight < 2 or standingHeight > 4:
      continue
    for directionIndex in 0 .. 3:
      let stepRow = directionRows[directionIndex]
      let stepColumn = directionColumns[directionIndex]
      var clearPath = true
      for step in 1 .. standingHeight:
        let targetRow = currentRow + stepRow * step
        let targetColumn = currentColumn + stepColumn * step
        if targetRow < 0 or targetRow >= boardSize or targetColumn < 0 or targetColumn >= boardSize:
          clearPath = false
          break
        let targetIndex = targetRow * boardSize + targetColumn
        if cellCode(currentCells, targetIndex) != emptyCell:
          clearPath = false
          break
      if not clearPath:
        continue
      var nextCells = currentCells
      setCellCode(nextCells, currentPosition, emptyCell)
      let landingIndex = (currentRow + stepRow) * boardSize + currentColumn + stepColumn
      for step in 1 .. standingHeight:
        let targetIndex = (currentRow + stepRow * step) * boardSize + currentColumn + stepColumn * step
        setCellCode(nextCells, targetIndex, fallenCell)
      setCellCode(nextCells, landingIndex, fallenCell + markerOffset)
      ensureCapacity()
      if markVisited(nextCells):
        if queueTail >= queuePositions.len:
          queueCells.setLen(queueCells.len * 2)
          queuePositions.setLen(queuePositions.len * 2)
          queueDepths.setLen(queueDepths.len * 2)
        for wordIndex in 0 .. 3:
          queueCells[queueTail * 4 + wordIndex] = nextCells[wordIndex]
        queuePositions[queueTail] = landingIndex
        queueDepths[queueTail] = currentDepth + 1
        queueTail += 1
  if answerSteps == -1:
    appendOutput("Impossible.")
  else:
    appendOutput($answerSteps)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The clear-path loop rejects runs that leave the board or hit any box.
Fallen cells carry code 1, so they cannot topple later.
An exhausted queue with no exit state proves escape is impossible.

## Complexity

Each visited layout is expanded once, with eight successor trials.

| phase | time | space |
|---|---|---|
| input read | one pass over n squared cells | one input string |
| state expansion | up to eight successors per layout | three queue arrays |
| visited check | one hash probe plus probing | four-word slots |
| output | one line per block | block buffer |

The hash table grows with the number of distinct layouts reached.

| measure | Big O |
|---|---|
| time | O(S) per block, where S is the number of reachable layouts |
| space | O(S) |

Searching paths without memoizing layouts revisits the same board many times, while the visited set expands each layout once.
The 64-cell bound keeps each state at four machine words.
