const valueRange = 1000
const wordBits = 64
const maxWords = 32
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos = scanPos + 1
  return value

proc countSetBits(value: uint64): int =
  var bits = value
  bits = bits - ((bits shr 1) and 0x5555555555555555'u64)
  bits = (bits and 0x3333333333333333'u64) + ((bits shr 2) and 0x3333333333333333'u64)
  bits = (bits + (bits shr 4)) and 0x0f0f0f0f0f0f0f0f'u64
  return int((bits * 0x0101010101010101'u64) shr 56)

proc lcsLength(agnesRoute: seq[int], matchMask: seq[uint64], wordCount: int, stateBits: var seq[uint64], shiftedBits: var seq[uint64], differenceBits: var seq[uint64]): int =
  for wordIndex in 0 ..< wordCount:
    stateBits[wordIndex] = 0'u64
  for checkpoint in agnesRoute:
    let maskBase = checkpoint * maxWords
    var shiftCarry = 0'u64
    for wordIndex in 0 ..< wordCount:
      let stateWord = stateBits[wordIndex]
      shiftedBits[wordIndex] = (stateWord shl 1) or shiftCarry
      shiftCarry = stateWord shr (wordBits - 1)
    shiftedBits[0] = shiftedBits[0] or 1'u64
    var borrow = 0'u64
    for wordIndex in 0 ..< wordCount:
      let leftWord = stateBits[wordIndex] or matchMask[maskBase + wordIndex]
      let shiftedWord = shiftedBits[wordIndex]
      let partial = leftWord - borrow
      let firstBorrow = leftWord < borrow
      let differenceWord = partial - shiftedWord
      let secondBorrow = partial < shiftedWord
      borrow = (if firstBorrow or secondBorrow: 1'u64 else: 0'u64)
      stateBits[wordIndex] = leftWord and (not differenceWord)
  var total = 0
  for wordIndex in 0 ..< wordCount:
    total = total + countSetBits(stateBits[wordIndex])
  return total

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)

var stateBits = newSeq[uint64](maxWords)
var shiftedBits = newSeq[uint64](maxWords)
var differenceBits = newSeq[uint64](maxWords)
var matchMask = newSeq[uint64]((valueRange + 1) * maxWords)
var agnesRoute: seq[int] = @[]
var tomRoute: seq[int] = @[]
var outputBuffer: string

for caseIndex in 1 .. caseCount:
  agnesRoute.setLen 0
  while true:
    let checkpoint = nextInt(inputData, scanPos)
    if checkpoint == 0: break
    agnesRoute.add checkpoint
  var bestScore = 0
  while true:
    let firstValue = nextInt(inputData, scanPos)
    if firstValue == 0: break
    tomRoute.setLen 0
    tomRoute.add firstValue
    while true:
      let checkpoint = nextInt(inputData, scanPos)
      if checkpoint == 0: break
      tomRoute.add checkpoint
    let checkpointCount = tomRoute.len
    let wordCount = (checkpointCount + wordBits - 1) div wordBits
    for valueIndex in 0 .. valueRange:
      let maskBase = valueIndex * maxWords
      for wordIndex in 0 ..< wordCount:
        matchMask[maskBase + wordIndex] = 0'u64
    for positionIndex in 0 ..< checkpointCount:
      let maskBase = tomRoute[positionIndex] * maxWords
      let wordIndex = positionIndex div wordBits
      matchMask[maskBase + wordIndex] = matchMask[maskBase + wordIndex] or (1'u64 shl (positionIndex mod wordBits))
    let score = lcsLength(agnesRoute, matchMask, wordCount, stateBits, shiftedBits, differenceBits)
    if score > bestScore: bestScore = score
  outputBuffer.add $bestScore
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
