# CLK — Chomp (SPOJ)

<https://www.spoj.com/problems/CLK/>

## Problem

Decide whether the player to move can force a win from a Chomp position on a 10-by-10 board. The position lists the number of remaining pieces in each of ten columns. The bottom-left piece is poisoned, and the player who takes it loses.

The first line holds the number of positions. Each later line holds ten column heights from left to right. Each answer line holds `W` for a win or `L` for a loss.

| item | bound |
|---|---|
| positions | given by the first line |
| columns | 10 |
| column height | 0 to 10 |
| judge limit | 1753 ms, 1536 MB |

Heights never increase from left to right in a legal position.

Sample input:

```
3
2 2 0 0 0 0 0 0 0 0
2 1 0 0 0 0 0 0 0 0
10 10 10 10 10 10 10 10 10 10
```

Sample output:

```
W
L
W
```

## Idea

Treat every legal position as a node in a game graph, like marking winning squares on a board one row at a time. A move cuts a top-right rectangle, so it always removes at least one piece. Solve positions with few pieces first, then use them to label positions with more pieces. A hash table maps a packed height vector to its label. Replaying the game for each move from scratch would repeat enormous work.

## Why It Works

1. A state is the ten column heights, packed into four bits each.
2. Choosing column c and row r truncates every column from c onward to height r.
3. The poisoned piece sits at column 0, row 0.
4. A state with no pieces means the previous player took the poison, so the mover has won.
5. A state is winning when some move reaches a losing state.
6. Every move lowers the piece count, so processing states by piece count is safe.

| term | meaning |
|---|---|
| `stateCodes` | packed height vectors for all legal states |
| `stateBuckets` | state indexes grouped by remaining piece count |
| `winFlags` | true when the player to move can force a win |
| `hashKeys` | open-addressed table keys for packed states |

The piece-count order guarantees that every successor is already labelled.

The generator traces the first two sample positions:

| position | best move | successor | verdict |
|---|---|---|---|
| 2 2 0 … 0 | column 1, row 1 | 2 1 0 … 0 | W |
| 2 1 0 … 0 | no winning move | none | L |

The full 10-by-10 board is also winning.

## Code

**Input and packing.** The reader loads tokens and prepares the output buffer.

```nim
const flushBlockBytes = 1 shl 17
const columnCount = 10
const maximumHeight = 10
const hashBits = 20
const hashSize = 1 shl hashBits

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
```

Four bits hold each height.
The packed code fits in a signed 64-bit integer.
The hash table has one million slots.

**State storage.** Every nonincreasing height vector is generated once.

```nim
var stateCodes = newSeq[int64]()
var stateBuckets = newSeq[seq[int]](maximumHeight * columnCount + 1)
var hashKeys = newSeq[int64](hashSize)
var hashPositions = newSeq[int](hashSize)
var currentCode: int64 = 0

proc slotFor(code: int64): int =
  let mixed = code xor (code shr 19) xor (code shr 39)
  return int(mixed and int64(hashSize - 1))

proc insertState(code: int64, position: int) =
  var slot = slotFor(code)
  while hashKeys[slot] != -1:
    slot = (slot + 1) and (hashSize - 1)
  hashKeys[slot] = code
  hashPositions[slot] = position

proc findState(code: int64): int =
  var slot = slotFor(code)
  while true:
    if hashKeys[slot] == code:
      return hashPositions[slot]
    if hashKeys[slot] == -1:
      return -1
    slot = (slot + 1) and (hashSize - 1)

proc enumerateStates(column: int, ceiling: int, piecesSoFar: int) =
  if column == columnCount:
    let position = stateCodes.len
    stateCodes.add currentCode
    stateBuckets[piecesSoFar].add position
    insertState(currentCode, position)
    return
  var height = 0
  while height <= ceiling:
    let shift = 4 * column
    let fieldMask = int64(15) shl shift
    currentCode = (currentCode and not fieldMask) or (int64(height) shl shift)
    enumerateStates(column + 1, height, piecesSoFar + height)
    height += 1

for slot in 0 .. hashSize - 1:
  hashKeys[slot] = -1
enumerateStates(0, maximumHeight, 0)
```

The recursion forces heights to decrease left to right.
Each generated state is stored once in the hash table.
Buckets group states by their remaining piece count.

**Backward solve.** Each state checks all possible chomp moves.

```nim
var winFlags = newSeq[bool](stateCodes.len)
for pieces in 0 .. maximumHeight * columnCount:
  for position in stateBuckets[pieces]:
    let code = stateCodes[position]
    if code == 0:
      winFlags[position] = true
      continue
    var winning = false
    var chompColumn = 0
    while chompColumn < columnCount and not winning:
      let columnHeight = int((code shr (4 * chompColumn)) and int64(15))
      var chompRow = 0
      while chompRow < columnHeight:
        var successor = code
        var higherColumn = chompColumn
        while higherColumn < columnCount:
          let otherHeight = int((successor shr (4 * higherColumn)) and int64(15))
          if otherHeight > chompRow:
            successor = successor - (int64(otherHeight - chompRow) shl (4 * higherColumn))
          higherColumn += 1
        if not winFlags[findState(successor)]:
          winning = true
          break
        chompRow += 1
      chompColumn += 1
    winFlags[position] = winning
```

The empty board is winning for the player to move.
A single losing successor makes the current state winning.
The search stops at the first losing successor.

**Answer emission.** Each input position is packed and looked up.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  var positionCode: int64 = 0
  for column in 0 .. columnCount - 1:
    let columnHeight = nextInt(inputData, scanPos)
    positionCode = positionCode or (int64(columnHeight) shl (4 * column))
  if winFlags[findState(positionCode)]:
    appendOutput("W")
  else:
    appendOutput("L")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Column order matches the input order.
The solved table answers each case in constant time.
All lines are written through one buffer.

## Complexity

The precomputation covers all partitions inside a 10-by-10 box.

| phase | time | space |
|---|---|---|
| state generation | one visit per legal state | codes, buckets, hash |
| backward solve | one scan of moves per state | one win bit per state |
| output | one buffered line per case | block buffer |

The number of legal states is 184756.

| measure | Big O |
|---|---|
| time | O(184756 · moves) precompute, O(1) per case |
| space | O(184756) |

Recomputing the game tree for every case would cost far more than one shared table.
