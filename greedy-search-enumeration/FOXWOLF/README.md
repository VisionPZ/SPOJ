# FOXWOLF — The Fox and the Wolf (SPOJ)

<https://www.spoj.com/problems/FOXWOLF/>

## Problem

Two animals walk toward their own homes on a small grid. They move one cell per minute or stay put, pay a delay when leaving burrs for meadow, and chat once if they meet. Find the earliest minute when both are home.

Input starts with four integers: rows, columns, chat minutes, and burr minutes. The next rows hold grid characters. A dot is meadow, B is burrs, T is trees. F and W mark the two homes; f and w mark the starts. Output the minimum finish time, or -1 when no plan works.

The bounds from the statement:

| Item | Bound |
|---|---|
| Rows N | 1 to 20 |
| Columns M | 1 to 20 |
| Chat minutes C | 1 to 9 |
| Burr minutes B | 1 to 9 |
| Judge limit | 2000 ms, 1536 MB |

Both animals act on the same clock, so the schedule must be searched as one joint state.

The sample input:

```
5 6 5 1
......
BWTTTB
B.TB..
BBT..T
.FTfw.
```

The sample output:

```
17
```

The wolf waits three minutes, then follows the fox; the fox finishes at minute 17.

## Idea

Both animals share one clock, like two runners who pause separately. One state holds both positions and both remaining pause times.

The algorithm is a breadth-first search over joint states. A state records each animal's cell, its remaining stand-still minutes, and whether the chat already happened. Every transition takes one minute, so the first goal state reached gives the minimum finish time. A separate search per animal misses the chat and the rule that one may wait while the other walks. The takeaway is to put both animals and their timers into one state and search in time order.

## Why It Works

1. At each minute an animal stays or moves to a side neighbor, never into a tree or the other home.
2. Moving from a burr into a meadow adds burr minutes of standing still for that animal only.
3. The other animal keeps moving during that pause, so each animal needs its own timer.
4. A meeting happens on the same cell at the same minute or on a swap of cells.
5. The chat adds chat minutes to both animals, overlapping with any burr pause at that same minute.
6. The chat happens at most once, so one flag closes that part of the state.
7. All transitions cost one minute, so breadth-first search reaches the goal in minimum time.

The main terms:

| Term | Meaning |
|---|---|
| `foxMoves` | legal next cells for the fox, including staying |
| `timerBase` | number of distinct values a timer can hold |
| `distance` | best minute seen for each encoded state |
| `burrPenalty` | extra pause for leaving a burr for meadow |

The table shows that the state carries both positions and both timers without extra copies.

The generator trace uses this small case:

```
grid:  W f . . w F
chat = 5, burr = 1
fox steps to home:  4
wolf steps to home: 4
they meet in the middle and chat: +5
answer: 4 + 5 = 9
```

The trace matches the second edge case answer of nine.

## Code

**Input and scanning.** The reader loads the header, the grid, and the four special cells.

```nim
const flushBlockBytes = 1 shl 17
const invalidDistance = -1

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let chatDuration = nextInt(inputData, scanPos)
let burrDuration = nextInt(inputData, scanPos)
let cellCount = rowCount * columnCount
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var grid = newSeq[char](cellCount)
var foxStart = -1
var wolfStart = -1
var foxHome = -1
var wolfHome = -1
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cell = rowIndex * columnCount + columnIndex
    let cellChar = inputData[scanPos]
    scanPos += 1
    grid[cell] = cellChar
    if cellChar == 'f': foxStart = cell
    elif cellChar == 'w': wolfStart = cell
    elif cellChar == 'F': foxHome = cell
    elif cellChar == 'W': wolfHome = cell
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
```

All grid lines enter one input string first.
Missing starts or homes produce the impossible answer at once.
Each special cell is recorded while the grid is read.

**Legal moves.** Staying is included, and each home is reserved for its own animal.

```nim
if foxStart == -1 or wolfStart == -1 or foxHome == -1 or wolfHome == -1:
  appendOutput("-1\n")
else:
  var isBurr = newSeq[bool](cellCount)
  var isMeadow = newSeq[bool](cellCount)
  for cell in 0 .. cellCount - 1:
    isBurr[cell] = grid[cell] == 'B'
    isMeadow[cell] = grid[cell] == '.'

  var foxMoveStart = newSeq[int](cellCount)
  var wolfMoveStart = newSeq[int](cellCount)
  var foxMoveCount = newSeq[int](cellCount)
  var wolfMoveCount = newSeq[int](cellCount)
  var foxMoves = newSeq[int](cellCount * 5)
  var wolfMoves = newSeq[int](cellCount * 5)
  var foxMoveTotal = 0
  var wolfMoveTotal = 0
  for cell in 0 .. cellCount - 1:
    foxMoveStart[cell] = foxMoveTotal
    wolfMoveStart[cell] = wolfMoveTotal
    foxMoves[foxMoveTotal] = cell
    wolfMoves[wolfMoveTotal] = cell
    foxMoveTotal += 1
    wolfMoveTotal += 1
    foxMoveCount[cell] = 1
    wolfMoveCount[cell] = 1
    let rowIndex = cell div columnCount
    let columnIndex = cell mod columnCount
    for deltaRow in -1 .. 1:
      for deltaColumn in -1 .. 1:
        if (deltaRow == 0 and deltaColumn == 0) or (deltaRow != 0 and deltaColumn != 0):
          continue
        let nextRow = rowIndex + deltaRow
        let nextColumn = columnIndex + deltaColumn
        if nextRow < 0 or nextRow >= rowCount or nextColumn < 0 or nextColumn >= columnCount:
          continue
        let neighbor = nextRow * columnCount + nextColumn
        let neighborChar = grid[neighbor]
        if neighborChar == 'T':
          continue
        if neighborChar != 'W':
          foxMoves[foxMoveTotal] = neighbor
          foxMoveTotal += 1
          foxMoveCount[cell] += 1
        if neighborChar != 'F':
          wolfMoves[wolfMoveTotal] = neighbor
          wolfMoveTotal += 1
          wolfMoveCount[cell] += 1
```

Staying put is always a legal move for both animals.
Trees are blocked for both, and each home is blocked for the other animal.
Flat move arrays keep the search loop free of allocations.

**State space.** Timers and the chat flag are packed into one integer per state.

```nim
  let timerBase = max(burrDuration, chatDuration) + 1
  let stateCount = cellCount * cellCount * timerBase * timerBase * 2
  var distance = newSeq[int32](stateCount)
  for index in 0 .. stateCount - 1:
    distance[index] = invalidDistance
  var queue = newSeq[int32](stateCount)
  var queueHead = 0
  var queueTail = 0

  proc encodeState(foxCell: int, wolfCell: int, foxBusy: int, wolfBusy: int, chatted: int): int =
    return (((foxCell * cellCount + wolfCell) * timerBase + foxBusy) * timerBase + wolfBusy) * 2 + chatted

  proc burrPenalty(fromCell: int, toCell: int): int =
    if isBurr[fromCell] and isMeadow[toCell]:
      return burrDuration
    return 0

  let startState = encodeState(foxStart, wolfStart, 0, 0, 0)
  distance[startState] = 0
  queue[queueTail] = int32(startState)
  queueTail += 1
  var answer = -1
```

The timer base covers the larger of the two possible pauses.
`distance` starts at minus one so unvisited states are easy to spot.
The queue holds each state at most once because every edge costs one minute.

**Breadth-first search.** The first goal state dequeued gives the minimum finish time.

```nim
  while queueHead < queueTail:
    let state = int(queue[queueHead])
    queueHead += 1
    let chatted = state mod 2
    let afterChat = state div 2
    let wolfBusy = afterChat mod timerBase
    let afterWolf = afterChat div timerBase
    let foxBusy = afterWolf mod timerBase
    let afterFox = afterWolf div timerBase
    let wolfCell = afterFox mod cellCount
    let foxCell = afterFox div cellCount
    let reached = distance[state]
    if foxCell == foxHome and wolfCell == wolfHome:
      answer = int(reached)
      break

    if foxBusy > 0 and wolfBusy > 0:
      let nextState = encodeState(foxCell, wolfCell, foxBusy - 1, wolfBusy - 1, chatted)
      if distance[nextState] == invalidDistance:
        distance[nextState] = reached + 1
        queue[queueTail] = int32(nextState)
        queueTail += 1
```

Decoding divides out one field at a time from the packed state.
The goal check runs on dequeue, so the first hit is optimal.
Both busy animals only lose one timer minute per step.

```nim
    elif foxBusy > 0:
      let wolfBegin = wolfMoveStart[wolfCell]
      let wolfEnd = wolfBegin + wolfMoveCount[wolfCell] - 1
      for wolfIndex in wolfBegin .. wolfEnd:
        let nextWolf = wolfMoves[wolfIndex]
        let penalty = burrPenalty(wolfCell, nextWolf)
        let meeting = foxCell == nextWolf
        var nextFoxBusy = foxBusy - 1
        var nextWolfBusy = penalty
        var nextChatted = chatted
        if meeting and chatted == 0:
          nextFoxBusy = max(nextFoxBusy, chatDuration)
          nextWolfBusy = max(penalty, chatDuration)
          nextChatted = 1
        let nextState = encodeState(foxCell, nextWolf, nextFoxBusy, nextWolfBusy, nextChatted)
        if distance[nextState] == invalidDistance:
          distance[nextState] = reached + 1
          queue[queueTail] = int32(nextState)
          queueTail += 1
    elif wolfBusy > 0:
      let foxBegin = foxMoveStart[foxCell]
      let foxEnd = foxBegin + foxMoveCount[foxCell] - 1
      for foxIndex in foxBegin .. foxEnd:
        let nextFox = foxMoves[foxIndex]
        let penalty = burrPenalty(foxCell, nextFox)
        let meeting = nextFox == wolfCell
        var nextFoxBusy = penalty
        var nextWolfBusy = wolfBusy - 1
        var nextChatted = chatted
        if meeting and chatted == 0:
          nextFoxBusy = max(penalty, chatDuration)
          nextWolfBusy = max(nextWolfBusy, chatDuration)
          nextChatted = 1
        let nextState = encodeState(nextFox, wolfCell, nextFoxBusy, nextWolfBusy, nextChatted)
        if distance[nextState] == invalidDistance:
          distance[nextState] = reached + 1
          queue[queueTail] = int32(nextState)
          queueTail += 1
```

The walking animal keeps moving while the other animal pauses.
A meeting inside a pause overlaps the chat with that pause.
Maximum, not addition, combines the two pause lengths.

```nim
    else:
      let foxBegin = foxMoveStart[foxCell]
      let foxEnd = foxBegin + foxMoveCount[foxCell] - 1
      let wolfBegin = wolfMoveStart[wolfCell]
      let wolfEnd = wolfBegin + wolfMoveCount[wolfCell] - 1
      for foxIndex in foxBegin .. foxEnd:
        let nextFox = foxMoves[foxIndex]
        let foxPenalty = burrPenalty(foxCell, nextFox)
        for wolfIndex in wolfBegin .. wolfEnd:
          let nextWolf = wolfMoves[wolfIndex]
          let wolfPenalty = burrPenalty(wolfCell, nextWolf)
          let meeting = (nextFox == nextWolf) or (nextFox == wolfCell and nextWolf == foxCell)
          var nextFoxBusy = foxPenalty
          var nextWolfBusy = wolfPenalty
          var nextChatted = chatted
          if meeting and chatted == 0:
            let delay = max(foxPenalty, max(wolfPenalty, chatDuration))
            nextFoxBusy = delay
            nextWolfBusy = delay
            nextChatted = 1
          let nextState = encodeState(nextFox, nextWolf, nextFoxBusy, nextWolfBusy, nextChatted)
          if distance[nextState] == invalidDistance:
            distance[nextState] = reached + 1
            queue[queueTail] = int32(nextState)
            queueTail += 1

  appendOutput($answer & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Same-cell and swap meetings both trigger the single chat.
A pause that starts at the meeting minute overlaps the chat.
An empty search leaves the answer at minus one.

## Complexity

The state space is bounded by both cells, both timers, and the chat flag.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over grid characters | input string |
| Move tables | up to five moves per cell | two flat move arrays |
| Breadth-first search | at most one visit per state | distance and queue arrays |
| Output | one line | block buffer |

The table shows that the packed state drives the search cost.

| Measure | Big O |
|---|---|
| Time | O(Cells squared Times Timers squared Times 25) |
| Space | O(Cells squared Times Timers squared) |

Searching each animal alone would ignore meetings and independent pauses. The joint search records both animals at once and still finishes within the bound.
