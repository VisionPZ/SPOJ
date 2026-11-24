## Problem

Four identical pieces occupy squares of an 8x8 board. A move slides one piece to an empty neighbor or jumps it over an adjacent piece into an empty square. Read two configurations and print YES when the second follows from the first in at most eight moves, else print NO.

The input and output stay small; the search sets the cost.

| Quantity | Bound |
| --- | --- |
| Board | 8 x 8 squares |
| Pieces | 4 per configuration |
| Move limit | 8 moves |
| Cases per file | fewer than 30 |
| Time limit | 2000 ms |
| Memory limit | 1536 MB |

The move limit, not the file size, drives the design.

## Idea

Meet in the middle (search from both ends) with two layer-by-layer searches. Build every configuration reachable within four moves from each end, then test the two sets for a shared member. Any path of at most eight moves passes through such a shared member, while a search from one end visits far more states.

Cost per case: about 5,500 stored configurations and their neighbors.

## Why It Works

Each configuration is a set of four squares, so the board has 635376 such sets. A slide or a jump moves one piece and leaves the other three fixed. Both moves are reversible, so the graph has no direction and a path splits at its midpoint. A path of length L <= 8 has a midpoint within four moves of each end.

Four set bits mark the four pieces in one 64-bit value.

`(rowNumber - 1) * 8 + (colNumber - 1)` names the bit for a square.

`1'u64 shl squareIndex` sets that bit in a mask.

`clearedMask = mask and not sourceBit` removes the moving piece.

The landing square is set next to form `neighborMask`.

The rank formula maps a sorted quadruple of square indices to one slot in a flat mark array.

`binomTable[pieceSquares[0]][1] + binomTable[pieceSquares[1]][2] + binomTable[pieceSquares[2]][3] + binomTable[pieceSquares[3]][4]`

Each mark belongs to one search, so a slot held by both searches gives the answer. A counter supplies a fresh mark per search and avoids clearing the array.

The generator prints the layer sizes from the sample start.

| Moves from the sample start | States |
| --- | --- |
| 0 | 1 |
| 1 | 16 |
| 2 | 134 |
| 3 | 715 |
| 4 | 2755 |
| 5 | 8158 |
| 6 | 19405 |
| 7 | 38053 |
| 8 | 62578 |

The sample target first appears at depth 7, which yields YES.

## Code

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

The pragmas remove runtime checks from the hot loop. The scanner skips separators, so the two lines per case need no special handling. One read fills `inputData` and one buffer holds the output.

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
```

The tables fill once at startup and are reused by every case. The rank indexes `seenMarks` directly, with no hash step. Cost: four trailing-bit steps per rank.

```nim
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

The piece loop runs at most four times, once per set bit. Precomputed landing squares keep moves inside the board. Cost: sixteen direction checks per state.

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

`searchHalfDepth` caps each search at four layers. `noMark` keeps the first search from matching empty slots. The second search stops at the first shared slot.

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

The case loop reads sixteen integers and runs once per case. One-based coordinates become bits without a per-piece object. The final write flushes the single output buffer.

## Complexity

Reading and scanning take O(input bytes) time and O(input bytes) space. Let N be the number of states within four moves of one configuration. Each search takes O(N) time and stores O(N) states. The mark array takes O(C(64,4)) space. The total per case is O(N) time, with N below 2,800 here. A search from one end to depth eight visits about 132,000 states from a central start.
