const valueRange = 1000
const wordBits = 64
const maxWords = 32
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i = i + 1
  return value

proc countSetBits(value: uint64): int =
  var bits = value
  bits = bits - ((bits shr 1) and 0x5555555555555555'u64)
  bits = (bits and 0x3333333333333333'u64) + ((bits shr 2) and 0x3333333333333333'u64)
  bits = (bits + (bits shr 4)) and 0x0f0f0f0f0f0f0f0f'u64
  return int((bits * 0x0101010101010101'u64) shr 56)

proc lcsLength(agnesRoute: seq[int], matchMask: seq[uint64], wordCount: int, stateBits: var seq[uint64], shiftedBits: var seq[uint64], differenceBits: var seq[uint64]): int =
  for l in 0 ..< wordCount:
    stateBits[l] = 0'u64
  for checkpoint in agnesRoute:
    let maskBase = checkpoint * maxWords
    var shiftCarry = 0'u64
    for l in 0 ..< wordCount:
      let stateWord = stateBits[l]
      shiftedBits[l] = (stateWord shl 1) or shiftCarry
      shiftCarry = stateWord shr (wordBits - 1)
    shiftedBits[0] = shiftedBits[0] or 1'u64
    var borrow = 0'u64
    for l in 0 ..< wordCount:
      let leftWord = stateBits[l] or matchMask[maskBase + l]
      let shiftedWord = shiftedBits[l]
      let partial = leftWord - borrow
      let firstBorrow = leftWord < borrow
      let differenceWord = partial - shiftedWord
      let secondBorrow = partial < shiftedWord
      borrow = (if firstBorrow or secondBorrow: 1'u64 else: 0'u64)
      stateBits[l] = leftWord and (not differenceWord)
  var total = 0
  for l in 0 ..< wordCount:
    total = total + countSetBits(stateBits[l])
  return total

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
let caseCount = nextInt(inputData, i)

var stateBits = newSeq[uint64](maxWords)
var shiftedBits = newSeq[uint64](maxWords)
var differenceBits = newSeq[uint64](maxWords)
var matchMask = newSeq[uint64]((valueRange + 1) * maxWords)
var agnesRoute: seq[int] = @[]
var tomRoute: seq[int] = @[]
var outputBuffer: string

for j in 1 .. caseCount:
  agnesRoute.setLen 0
  while true:
    let checkpoint = nextInt(inputData, i)
    if checkpoint == 0: break
    agnesRoute.add checkpoint
  var bestScore = 0
  while true:
    let firstValue = nextInt(inputData, i)
    if firstValue == 0: break
    tomRoute.setLen 0
    tomRoute.add firstValue
    while true:
      let checkpoint = nextInt(inputData, i)
      if checkpoint == 0: break
      tomRoute.add checkpoint
    let checkpointCount = tomRoute.len
    let wordCount = (checkpointCount + wordBits - 1) div wordBits
    for k in 0 .. valueRange:
      let maskBase = k * maxWords
      for l in 0 ..< wordCount:
        matchMask[maskBase + l] = 0'u64
    for k in 0 ..< checkpointCount:
      let maskBase = tomRoute[k] * maxWords
      let l = k div wordBits
      matchMask[maskBase + l] = matchMask[maskBase + l] or (1'u64 shl (k mod wordBits))
    let score = lcsLength(agnesRoute, matchMask, wordCount, stateBits, shiftedBits, differenceBits)
    if score > bestScore: bestScore = score
  outputBuffer.add $bestScore
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
