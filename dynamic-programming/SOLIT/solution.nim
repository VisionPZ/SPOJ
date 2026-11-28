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
