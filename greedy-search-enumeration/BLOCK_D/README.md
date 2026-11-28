# BLOCK_D — BLOCK_D SOLVER (SPOJ)

<https://www.spoj.com/problems/BLOCK_D/>

## Problem

Blocks of five colors fill a grid. Choosing a block destroys its whole same-color edge-connected group, then blocks fall and empty columns disappear. Report the fewest moves that remove every block, or -1 when that is impossible.

| item | bound |
|---|---|
| test cases | 1 to 10 |
| rows and columns | 1 to 8 each |
| colors | `a` through `e` |
| judge limit | 10000 ms, 1536 MB |

Input starts with the test count. Each case gives the dimensions, then one row string per row. Output is one integer per case.

Sample input:

```
2
5 5
aaaba
aaaba
aaaba
aaaba
aaaba
5 5
bbbbb
baabb
bbbab
bbbaa
aabab
```

Sample output:

```
2
3
```

## Idea

Treat every settled board as a room in a maze and use breadth-first search, like finding the shortest route out of a building. Each move destroys one connected group, so the first time the empty board appears gives the minimum move count. A hash set of seen boards prevents revisiting rooms reached by other move orders.

A greedy choice can strand single blocks forever. Exhaustive search over settled boards settles the answer exactly.

## Why It Works

1. Only groups of at least two edge-connected blocks of one color can be destroyed.
2. After destruction, each column keeps its remaining blocks packed at the bottom.
3. A column with no blocks is removed, which shortens every row.
4. Each search edge applies one move plus its forced gravity and column removal.
5. Breadth-first search explores boards in nondecreasing move count.
6. The first empty board therefore carries the minimum number of moves.
7. Exhausting the queue without an empty board proves -1.

| term | meaning |
|---|---|
| `BoardState` | settled board cells plus current column count |
| `componentColor` | color of the group being destroyed |
| `applyGravity` | packs each column toward the bottom |
| `compactColumns` | removes empty columns after gravity |

The table defines each part of a board transition.

A trace from the generator for the first sample case uses a different breadth-first implementation. Five columns hold four `a` columns and one `b` column.

```
move 1: destroy the connected a group; four columns empty and vanish
settled board: five rows of b, one column left
move 2: destroy the connected b group; the board is empty
result 2, matching the sample
```

The oracle prints 2 for this board.

## Code

**Search setup.** Global dimensions guide the transition helpers.

```nim
import sets

const flushBlockBytes = 1 shl 17

type
  BoardState = tuple[cells: string, width: int]

var rowCount = 0
var columnCount = 0

proc stateKey(cells: string, width: int): string =
  return cells & "/" & $width
```

The state carries its own width.
The key separates width from cells.
Sets are initialised through `init()`.

**Gravity and compaction.** These helpers create the settled board after a move.

```nim
proc applyGravity(grid: var seq[char], width: int) =
  for columnIndex in 0 .. width - 1:
    var writeRow = rowCount - 1
    for rowIndex in countdown(rowCount - 1, 0):
      let cellIndex = rowIndex * width + columnIndex
      if grid[cellIndex] != '.':
        if writeRow != rowIndex:
          grid[writeRow * width + columnIndex] = grid[cellIndex]
          grid[cellIndex] = '.'
        writeRow -= 1

proc compactColumns(grid: var seq[char], width: var int) =
  var keptColumns = newSeq[int]()
  for columnIndex in 0 .. width - 1:
    var holdsBlock = false
    for rowIndex in 0 .. rowCount - 1:
      if grid[rowIndex * width + columnIndex] != '.':
        holdsBlock = true
    if holdsBlock:
      keptColumns.add columnIndex
  if keptColumns.len == width:
    return
  var compacted = ""
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in keptColumns:
      compacted.add grid[rowIndex * width + columnIndex]
  grid.setLen rowCount * keptColumns.len
  for cellIndex in 0 .. compacted.len - 1:
    grid[cellIndex] = compacted[cellIndex]
  width = keptColumns.len
```

Gravity scans each column from the bottom up.
Empty columns are dropped in their original order.
Both helpers run before a board enters the queue.

**Input and output.** The hand reader loads the board lines verbatim.

```nim
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

proc nextBoardLine(data: string, pos: var int, width: int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var lineText = ""
  while pos < data.len and data[pos] > ' ' and lineText.len < width:
    lineText.add data[pos]
    pos += 1
  return lineText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The board reader stops after the stated width.
Colors need no integer conversion.
The buffer flushes after 128 KiB.

**Breadth-first search.** Each popped board expands one move per destroyable group.

```nim
proc solveCase(initialCells: string): int =
  var visited: HashSet[string]
  visited.init()
  var queue = newSeq[BoardState]()
  var depths = newSeq[int]()
  queue.add((initialCells, columnCount))
  depths.add 0
  visited.incl stateKey(initialCells, columnCount)
  var headIndex = 0
  while headIndex < queue.len:
    let currentState = queue[headIndex]
    let currentDepth = depths[headIndex]
    headIndex += 1
    let width = currentState.width
    var grid = newSeq[char](currentState.cells.len)
    for cellIndex in 0 .. currentState.cells.len - 1:
      grid[cellIndex] = currentState.cells[cellIndex]
    var componentSeen = newSeq[bool](grid.len)
    for startIndex in 0 .. grid.len - 1:
      if grid[startIndex] == '.' or componentSeen[startIndex]:
        continue
      let componentColor = grid[startIndex]
      var stack = newSeq[int]()
      var members = newSeq[int]()
      stack.add startIndex
      componentSeen[startIndex] = true
      while stack.len > 0:
        let cellIndex = stack[stack.len - 1]
        stack.setLen stack.len - 1
        members.add cellIndex
        let rowIndex = cellIndex div width
        let columnIndex = cellIndex mod width
        if rowIndex > 0:
          let neighbor = cellIndex - width
          if grid[neighbor] == componentColor and not componentSeen[neighbor]:
            componentSeen[neighbor] = true
            stack.add neighbor
        if rowIndex < rowCount - 1:
          let neighbor = cellIndex + width
          if grid[neighbor] == componentColor and not componentSeen[neighbor]:
            componentSeen[neighbor] = true
            stack.add neighbor
        if columnIndex > 0:
          let neighbor = cellIndex - 1
          if grid[neighbor] == componentColor and not componentSeen[neighbor]:
            componentSeen[neighbor] = true
            stack.add neighbor
        if columnIndex < width - 1:
          let neighbor = cellIndex + 1
          if grid[neighbor] == componentColor and not componentSeen[neighbor]:
            componentSeen[neighbor] = true
            stack.add neighbor
      if members.len < 2:
        continue
```

Flood fill finds one connected group at a time.
Singleton groups never produce a move.
Each cell is classified once per board.

```nim
      var nextGrid = newSeq[char](grid.len)
      for cellIndex in 0 .. grid.len - 1:
        nextGrid[cellIndex] = grid[cellIndex]
      for cellIndex in members:
        nextGrid[cellIndex] = '.'
      var nextWidth = width
      applyGravity(nextGrid, nextWidth)
      compactColumns(nextGrid, nextWidth)
      var nextCells = ""
      for cell in nextGrid:
        nextCells.add cell
      var cleared = true
      for cell in nextGrid:
        if cell != '.':
          cleared = false
      if cleared:
        return currentDepth + 1
      let nextKey = stateKey(nextCells, nextWidth)
      if not (nextKey in visited):
        visited.incl nextKey
        queue.add((nextCells, nextWidth))
        depths.add currentDepth + 1
  return -1
```

The settled board becomes a new queue entry.
The first cleared board returns the current depth plus one.
An exhausted queue returns -1.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  rowCount = nextInt(inputData, scanPos)
  columnCount = nextInt(inputData, scanPos)
  var initialCells = ""
  for rowIndex in 0 .. rowCount - 1:
    initialCells.add nextBoardLine(inputData, scanPos, columnCount)
  let answer = solveCase(initialCells)
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case starts with an empty visitation set.
Dimensions are global for the duration of one case.
One flush writes every answer.

## Complexity

The search expands each reachable settled board once, with up to five color groups per board.

| phase | time | space |
|---|---|---|
| input read | one pass over board rows | one input string |
| flood fill | one visit per cell | one flag per cell |
| transitions | one gravity pass per group | one grid copy |
| visited set | one hash insert per board | one key per board |

The table shows that the number of reachable boards drives the cost.

| measure | Big O |
|---|---|
| time | O(S * cells), S reachable boards |
| space | O(S * cells) for visited keys |

A greedy choice can wander through dead ends, while breadth-first search returns the first shortest route.
