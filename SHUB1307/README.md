# SHUB1307 — Gupta ji Birthday !! (SPOJ)

<https://www.spoj.com/problems/SHUB1307/>

## Problem

Walk from the top-left tile to the bottom-right tile, moving east, south, or south-east. Each tile has a shot count, and the total along the path must stay at most `K`. Report the largest legal total, or `-1` when no path fits.

Input starts with `T` cases. Each case gives `N`, `M`, and `K`, then `N` rows of `M` tile values. Output one answer per case.

| Item | Bound |
|---|---|
| Cases T | 1 to 10 |
| Grid N, M | 1 to 100 each |
| Capacity K | 1 to 5000 |
| Tile value | 1 to 50 |
| Judge limit | 5000 ms, 1536 MB |

A path visits at most 100 tiles, so its sum stays at most 5000.

The sample has a grid that fits and one that cannot:

```
2
3 3 7
2 3 1
6 1 9
8 2 3
3 4 9
2 3 4 1
6 5 5 3
5 2 3 4
```

The expected output is:

```
6
-1
```

The diagonal path `2 + 1 + 3` gives six shots in the first grid.

## Idea

Track which totals are possible at each tile, like crossing a bridge and marking every weight the bridge can still carry. Store all totals from zero to `K` as bits in one row of machine words. Moving to the next tile shifts those bits by that tile's value. A boolean array per tile would repeat work and cost far more.

## Why It Works

1. A tile draws from its west, north, and north-west neighbours.
2. Row-major order finishes those neighbours before the current tile.
3. Bit `s` in a neighbour means total `s` is reachable there.
4. Adding the current value shifts every set bit forward by that amount.
5. Shifting past `K` is dropped by masking the final word.
6. The highest set bit at the exit tile is the largest legal total.

| Term | Meaning |
|---|---|
| `wordBitCount` | number of totals held in one uint64 word |
| `previousRow` | bit sets for the row above |
| `currentRow` | bit sets for the row being built |
| `capacityMask` | clears bits beyond `K` in the top word |
| `bestShots` | highest reachable total at the exit |

The table lists the state used by each tile.

Reachable totals in the first sample grid, with `K = 7`:

```
tile value  reachable totals
2           2
3 1         5    6
6 1 9       3 6  -
8 2 3       5    6
```

The exit tile reaches six, matching the sample answer.

## Code

**Input and scanning.** The hand reader loads case headers and tile values.

```nim
const flushBlockBytes = 1 shl 17
const wordBitCount = 64

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

proc collectSource(sourceBits: var seq[uint64], sourceRow: seq[uint64], baseIndex: int, wordCount: int) =
  for wordIndex in 0 .. wordCount - 1:
    sourceBits[wordIndex] = sourceBits[wordIndex] or sourceRow[baseIndex + wordIndex]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips all whitespace between tiles.
The source helper ORs a neighbour's bits into one scratch row.
The buffer collects answers across cases.

**Case setup.** One mask per case limits totals to `K`.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let colCount = nextInt(inputData, scanPos)
  let capacity = nextInt(inputData, scanPos)
  let wordCount = capacity div wordBitCount + 1
  let topValidBits = capacity mod wordBitCount + 1
  var capacityMask: uint64 = 0'u64
  if topValidBits == wordBitCount:
    capacityMask = not 0'u64
  else:
    capacityMask = (1'u64 shl topValidBits) - 1'u64
  var previousRow = newSeq[uint64](colCount * wordCount)
  var currentRow = newSeq[uint64](colCount * wordCount)
  var sourceBits = newSeq[uint64](wordCount)
  for rowIndex in 0 .. rowCount - 1:
```

The word count covers bits zero through `K`.
Two rows are enough because moves use only adjacent rows.
The scratch row holds the three merged neighbours.

**Tile transition.** Each tile shifts its sources by its own value.

```nim
    for colIndex in 0 .. colCount - 1:
      let shotValue = nextInt(inputData, scanPos)
      for wordIndex in 0 .. wordCount - 1:
        sourceBits[wordIndex] = 0'u64
      if rowIndex == 0 and colIndex == 0:
        sourceBits[0] = 1'u64
      else:
        if colIndex > 0:
          collectSource(sourceBits, currentRow, (colIndex - 1) * wordCount, wordCount)
        if rowIndex > 0:
          collectSource(sourceBits, previousRow, colIndex * wordCount, wordCount)
          if colIndex > 0:
            collectSource(sourceBits, previousRow, (colIndex - 1) * wordCount, wordCount)
      let destBase = colIndex * wordCount
      for wordIndex in 0 .. wordCount - 1:
        currentRow[destBase + wordIndex] = 0'u64
      let wordShift = shotValue div wordBitCount
      let bitShift = shotValue mod wordBitCount
      for wordIndex in 0 .. wordCount - 1:
        let sourceIndex = wordIndex - wordShift
        if sourceIndex >= 0:
          var shiftedBits = sourceBits[sourceIndex] shl bitShift
          if bitShift > 0 and sourceIndex > 0:
            shiftedBits = shiftedBits or (sourceBits[sourceIndex - 1] shr (wordBitCount - bitShift))
          currentRow[destBase + wordIndex] = shiftedBits
      let topWordIndex = destBase + wordCount - 1
      currentRow[topWordIndex] = currentRow[topWordIndex] and capacityMask
    swap previousRow, currentRow
```

The start tile begins from total zero.
A word shift plus a bit shift moves every reachable total at once.
The top-word mask drops totals above `K`.

**Answer extraction.** The highest set bit at the exit is the answer.

```nim
  var bestShots = -1
  var wordIndex = wordCount - 1
  while wordIndex >= 0:
    let wordValue = previousRow[(colCount - 1) * wordCount + wordIndex]
    if wordValue != 0'u64:
      var bitIndex = wordBitCount - 1
      while bitIndex >= 0 and (wordValue and (1'u64 shl bitIndex)) == 0'u64:
        bitIndex -= 1
      bestShots = wordIndex * wordBitCount + bitIndex
      break
    wordIndex -= 1
  appendOutput($bestShots)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

An empty exit set produces minus one.
Words are scanned from the top to find the largest total.
One flush writes every case answer.

## Complexity

Each tile merges and shifts a fixed number of words.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all tile values | one input string |
| Tile transition | word operations per tile | two rows of words |
| Output | one line per case | block buffer |

Work grows with tiles times words, not with capacity alone.

| Measure | Big O |
|---|---|
| Time | O(N × M × K / 64) per case |
| Space | O(M × K / 64) |

A three-dimensional boolean table would use O(N × M × K) time and space instead.
