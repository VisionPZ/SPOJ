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
