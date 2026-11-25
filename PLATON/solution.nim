const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hashBits = 17
const hashSize = 1 shl hashBits
const hashMask = hashSize - 1
const hashMultiplier = 2654435761'i64
const maxSum = 10000

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var hashKeys = newSeq[int](hashSize)
var hashValues = newSeq[int](hashSize)
var hashStamps = newSeq[int](hashSize)
var currentStamp = 0

proc hashSlot(value: int): int =
  return int((int64(value) * hashMultiplier shr 32) and int64(hashMask))

proc bumpCount(value: int, stamp: int): int =
  var at = hashSlot(value)
  while true:
    if hashStamps[at] != stamp:
      hashStamps[at] = stamp
      hashKeys[at] = value
      hashValues[at] = 1
      return 1
    if hashKeys[at] == value:
      hashValues[at] += 1
      return hashValues[at]
    at = (at + 1) and hashMask

proc lookupCount(value: int, stamp: int): int =
  var at = hashSlot(value)
  while true:
    if hashStamps[at] != stamp: return 0
    if hashKeys[at] == value: return hashValues[at]
    at = (at + 1) and hashMask

var sumSplitCount = newSeq[int](maxSum + 1)
var sumBadCount = newSeq[int](maxSum + 1)
var sumWinnerCount = newSeq[int](maxSum + 1)
var winnerLow = newSeq[int](maxSum + 1)
var winnerHigh = newSeq[int](maxSum + 1)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let rangeLow = nextInt(inputData, scanPos)
  let rangeHigh = nextInt(inputData, scanPos)
  let sumLow = 2 * rangeLow + 1
  let sumHigh = 2 * rangeHigh - 1
  for s in sumLow..sumHigh:
    sumSplitCount[s] = 0
    sumBadCount[s] = 0
    sumWinnerCount[s] = 0
  currentStamp += 1
  let productStamp = currentStamp
  for x in rangeLow..rangeHigh:
    for y in x + 1..rangeHigh:
      discard bumpCount(x * y, productStamp)
  for x in rangeLow..rangeHigh:
    for y in x + 1..rangeHigh:
      let total = x + y
      sumSplitCount[total] += 1
      if lookupCount(x * y, productStamp) == 1:
        sumBadCount[total] += 1
  currentStamp += 1
  let winnerStamp = currentStamp
  for x in rangeLow..rangeHigh:
    for y in x + 1..rangeHigh:
      let total = x + y
      if sumSplitCount[total] > 1 and sumBadCount[total] == 0:
        discard bumpCount(x * y, winnerStamp)
  for x in rangeLow..rangeHigh:
    for y in x + 1..rangeHigh:
      let total = x + y
      if sumSplitCount[total] > 1 and sumBadCount[total] == 0 and lookupCount(x * y, winnerStamp) == 1:
        sumWinnerCount[total] += 1
        winnerLow[total] = x
        winnerHigh[total] = y
  var pairCount = 0
  for s in sumLow..sumHigh:
    if sumSplitCount[s] > 1 and sumBadCount[s] == 0 and sumWinnerCount[s] == 1:
      pairCount += 1
  appendOutput("case " & $caseIndex)
  outputBuffer.add '\n'
  appendOutput($pairCount)
  outputBuffer.add '\n'
  for s in sumLow..sumHigh:
    if sumSplitCount[s] > 1 and sumBadCount[s] == 0 and sumWinnerCount[s] == 1:
      appendOutput($(winnerLow[s]) & " " & $(winnerHigh[s]))
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
