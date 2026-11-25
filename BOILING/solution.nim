const flushBlockBytes = 1 shl 17
const maximumCuts = 500

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextThreshold(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - 48
    pos += 1
  var fractionPart = 0
  var fractionDigits = 0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9' and fractionDigits < 2:
      fractionPart = fractionPart * 10 + int(data[pos]) - 48
      pos += 1
      fractionDigits += 1
  while fractionDigits < 2:
    fractionPart = fractionPart * 10
    fractionDigits += 1
  return wholePart * 100 + fractionPart

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let thresholdHundredths = nextThreshold(inputData, scanPos)
let pieceCount = nextInt(inputData, scanPos)
var pieceWeights = newSeq[int](pieceCount)
for pieceIndex in 0 .. pieceCount - 1:
  pieceWeights[pieceIndex] = nextInt(inputData, scanPos)
var bestCuts = maximumCuts
for pivotIndex in 0 .. pieceCount - 1:
  let pivotWeight = pieceWeights[pivotIndex]
  for pieceTarget in 1 .. maximumCuts:
    var requiredCuts: int64 = 0
    var feasible = true
    for otherIndex in 0 .. pieceCount - 1:
      let otherWeight = pieceWeights[otherIndex]
      let fewestPieces = (int64(pieceTarget) * int64(otherWeight) + int64(pivotWeight) - 1) div int64(pivotWeight)
      let mostPieces = (100 * int64(pieceTarget) * int64(otherWeight) - 1) div (int64(thresholdHundredths) * int64(pivotWeight))
      if fewestPieces > mostPieces:
        feasible = false
        break
      requiredCuts = requiredCuts + fewestPieces - 1
      if requiredCuts >= int64(bestCuts):
        break
    if feasible and requiredCuts < int64(bestCuts):
      bestCuts = int(requiredCuts)
appendOutput($bestCuts)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
