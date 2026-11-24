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
