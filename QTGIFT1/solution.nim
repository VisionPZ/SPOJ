const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const hugeValue = int64(1 shl 60)

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let packCount = nextInt(inputData, scanPos)
let skipLength = nextInt(inputData, scanPos)
var candidateIndex = newSeq[int](packCount)
var candidateCost = newSeq[int64](packCount)
var headIndex = 0
var tailIndex = 0
var totalSum: int64 = 0
var minFinalCost: int64 = hugeValue
let lastFirstSkip = skipLength - 1
let firstFinalSkip = packCount - skipLength
for packIndex in 0 .. packCount - 1:
  let packValue = int64(nextInt(inputData, scanPos))
  totalSum = totalSum + packValue
  while headIndex < tailIndex and candidateIndex[headIndex] < packIndex - skipLength:
    headIndex += 1
  var bestPrevious: int64 = hugeValue
  if packIndex <= lastFirstSkip:
    bestPrevious = 0
  if headIndex < tailIndex and candidateCost[headIndex] < bestPrevious:
    bestPrevious = candidateCost[headIndex]
  let currentCost = packValue + bestPrevious
  while tailIndex > headIndex and candidateCost[tailIndex - 1] >= currentCost:
    tailIndex -= 1
  candidateIndex[tailIndex] = packIndex
  candidateCost[tailIndex] = currentCost
  tailIndex += 1
  if packIndex >= firstFinalSkip and currentCost < minFinalCost:
    minFinalCost = currentCost
let bestMoney = totalSum - minFinalCost
appendOutput($bestMoney)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
