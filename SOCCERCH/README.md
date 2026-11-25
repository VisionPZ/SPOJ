# SOCCERCH — Soccer Challenge (SPOJ)
<https://www.spoj.com/problems/SOCCERCH/>

## Problem

Find the shortest closed run along plot boundaries from a field corner that inspects every target plot and no muddy plot. Report the winner of Fernando and Martin, or `Tie`, with that shortest length.

Input holds many fields. Each starts with rows `R` and columns `C`, then `R` strings of `I`, `X` and `O`. The line `0 0` ends the input. Fernando starts at the top-left corner; Martin starts at the bottom-right corner.

| item | bound |
|---|---|
| rows R | 1 to 50 |
| columns C | 1 to 50 |
| target plus muddy plots | at most 10 |
| judge limit | 24890 ms, 1536 MB |

A plot is inspected when the closed path winds around it. Retracing a boundary adds two steps and does not change which plots lie inside.

Sample input:

```
1 1 I
2 2
XX
XI
2 2
XI
IX
3 3
III
IXI
III
2 2
IO
OO
0 0
```

Sample output:

```
Tie 4
Martin 4
Tie 10
Tie 18
Fernando 4
```

## Idea

Treat the walk like drawing a loop with a pencil, then ask how many times the loop wraps each marked plot. Only the parity of that wrap count matters, like a light that flips each time the pencil crosses a ray. A breadth-first search over position plus flip bits finds the shortest loop.

Each vertical boundary step flips the bits of plots lying to its left in that row. Horizontal steps flip nothing. The state space stays small because at most ten plots matter.

## Why It Works

1. A closed boundary walk gives each plot a winding number around its centre.
2. A plot is inspected exactly when its winding number is odd.
3. Send a horizontal ray from the plot centre to the right.
4. A vertical step at column `c` crosses that ray for plots in the same row with column less than `c`.
5. Crossing flips the parity bit for each such plot.

| term | meaning |
|---|---|
| `interestingRows` | row of each target or muddy plot |
| `wantedMask` | bits set for target plots and clear for muddy plots |
| `flipMasks` | bits flipped by one vertical step |
| `currentMask` | parity bits at the current grid vertex |

For the field `XI / IX`, the two target plots sit on opposite diagonals. A loop of length 10 wraps both of them and leaves the muddy plots outside. Both corners give the same length, so the answer is `Tie 10`.

## Code

**Input helpers.** The whole input is buffered, and field rows are read as words of `I`, `X`, `O`.

```nim
const flushBlockBytes = 1 shl 17
const unreachableDistance = 1000000000

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

proc nextFieldWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] notin {'I', 'X', 'O'}:
    pos += 1
  var word = ""
  while pos < data.len and data[pos] in {'I', 'X', 'O'}:
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner ignores blank separators.
Field rows keep their character order.
All answers wait in one output buffer.

**Build the flip table.** A vertical step flips the bits of plots on its left.

```nim
proc solveForCorner(field: seq[string], cornerRow, cornerCol: int): int =
  let fieldRows = field.len
  let fieldCols = field[0].len
  var interestingRows: seq[int] = @[]
  var interestingCols: seq[int] = @[]
  var wantedMask = 0
  for rowIndex in 0 .. fieldRows - 1:
    for colIndex in 0 .. fieldCols - 1:
      if field[rowIndex][colIndex] != 'O':
        let bitIndex = interestingRows.len
        interestingRows.add rowIndex
        interestingCols.add colIndex
        if field[rowIndex][colIndex] == 'I':
          wantedMask = wantedMask or (1 shl bitIndex)
  let interestingCount = interestingRows.len
  let maskCount = 1 shl interestingCount
  let vertexCols = fieldCols + 1
  let vertexCount = (fieldRows + 1) * vertexCols
  var flipMasks = newSeq[seq[int]](fieldRows)
  for rowIndex in 0 .. fieldRows - 1:
    flipMasks[rowIndex] = newSeq[int](fieldCols + 1)
    for colIndex in 0 .. fieldCols:
      var flipMask = 0
      for bitIndex in 0 .. interestingCount - 1:
        if interestingRows[bitIndex] == rowIndex and interestingCols[bitIndex] < colIndex:
          flipMask = flipMask or (1 shl bitIndex)
      flipMasks[rowIndex][colIndex] = flipMask
```

Only target and muddy plots receive bits.
A target bit starts set in the goal mask.
A muddy bit starts clear, so it must stay clear.

**Search the state space.** Each state pairs a grid vertex with one parity pattern.

```nim
  let stateCount = vertexCount * maskCount
  var distances = newSeq[int](stateCount)
  var queue = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    distances[stateIndex] = unreachableDistance
  let startVertex = cornerRow * vertexCols + cornerCol
  let goalState = startVertex * maskCount + wantedMask
  let startState = startVertex * maskCount
  distances[startState] = 0
  var queueHead = 0
  var queueTail = 0
  queue[queueTail] = startState
  queueTail += 1
  while queueHead < queueTail:
    let stateIndex = queue[queueHead]
    queueHead += 1
    let currentDistance = distances[stateIndex]
    let currentMask = stateIndex mod maskCount
    let currentVertex = stateIndex div maskCount
    if stateIndex == goalState:
      return currentDistance
    let currentRow = currentVertex div vertexCols
    let currentCol = currentVertex mod vertexCols
```

The start state has all bits clear.
The goal state returns to the same corner with the wanted pattern.
Breadth-first order gives the shortest walk first.

**Four moves.** Vertical moves flip bits; horizontal moves keep them.

```nim
    if currentRow > 0:
      let nextVertex = currentVertex - vertexCols
      let nextMask = currentMask xor flipMasks[currentRow - 1][currentCol]
      let nextState = nextVertex * maskCount + nextMask
      if distances[nextState] > currentDistance + 1:
        distances[nextState] = currentDistance + 1
        queue[queueTail] = nextState
        queueTail += 1
    if currentRow < fieldRows:
      let nextVertex = currentVertex + vertexCols
      let nextMask = currentMask xor flipMasks[currentRow][currentCol]
      let nextState = nextVertex * maskCount + nextMask
      if distances[nextState] > currentDistance + 1:
        distances[nextState] = currentDistance + 1
        queue[queueTail] = nextState
        queueTail += 1
    if currentCol > 0:
      let nextVertex = currentVertex - 1
      let nextState = nextVertex * maskCount + currentMask
      if distances[nextState] > currentDistance + 1:
        distances[nextState] = currentDistance + 1
        queue[queueTail] = nextState
        queueTail += 1
    if currentCol < fieldCols:
      let nextVertex = currentVertex + 1
      let nextState = nextVertex * maskCount + currentMask
      if distances[nextState] > currentDistance + 1:
        distances[nextState] = currentDistance + 1
        queue[queueTail] = nextState
        queueTail += 1
  return unreachableDistance
```

Each accepted update enqueues the new state once.
Walking the same boundary twice appears as two moves.
The search ends as soon as the goal state leaves the queue.

**Driver.** Both corners use the same search, then the shorter length wins.

```nim
while true:
  let fieldRows = nextInt(inputData, scanPos)
  let fieldCols = nextInt(inputData, scanPos)
  if fieldRows == 0 and fieldCols == 0:
    break
  var field: seq[string] = @[]
  for rowIndex in 0 .. fieldRows - 1:
    field.add nextFieldWord(inputData, scanPos)
  let fernandoLength = solveForCorner(field, 0, 0)
  let martinLength = solveForCorner(field, fieldRows, fieldCols)
  if fernandoLength < martinLength:
    appendOutput("Fernando ")
    appendOutput($fernandoLength)
  elif martinLength < fernandoLength:
    appendOutput("Martin ")
    appendOutput($martinLength)
  else:
    appendOutput("Tie ")
    appendOutput($fernandoLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The pair `0 0` ends the input.
Equal lengths print `Tie` once.
The final flush writes all result lines.

## Complexity

The state space is the grid vertices times the parity patterns.

| phase | time | space |
|---|---|---|
| read one field | one pass over R times C plots | field rows |
| build flip table | one pass over grid steps and marked plots | one mask per step |
| breadth-first search | four moves per visited state | distance and queue arrays |

| measure | Big O |
|---|---|
| time per corner | O(R*C*2^K) for K marked plots |
| space per corner | O(R*C*2^K) |

K stays at most 10, so the mask count never exceeds 1024.
Enumerating all closed walks would be exponential in the walk length.
The state search collapses those walks into one visit per vertex and mask.
