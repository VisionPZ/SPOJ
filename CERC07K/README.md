# CERC07K — Key Task (SPOJ)

<https://www.spoj.com/problems/CERC07K/>

## Problem

Find the fewest grid steps from the start marker to any exit in a maze with colored keys and doors. A door opens only after its matching key has been stepped on; picking up a key and opening a door cost no steps.

Each scenario gives two integers `R` and `C`, then `R` rows of `C` characters. Walls are `#`, free cells are `.`, the start is `*`, exits are `X`, keys are lowercase `b y r g`, and doors are uppercase `B Y R G`. A blank line follows each map, and `0 0` ends the input. Print either `Escape possible in S steps.` or `The poor student is trapped!`.

| item | bound |
|---|---|
| rows and columns | 1 to 100 each |
| key colors | 4 |
| start markers per map | exactly 1 |
| judge limit | 1000 ms, 1536 MB |

The key collection changes the state, so position alone cannot describe a search node.

Sample input:

```
1 10
*........X

1 3
*#X

3 20
####################
#XY.gBr.*.Rb.G.GG.y#
####################

0 0
```

Sample output:

```
Escape possible in 9 steps.
The poor student is trapped!
Escape possible in 45 steps.
```

## Idea

Carry the set of collected keys with the position, like a traveler holding a ring of keys while walking a floor plan. Breadth-first search explores states in step order, so the first exit reached has the fewest steps. Each cell has sixteen key sets, so the state space stays small. A plain position-only search would miss routes that need a detour for a key. Take away the key set and the maze becomes a different, wrong problem.

## Why It Works

1. A state is a cell plus the set of keys held there.
2. Every move costs exactly one step, so breadth-first order gives shortest paths.
3. A door transition is allowed only when the matching key bit is set.
4. Stepping on a key sets one bit and leaves the step count unchanged.
5. Revisiting a state with the same or more keys cannot improve any later route.

| term | meaning |
|---|---|
| `keyMasks` | key bits found in each cell |
| `doorMasks` | key bits required by each cell |
| `currentKeys` | keys held in the current state |
| `distances` | step count for every state, `-1` when unseen |
| `startState` | start cell with no keys |

The transition rule keeps the search inside legal moves at all times.

Walking `*bBy.X` gives:

```
start   cell 0   keys -      steps 0
step 1  cell b   keys b      steps 1
step 2  door B   keys b      steps 2
step 3  cell y   keys b+y    steps 3
step 4  cell .   keys b+y    steps 4
step 5  exit X   keys b+y    steps 5
```

The trace shows why the blue door opens after the blue key: the answer is five steps.

## Code

**Input and parsing.** The reader converts each map into per-cell masks.

```nim
const flushBlockBytes = 1 shl 17
const keyCount = 16

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

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let cell = data[pos]
  pos += 1
  return cell

proc keyBit(cell: char): int =
  if cell == 'b' or cell == 'B':
    return 1
  if cell == 'y' or cell == 'Y':
    return 2
  if cell == 'r' or cell == 'R':
    return 4
  if cell == 'g' or cell == 'G':
    return 8
  return 0
```

The cell reader skips blank lines between maps automatically.
Uppercase and lowercase forms of a color share one bit.
The exit letter never produces a door bit.

**Search and output.** Breadth-first search stops at the first exit state.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  let cellCount = rowCount * columnCount
  var isWall = newSeq[bool](cellCount)
  var keyMasks = newSeq[int](cellCount)
  var doorMasks = newSeq[int](cellCount)
  var isExit = newSeq[bool](cellCount)
  var startCell = 0
  for cellIndex in 0 .. cellCount - 1:
    let cell = nextCell(inputData, scanPos)
    isWall[cellIndex] = cell == '#'
    if cell >= 'a' and cell <= 'z':
      keyMasks[cellIndex] = keyBit(cell)
    if (cell >= 'A' and cell <= 'Z') and cell != 'X':
      doorMasks[cellIndex] = keyBit(cell)
    isExit[cellIndex] = cell == 'X'
    if cell == '*':
      startCell = cellIndex
  let stateCount = cellCount * keyCount
  var distances = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    distances[stateIndex] = -1
  var queue = newSeq[int](stateCount)
  var queueHead = 0
  var queueTail = 0
  let startState = startCell * keyCount
  distances[startState] = 0
  queue[queueTail] = startState
  queueTail += 1
  var escapeSteps = -1
  while queueHead < queueTail and escapeSteps == -1:
    let currentState = queue[queueHead]
    queueHead += 1
    let currentCell = currentState div keyCount
    let currentKeys = currentState mod keyCount
    let currentRow = currentCell div columnCount
    let currentColumn = currentCell mod columnCount
    for direction in 0 .. 3:
      var nextRow = currentRow
      var nextColumn = currentColumn
      if direction == 0:
        nextRow -= 1
      elif direction == 1:
        nextRow += 1
      elif direction == 2:
        nextColumn -= 1
      else:
        nextColumn += 1
      if nextRow < 0 or nextRow >= rowCount or nextColumn < 0 or nextColumn >= columnCount:
        continue
      let nextCellIndex = nextRow * columnCount + nextColumn
      if isWall[nextCellIndex]:
        continue
      if (doorMasks[nextCellIndex] and currentKeys) == 0 and doorMasks[nextCellIndex] != 0:
        continue
      let nextKeys = currentKeys or keyMasks[nextCellIndex]
      let nextState = nextCellIndex * keyCount + nextKeys
      if distances[nextState] != -1:
        continue
      distances[nextState] = distances[currentState] + 1
      if isExit[nextCellIndex]:
        escapeSteps = distances[nextState]
        break
      queue[queueTail] = nextState
      queueTail += 1
  if escapeSteps == -1:
    appendOutput("The poor student is trapped!")
  else:
    appendOutput("Escape possible in " & $escapeSteps & " steps.")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each state enters the queue at most once.
The first exit found has the shortest step count.
One buffer holds all scenario answers until a block fills.

## Complexity

The search visits each cell-key state once per map.

| phase | time | space |
|---|---|---|
| input read | one pass over map characters | one input string |
| breadth-first search | sixteen states per cell | one distance per state |
| output | one write per block | block buffer |

The phase costs all scale with the number of cells in one map.

| measure | Big O |
|---|---|
| time per map | O(R * C * 16) |
| space | O(R * C * 16) |

Searching positions without keys would shrink the state space but give wrong answers. The key bit set is what makes the linear scan exact.
