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

proc skipWhitespace(inputData: string, scanPos: var int) =
  while scanPos < inputData.len and ord(inputData[scanPos]) <= 32:
    scanPos += 1

proc nextInteger(inputData: string, scanPos: var int): int =
  skipWhitespace(inputData, scanPos)
  result = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    result = result * 10 + (ord(inputData[scanPos]) - firstDigitValue)
    scanPos += 1

proc readGridRow(inputData: string, scanPos: var int, cells: var string, cellOffset: int, rowWidth: int) =
  skipWhitespace(inputData, scanPos)
  for col in 0 ..< rowWidth:
    cells[cellOffset + col] = inputData[scanPos + col]
  scanPos += rowWidth
```

The scanner walks one buffer and allocates no tokens. The row reader copies exactly rowWidth cells. Both loops stop at the buffer end.

```nim
proc bitIsSet(bits: seq[uint64], bitIndex: int): bool =
  (bits[bitIndex shr 6] and (1'u64 shl (bitIndex and 63))) != 0'u64

proc setBit(bits: var seq[uint64], bitIndex: int) =
  bits[bitIndex shr 6] = bits[bitIndex shr 6] or (1'u64 shl (bitIndex and 63))

proc clearBits(bits: var seq[uint64]) =
  for wordIndex in 0 ..< bits.len:
    bits[wordIndex] = 0'u64

proc copyBits(dest: var seq[uint64], src: seq[uint64]) =
  for wordIndex in 0 ..< dest.len:
    dest[wordIndex] = src[wordIndex]

proc intersectBits(dest: var seq[uint64], src: seq[uint64]) =
  for wordIndex in 0 ..< dest.len:
    dest[wordIndex] = dest[wordIndex] and src[wordIndex]

proc orWordsAt(dest: var seq[uint64], destBase: int, src: seq[uint64], srcBase: int, count: int) =
  for wordIndex in 0 ..< count:
    dest[destBase + wordIndex] = dest[destBase + wordIndex] or src[srcBase + wordIndex]

proc orShiftedAt(dest: var seq[uint64], destBase: int, src: seq[uint64], srcBase: int,
                 count: int, wordShift: int, bitShift: int) =
  if bitShift == 0:
    for wordIndex in 0 ..< count:
      dest[destBase + wordIndex + wordShift] =
        dest[destBase + wordIndex + wordShift] or src[srcBase + wordIndex]
  else:
    for wordIndex in 0 ..< count:
      let value = src[srcBase + wordIndex]
      dest[destBase + wordIndex + wordShift] =
        dest[destBase + wordIndex + wordShift] or (value shl bitShift)
      if destBase + wordIndex + wordShift + 1 < dest.len:
        dest[destBase + wordIndex + wordShift + 1] =
          dest[destBase + wordIndex + wordShift + 1] or (value shr (64 - bitShift))
```

Each bit set is a sequence of 64-bit words. The shifted OR carries overflow into the next word. Every operation works on whole words.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInteger(inputData, scanPos)
var keyCells = ""
var lockCells = ""
var outputBuffer = ""

for caseIndex in 0 ..< caseCount:
  let keyRows = nextInteger(inputData, scanPos)
  let keyCols = nextInteger(inputData, scanPos)
  keyCells.setLen(keyRows * keyCols)
  for rowIndex in 0 ..< keyRows:
    readGridRow(inputData, scanPos, keyCells, rowIndex * keyCols, keyCols)
  let lockDepth = nextInteger(inputData, scanPos)
  let lockWidth = nextInteger(inputData, scanPos)
  lockCells.setLen(lockDepth * lockWidth)
  for rowIndex in 0 ..< lockDepth:
    readGridRow(inputData, scanPos, lockCells, rowIndex * lockWidth, lockWidth)

  var answerDepth = 0
  var fellThrough = false

  if keyCols <= lockWidth:
    let offsetCount = lockWidth - keyCols + 1
    let rowWords = (lockDepth + 63) div 64
    let diagonalBase = keyRows - 1
    let diagonalWords = rowWords + ((keyRows + 63) div 64) + 1

    var blockedCol = newSeq[uint64](lockWidth * rowWords)
    for col in 0 ..< lockWidth:
      let columnBase = col * rowWords
      for rowIndex in 0 ..< lockDepth:
        if lockCells[rowIndex * lockWidth + col] == '#':
          blockedCol[columnBase + (rowIndex shr 6)] =
            blockedCol[columnBase + (rowIndex shr 6)] or (1'u64 shl (rowIndex and 63))

    var diagonalFail = newSeq[uint64](offsetCount * diagonalWords)
    var failRows = newSeq[uint64](rowWords)
    var woodStart = newSeq[int](keyRows + 1)
    var woodCols = newSeq[int](0)
    for rowIndex in 0 ..< keyRows:
      woodStart[rowIndex] = woodCols.len
      for col in 0 ..< keyCols:
        if keyCells[rowIndex * keyCols + col] == '#':
          woodCols.add col
    woodStart[keyRows] = woodCols.len
```

One bit set per lock column records where that column holds wood. The wood columns of each key row are collected once. The row loops run keyRows and lockDepth times.

```nim
    for rowIndex in 0 ..< keyRows:
      let shiftAmount = diagonalBase - rowIndex
      let wordShift = shiftAmount shr 6
      let bitShift = shiftAmount and 63
      for offset in 0 ..< offsetCount:
        clearBits(failRows)
        for colIndex in woodStart[rowIndex] ..< woodStart[rowIndex + 1]:
          let columnBase = (offset + woodCols[colIndex]) * rowWords
          orWordsAt(failRows, 0, blockedCol, columnBase, rowWords)
        let diagonalBaseIndex = offset * diagonalWords
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
    for offset in 0 ..< offsetCount:
      setBit(previousReach, offset)

    let finalDepth = lockDepth + keyRows
    var stopped = false
    for depth in 1 .. finalDepth:
      let topPosition = depth - keyRows
      let diagonalIndex = topPosition + diagonalBase
      clearBits(currentValid)
      for offset in 0 ..< offsetCount:
        if not bitIsSet(diagonalFail, offset * diagonalWords * 64 + diagonalIndex):
          setBit(currentValid, offset)

      copyBits(candidates, previousReach)
      intersectBits(candidates, currentValid)
      clearBits(nextReach)
      var scanOffset = 0
      while scanOffset < offsetCount:
        if not bitIsSet(currentValid, scanOffset):
          scanOffset += 1
        else:
          let runStart = scanOffset
          var runHasCandidate = bitIsSet(candidates, scanOffset)
          scanOffset += 1
          while scanOffset < offsetCount and bitIsSet(currentValid, scanOffset):
            if bitIsSet(candidates, scanOffset):
              runHasCandidate = true
            scanOffset += 1
          if runHasCandidate:
            for bitIndex in runStart ..< scanOffset:
              setBit(nextReach, bitIndex)

      var hasReach = false
      for wordIndex in 0 ..< wordCount:
        if nextReach[wordIndex] != 0'u64:
          hasReach = true
          break
      if not hasReach:
        answerDepth = depth - 1
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
