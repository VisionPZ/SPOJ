## Problem

Read T test cases. Each case gives a key and a lock. The key is an R by C grid of '#' wood and '.' holes. The lock is a D by W grid of '#' wood and '.' free cells. The key falls down and slides left or right, but never turns. Print the deepest depth it reaches, or say that it falls through. Depth counts rows from the lock top down to the key bottom.

| Value | Range |
| --- | --- |
| R, C | 1 to 100 |
| D | 1 to 10000 |
| W | 1 to 1000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

One case can hold ten million lock cells, so the program scans those cells only a few times.

## Idea

Mark the blocked depths first, then walk them with a reachability pass. At depth X, key row r sits in lock row X - R + r. That pair depends only on the difference l - r, called the diagonal. An offset is the number of columns the key shifts right, from 0 to W - C. For each offset, build one bit set over diagonals. A bit is set when any wood column of a key row meets wood in the matching lock row. Depth X then needs one bit read.

A pass over depths tracks which offsets stay reachable. After each step, every run of side-by-side valid offsets becomes reachable at once.

Marking costs one word operation per wood column, per offset, per key row. The depth pass costs one bit read per depth and offset.

## Why It Works

A key row r at depth X meets lock row l = X - R + r. Rearrange this to X = l - r + R. The pair (r, l) fixes the depth, so only l - r matters. One diagonal bit per offset covers every depth.

A key row fits a lock row when each wood column lands on a free cell. For one offset, the blocked lock rows are the union of the rows where those lock columns hold wood. The program stores one bit set per lock column and ORs the sets of the wood columns.

The shift by R - 1 - r moves row l to diagonal index l - r + R - 1. That index equals X - 1. So depth X reads bit X - 1.

Sliding is free between side-by-side valid offsets, since each offset in the run avoids wood. If one offset in a run is reachable, the whole run is reachable. The key falls through when an offset stays reachable down to depth D + R.

The sample key has rows "#.##" and "###.". The sample lock has rows "#....#", "#....#", and "#..###". The three offsets give these diagonal bits, one column per depth from 1 to 5.

| offset | depths 1 to 5 |
| --- | --- |
| 0 | 11110 |
| 1 | 00110 |
| 2 | 01110 |

A one marks a blocked depth. The depth pass reads those bits and closes reachable runs after each step.

| depth | valid offsets | reachable offsets |
| --- | --- | --- |
| 1 | 011 | 011 |
| 2 | 010 | 010 |
| 3 | 000 | 000 |

Reachability becomes empty at depth 3, so the answer is 2.

## Code

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

proc readGridRow(inputData: string, i: var int, cells: var string, cellOffset: int, rowWidth: int) =
  skipWhitespace(inputData, i)
  for j in 0 ..< rowWidth:
    cells[cellOffset + j] = inputData[i + j]
  i += rowWidth
```

The scanner walks one buffer and allocates no tokens. The row reader copies exactly rowWidth cells. Both loops stop at the buffer end.

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

Each bit set is a sequence of 64-bit words. The shifted OR carries overflow into the next word. Every operation works on whole words.

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
```

One bit set per lock column records where that column holds wood. The wood columns of each key row are collected once. The row loops run keyRows and lockDepth times.

```nim
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

The outer loop runs keyRows times and the inner loop runs offsetCount times. The shift maps a lock row to its diagonal. The OR merges all wood columns of the row.

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

    if not stopped:
      fellThrough = true
```

The depth loop runs lockDepth + keyRows times. One bit per offset tells whether the key fits. The run scan closes over all side-by-side offsets. An empty nextReach ends the search.

```nim
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

The answer prints as one line per case. The buffer flushes every flushBlockBytes bytes. The final write emits any remainder.

## Complexity

Building column bit sets costs O(D · W). Marking diagonals costs one word operation per wood column, per offset, per key row. The depth pass costs one bit read per depth and offset.

Total time is O(D · W + R · C · W · D / 64 + (D + R) · W). Column bit sets use O(W · D / 64) words. Diagonal fail sets use O((W - C + 1) · (D + R) / 64) words.

A naive check compares every key cell with every lock cell at every offset and depth. That costs O(D · W · R · C) and is much slower.
