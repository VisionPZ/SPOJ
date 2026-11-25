const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hashBits = 17
const hashSize = 1 shl hashBits
const hashMask = hashSize - 1
const hashShift = 32 - hashBits
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
  return int(((int64(value) * hashMultiplier) shr hashShift) and int64(hashMask))

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

var goodSums = newSeq[int](maxSum + 1)
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
  let rangeLow = nextInt(inputData, scanPos) + 1
  let rangeHigh = nextInt(inputData, scanPos) - 1
  var pairCount = 0
  if rangeLow < rangeHigh:
    currentStamp += 1
    let productStamp = currentStamp
    for x in rangeLow..rangeHigh:
      for y in x + 1..rangeHigh:
        discard bumpCount(x * y, productStamp)
    let sumLow = 2 * rangeLow + 1
    let sumHigh = 2 * rangeHigh - 1
    var goodSumCount = 0
    for s in sumLow..sumHigh:
      let loX = max(rangeLow, s - rangeHigh)
      let hiX = (s - 1) div 2
      if hiX - loX + 1 < 2:
        continue
      var allAmbiguous = true
      for x in loX..hiX:
        if lookupCount(x * (s - x), productStamp) == 1:
          allAmbiguous = false
          break
      if allAmbiguous:
        goodSums[goodSumCount] = s
        goodSumCount += 1
    if goodSumCount > 0:
      currentStamp += 1
      let winnerStamp = currentStamp
      for i in 0..<goodSumCount:
        let s = goodSums[i]
        let loX = max(rangeLow, s - rangeHigh)
        let hiX = (s - 1) div 2
        for x in loX..hiX:
          discard bumpCount(x * (s - x), winnerStamp)
      for i in 0..<goodSumCount:
        let s = goodSums[i]
        let loX = max(rangeLow, s - rangeHigh)
        let hiX = (s - 1) div 2
        var uniqueCount = 0
        var bestLow = 0
        var bestHigh = 0
        for x in loX..hiX:
          if lookupCount(x * (s - x), winnerStamp) == 1:
            uniqueCount += 1
            bestLow = x
            bestHigh = s - x
            if uniqueCount > 1:
              break
        if uniqueCount == 1:
          winnerLow[pairCount] = bestLow
          winnerHigh[pairCount] = bestHigh
          pairCount += 1
  appendOutput("case " & $caseIndex)
  outputBuffer.add '\n'
  appendOutput($pairCount)
  outputBuffer.add '\n'
  for i in 0..<pairCount:
    appendOutput($(winnerLow[i]) & " " & $(winnerHigh[i]))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
