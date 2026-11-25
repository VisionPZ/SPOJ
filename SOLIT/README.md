# SOLIT — Solitaire (SPOJ)
<https://www.spoj.com/problems/SOLIT/>

## Problem

Four identical pieces sit on an 8 by 8 board. A move steps one piece to an empty neighbor or jumps it over another piece. Decide whether one arrangement can become another in at most eight moves.

Input: an integer t, then t cases. Each case has two lines of eight integers, four row-column pairs per line. Output: `YES` when the target is reachable within eight moves, and `NO` otherwise.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Test cases | t from input |
| Board | 8 by 8 squares |
| Pieces | 4 identical pieces |
| Move limit | 8 moves |
| Judge time limit | 2000 ms |
| Judge memory limit | 1536 MB |

The pieces are identical, so only the occupied set matters.

The sample input:

```
1
4 4 4 5 5 4 6 5
2 4 3 3 3 6 4 6
```

The sample output:

```
YES
```

## Idea

Meet in the middle, like two hikers starting at opposite ends of a trail and hoping to meet halfway. Explore four moves out from the start and four moves back from the target. If the two small searches share an arrangement, eight moves connect them.

The program stores each board as a 64-bit bit mask with one bit per square. A combinadic rank turns every four-piece mask into a small integer, which indexes a visited stamp. Breadth-first expansion from each side costs at most a few hundred thousand states. A plain search to depth eight would branch across the full move tree and repeat many arrangements.

Two half-depth searches beat one full-depth search.

## Why It Works

Four facts carry the program.

1. Pieces are identical, so an arrangement is a set of four squares. A 64-bit mask represents that set exactly.
2. At most 8 choose 4, or 70, moves exist from any mask. Four directions serve each piece, and a jump needs an empty landing square.
3. Any path of at most eight moves passes through a state four moves from the start and four moves from the target. Meeting at that state proves reachability.
4. A combinadic rank maps each four-square mask to a number below 635376. A stamp array then replaces clearing a large visited set per case.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `startMask`, `targetMask` | 64-bit piece sets for the two arrangements |
| `rankMask` | combinadic index of a four-square mask |
| `seenMarks` | stamp array holding the last search that saw a rank |
| `searchHalfDepth` | four moves per side |

The two half-depth searches together cover eight moves exactly.

A script counts the state space for the board.

```text
boards with 4 pieces = C(64,4) = 635376
moves per state at most 4 pieces times 4 directions = 16
half-depth 4 from each side
a shared stamp means a path of at most 8 moves
```

The sample answer `YES` follows from such a shared state.

## Code

**Constants and move tables.** Precomputed tables avoid board arithmetic in the search.

```nim
{.push checks: off, overflowChecks: off, rangeChecks: off.}

import bitops

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const configCount = 635376
const noMark = 0'u32
const searchHalfDepth = 4
const dirRow = [-1, 1, 0, 0]
const dirCol = [0, 0, -1, 1]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`configCount` is 64 choose 4, so the stamp array stays small. `dirRow` and `dirCol` hold the four move directions.

**Lookup tables.** Binomial coefficients and landing squares are built once.

```nim
var binomTable: array[64, array[5, int]]
for squareIndex in 0..63:
  binomTable[squareIndex][0] = 1
  for chooseCount in 1..4:
    if squareIndex >= chooseCount:
      binomTable[squareIndex][chooseCount] = binomTable[squareIndex - 1][chooseCount] + binomTable[squareIndex - 1][chooseCount - 1]

var adjacentSquare: array[64, array[4, int]]
var landingSquare: array[64, array[4, int]]
for squareIndex in 0..63:
  let rowIndex = squareIndex div 8
  let colIndex = squareIndex mod 8
  for direction in 0..3:
    let adjacentRow = rowIndex + dirRow[direction]
    let adjacentCol = colIndex + dirCol[direction]
    if adjacentRow >= 0 and adjacentRow <= 7 and adjacentCol >= 0 and adjacentCol <= 7:
      adjacentSquare[squareIndex][direction] = adjacentRow * 8 + adjacentCol
    else:
      adjacentSquare[squareIndex][direction] = -1
    let landingRow = rowIndex + 2 * dirRow[direction]
    let landingCol = colIndex + 2 * dirCol[direction]
    if landingRow >= 0 and landingRow <= 7 and landingCol >= 0 and landingCol <= 7:
      landingSquare[squareIndex][direction] = landingRow * 8 + landingCol
    else:
      landingSquare[squareIndex][direction] = -1
```

`binomTable` feeds the combinadic rank. A value of minus one marks a move that leaves the board.

**Rank and expansion.** One rank identifies each four-piece set.

```nim
var seenMarks = newSeq[uint32](configCount)
var markCounter: uint32 = 0

proc rankMask(mask: uint64): int =
  var pieceSquares: array[4, int]
  var pieceCount = 0
  var remaining = mask
  while remaining != 0'u64:
    pieceSquares[pieceCount] = countTrailingZeroBits(remaining)
    pieceCount += 1
    remaining = remaining and (remaining - 1'u64)
  return binomTable[pieceSquares[0]][1] + binomTable[pieceSquares[1]][2] + binomTable[pieceSquares[2]][3] + binomTable[pieceSquares[3]][4]

proc expandInto(mask: uint64, newMark, otherMark: uint32, next: var seq[uint64]): bool =
  var pieceSquares: array[4, int]
  var pieceCount = 0
  var remaining = mask
  while remaining != 0'u64:
    pieceSquares[pieceCount] = countTrailingZeroBits(remaining)
    pieceCount += 1
    remaining = remaining and (remaining - 1'u64)
  for pieceIndex in 0..<pieceCount:
    let squareIndex = pieceSquares[pieceIndex]
    let sourceBit = 1'u64 shl squareIndex
    let clearedMask = mask and not sourceBit
    for direction in 0..3:
      let adjacentIndex = adjacentSquare[squareIndex][direction]
      if adjacentIndex < 0: continue
      let adjacentBit = 1'u64 shl adjacentIndex
      var landingBit: uint64
      if (mask and adjacentBit) == 0'u64:
        landingBit = adjacentBit
      else:
        let landingIndex = landingSquare[squareIndex][direction]
        if landingIndex < 0: continue
        landingBit = 1'u64 shl landingIndex
        if (mask and landingBit) != 0'u64: continue
      let neighborMask = clearedMask or landingBit
      let neighborRank = rankMask(neighborMask)
      if otherMark != noMark and seenMarks[neighborRank] == otherMark: return true
      if seenMarks[neighborRank] != newMark:
        seenMarks[neighborRank] = newMark
        next.add neighborMask
  return false
```

`countTrailingZeroBits` extracts each occupied square in order. A step uses the adjacent square when empty; otherwise it uses the landing square. The other-mark check finds a meeting state immediately.

**Half-depth search.** Breadth-first levels stop at four moves.

```nim
proc searchNeighborhood(origin: uint64, newMark, otherMark: uint32): bool =
  var states: seq[uint64] = @[origin]
  let originRank = rankMask(origin)
  if otherMark != noMark and seenMarks[originRank] == otherMark: return true
  seenMarks[originRank] = newMark
  var head = 0
  var depth = 0
  var levelEnd = 1
  while head < states.len and depth < searchHalfDepth:
    let mask = states[head]
    head += 1
    if expandInto(mask, newMark, otherMark, states): return true
    if head == levelEnd:
      depth += 1
      levelEnd = states.len
  return false

proc isReachable(startMask, targetMask: uint64): bool =
  if startMask == targetMask: return true
  markCounter += 1
  let startMark = markCounter
  discard searchNeighborhood(startMask, startMark, noMark)
  markCounter += 1
  return searchNeighborhood(targetMask, markCounter, startMark)
```

`levelEnd` marks where the next depth starts. Each side gets a fresh stamp, so no array clearing occurs. Equal masks return before any search.

**Driver.** Eight integers become two masks.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  var startMask = 0'u64
  for pieceIndex in 0..3:
    let rowNumber = nextInt(inputData, scanPos)
    let colNumber = nextInt(inputData, scanPos)
    startMask = startMask or (1'u64 shl ((rowNumber - 1) * 8 + (colNumber - 1)))
  var targetMask = 0'u64
  for pieceIndex in 0..3:
    let rowNumber = nextInt(inputData, scanPos)
    let colNumber = nextInt(inputData, scanPos)
    targetMask = targetMask or (1'u64 shl ((rowNumber - 1) * 8 + (colNumber - 1)))
  if isReachable(startMask, targetMask):
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Row and column minus one map onto square indices 0 through 63. Each case runs two bounded searches. The final write emits the remaining answers.

## Complexity

Each half-depth search has a fixed branching bound.

| Phase | Time | Space |
| --- | --- | --- |
| Table build | O(64 times 4) once | O(64 times 4) |
| Start search | at most 16 to the 4 states | visited stamps |
| Target search | at most 16 to the 4 states | visited stamps |
| Output | O(t) lines | one block |

The stamp array holds 635376 ranks and is allocated once.

| Measure | Big O |
| --- | --- |
| Time | O(branch to the 4) per side |
| Space | O(635376) stamps |

A single search to depth eight repeats far more states than the two half-depth searches.
