# PROPKEY — The Proper Key (SPOJ)

<https://www.spoj.com/problems/PROPKEY/>

## Problem

A flat wooden key falls into a grid lock, sliding sideways but never rotating. Report how deep it can fall, or whether it passes through.

Input: `T` cases. Each starts with `R C`, then `R` rows of `#` (wood) and `.` (empty) for the key. Next come `D W`, then `D` such rows for the lock. Output: `The key falls to depth X.` when it stops, or `The key can fall through.` when it exits the bottom.

The bounds from the statement:

| Item | Bound |
|---|---|
| Key rows and columns | 1 ≤ R, C ≤ 100 |
| Lock depth `D` | 1 ≤ D ≤ 10000 |
| Lock width `W` | 1 ≤ W ≤ 1000 |
| Judge limit | 1000 ms, 1536 MB |

Depth counts from the bottom of the key to the top of the lock, so a key that cannot enter has depth 0.

The sample input and output:

```
4
2 4
#.##
###.
3 6
#....#
#....#
#..###
2 3
##.
.##
2 7
#.#.#.#
.#.#.#.
1 1
#
1 10
###....###
3 2
##
.#
.#
1 5
#.#.#
```

```
The key falls to depth 2.
The key falls to depth 0.
The key can fall through.
The key falls to depth 2.
```

## Idea

Model the fall as a sequence of sideways slides, like a Tetris piece that slides but never rotates. If a slot is free, the key can slide there and keep going down.

The program first stores each lock column as bitsets (arrays of 64-bit words, one bit per depth row). For every key row it builds a fail mask: the offsets where that key row hits lock wood. A sweep over depth then tracks which offsets stay reachable.

Between rows the key may slide sideways. Reachable offsets therefore spread across each contiguous run of valid offsets. Bitset words test 64 offsets at once, and the sweep touches a few words per row. Cell-by-cell simulation would cost `R × D × W` per case.

Bitsets collapse the sideways sliding into a handful of word operations per row.

## Why It Works

Four facts carry the simulation.

1. An offset is valid at a given depth exactly when no key wood cell lands on a lock wood cell. The `#` marks in both grids define those cells.
2. The key slides sideways between rows, so every offset joined to a reachable one through a run of valid offsets stays reachable.
3. One 64-bit word holds 64 offsets. `orShiftedAt` aligns a key row's blocked columns onto each diagonal, building fail masks for many offsets in parallel.
4. The sweep stops when no offset remains reachable. If the key crosses all `D` rows, it falls through.

The bitsets that drive the sweep:

| Term | Meaning |
|---|---|
| `blockedCol` | bitset of wooden rows in one lock column |
| `diagonalFail` | fail bits for every offset and diagonal |
| `previousReach` | offsets reachable before the current row |
| `currentValid` | offsets where the key meets no lock wood |

The runs of valid offsets implement the free sideways slide.

A script-traced example uses sample case 3, a one-cell key and lock row `###....###`:

```
key:   #                 free lock columns: 3,4,5,6
lock:  ###....###        valid offsets: 3,4,5,6 (four in a row)
depth 1 is crossed with a reachable offset -> "The key can fall through."
```

Sample case 2 shows the opposite. Key row `##.` needs two adjacent free cells, but lock row `#.#.#.#` has none. No offset fits at depth 0, so the answer is depth 0.

## Code

**Input helpers.** Grid rows are copied straight from the buffered stream.

```nim
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

proc skipWhitespace(inputData: string, i: var int) =
  while i < inputData.len and ord(inputData[i]) <= 32:
    i += 1

proc nextInteger(inputData: string, i: var int): int =
  skipWhitespace(inputData, i)
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (ord(inputData[i]) - firstDigitValue)
    i += 1
```

`skipWhitespace` advances past separators, including blank lines. `nextInteger` reads one positive value by index.

**Grid reader.** One row of characters lands in a flat cell array.

```nim
proc readGridRow(inputData: string, i: var int, cells: var string, cellOffset: int, rowWidth: int) =
  skipWhitespace(inputData, i)
  for j in 0 ..< rowWidth:
    cells[cellOffset + j] = inputData[i + j]
  i += rowWidth
```

`cellOffset` points at the first cell of the row, so the key and lock share one reader. The index advances by exactly `rowWidth` characters.

**Bit operations.** These helpers set, clear, copy, intersect, and shift 64-bit words.

```nim
proc bitIsSet(bits: seq[uint64], i: int): bool =
  (bits[i shr 6] and (1'u64 shl (i and 63))) != 0'u64

proc setBit(bits: var seq[uint64], i: int) =
  bits[i shr 6] = bits[i shr 6] or (1'u64 shl (i and 63))

proc clearBits(bits: var seq[uint64]) =
  for i in 0 ..< bits.len:
    bits[i] = 0'u64

proc copyBits(dest: var seq[uint64], src: seq[uint64]) =
  for i in 0 ..< dest.len:
    dest[i] = src[i]

proc intersectBits(dest: var seq[uint64], src: seq[uint64]) =
  for i in 0 ..< dest.len:
    dest[i] = dest[i] and src[i]

proc orWordsAt(dest: var seq[uint64], destBase: int, src: seq[uint64], srcBase: int, count: int) =
  for i in 0 ..< count:
    dest[destBase + i] = dest[destBase + i] or src[srcBase + i]

proc orShiftedAt(dest: var seq[uint64], destBase: int, src: seq[uint64], srcBase: int,
                 count: int, wordShift: int, bitShift: int) =
  if bitShift == 0:
    for i in 0 ..< count:
      dest[destBase + i + wordShift] =
        dest[destBase + i + wordShift] or src[srcBase + i]
  else:
    for i in 0 ..< count:
      let value = src[srcBase + i]
      dest[destBase + i + wordShift] =
        dest[destBase + i + wordShift] or (value shl bitShift)
      if destBase + i + wordShift + 1 < dest.len:
        dest[destBase + i + wordShift + 1] =
          dest[destBase + i + wordShift + 1] or (value shr (64 - bitShift))
```

`bitIsSet` extracts one offset from a word. `orShiftedAt` handles both whole-word and partial-word shifts, keeping the diagonal alignment exact.

**Input.** The program reads both grids for every test case.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = nextInteger(inputData, i)
var keyCells = ""
var lockCells = ""
var outputBuffer = ""

for j in 0 ..< caseCount:
  let keyRows = nextInteger(inputData, i)
  let keyCols = nextInteger(inputData, i)
  keyCells.setLen(keyRows * keyCols)
  for k in 0 ..< keyRows:
    readGridRow(inputData, i, keyCells, k * keyCols, keyCols)
  let lockDepth = nextInteger(inputData, i)
  let lockWidth = nextInteger(inputData, i)
  lockCells.setLen(lockDepth * lockWidth)
  for k in 0 ..< lockDepth:
    readGridRow(inputData, i, lockCells, k * lockWidth, lockWidth)
```

`keyCells` and `lockCells` hold one character per cell. A key wider than the lock skips the simulation entirely and reports depth 0.

**Failure masks.** Each key row contributes blocked diagonals for every offset.

```nim
  var answerDepth = 0
  var fellThrough = false

  if keyCols <= lockWidth:
    let offsetCount = lockWidth - keyCols + 1
    let rowWords = (lockDepth + 63) div 64
    let diagonalBase = keyRows - 1
    let diagonalWords = rowWords + ((keyRows + 63) div 64) + 1

    var blockedCol = newSeq[uint64](lockWidth * rowWords)
    for k in 0 ..< lockWidth:
      let columnBase = k * rowWords
      for l in 0 ..< lockDepth:
        if lockCells[l * lockWidth + k] == '#':
          blockedCol[columnBase + (l shr 6)] =
            blockedCol[columnBase + (l shr 6)] or (1'u64 shl (l and 63))

    var diagonalFail = newSeq[uint64](offsetCount * diagonalWords)
    var failRows = newSeq[uint64](rowWords)
    var woodStart = newSeq[int](keyRows + 1)
    var woodCols = newSeq[int](0)
    for k in 0 ..< keyRows:
      woodStart[k] = woodCols.len
      for l in 0 ..< keyCols:
        if keyCells[k * keyCols + l] == '#':
          woodCols.add l
    woodStart[keyRows] = woodCols.len

    for k in 0 ..< keyRows:
      let shiftAmount = diagonalBase - k
      let wordShift = shiftAmount shr 6
      let bitShift = shiftAmount and 63
      for l in 0 ..< offsetCount:
        clearBits(failRows)
        for i in woodStart[k] ..< woodStart[k + 1]:
          let columnBase = (l + woodCols[i]) * rowWords
          orWordsAt(failRows, 0, blockedCol, columnBase, rowWords)
        let diagonalBaseIndex = l * diagonalWords
        orShiftedAt(diagonalFail, diagonalBaseIndex, failRows, 0,
                    rowWords, wordShift, bitShift)
```

`blockedCol` packs each lock column into words. `woodStart` and `woodCols` list only the wooden columns of a key row. `orShiftedAt` places those blocked columns onto the right diagonal for each offset.

**Reachability sweep.** Each depth row updates the set of live offsets.

```nim
    let wordCount = (offsetCount + 63) div 64
    var previousReach = newSeq[uint64](wordCount)
    var currentValid = newSeq[uint64](wordCount)
    var candidates = newSeq[uint64](wordCount)
    var nextReach = newSeq[uint64](wordCount)
    for k in 0 ..< offsetCount:
      setBit(previousReach, k)

    let finalDepth = lockDepth + keyRows
    var stopped = false
    for k in 1 .. finalDepth:
      let topPosition = k - keyRows
      let diagonalIndex = topPosition + diagonalBase
      clearBits(currentValid)
      for l in 0 ..< offsetCount:
        if not bitIsSet(diagonalFail, l * diagonalWords * 64 + diagonalIndex):
          setBit(currentValid, l)

      copyBits(candidates, previousReach)
      intersectBits(candidates, currentValid)
      clearBits(nextReach)
      var l = 0
      while l < offsetCount:
        if not bitIsSet(currentValid, l):
          l += 1
        else:
          let runStart = l
          var runHasCandidate = bitIsSet(candidates, l)
          l += 1
          while l < offsetCount and bitIsSet(currentValid, l):
            if bitIsSet(candidates, l):
              runHasCandidate = true
            l += 1
          if runHasCandidate:
            for i in runStart ..< l:
              setBit(nextReach, i)

      var hasReach = false
      for i in 0 ..< wordCount:
        if nextReach[i] != 0'u64:
          hasReach = true
          break
      if not hasReach:
        answerDepth = k - 1
        stopped = true
        break
      copyBits(previousReach, nextReach)
```

`currentValid` copies offsets that meet no wood. Intersecting with `previousReach` keeps only offsets reachable from above. Each contiguous run containing a candidate becomes reachable for the next row.

**Output.** The final verdict prints one sentence.

```nim
    if not stopped:
      fellThrough = true

  if fellThrough:
    outputBuffer.add "The key can fall through.\n"
  else:
    outputBuffer.add "The key falls to depth "
    outputBuffer.add $answerDepth
    outputBuffer.add ".\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

`stopped` means some row blocked every offset. The answer depth is the last row the key reached. Output flushes at 256 KiB blocks.

## Complexity

Each case packs bitsets, builds fail masks, then sweeps depth once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Blocked columns | O(W × D / 64) word writes | O(W × D / 64) |
| Fail masks | O(R × offsets × rowWords) | O(offsets × diagonals) |
| Reachability sweep | O((D + R) × offsetWords) | O(offsetWords) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O((D + R) × W × R / 64) word ops | O(W × D / 64 + W × R / 64) |

A word covers 64 offsets, so the wide lock costs little.

| Measure | Big O |
|---|---|
| Time | O((D + R) × ceil(W / 64) × ceil(R / 64 + 1)) word ops |
| Space | O(W × D / 64 + W × R / 64) words |

The bit-parallel factor is what keeps the 1000 ms limit comfortable.

Testing every cell at every offset and depth would cost `R × D × W` per case. Bitset words divide that by 64.
