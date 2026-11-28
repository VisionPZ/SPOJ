const flushBlockBytes = 1 shl 17
const bitWidth = 31

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc segmentCost(leftIndex: int, rightIndex: int, prefixStride: int, onePrefix: seq[int64]): int64 =
  let segmentLength = int64(rightIndex - leftIndex)
  var totalCost: int64 = 0
  for bitIndex in 0 .. bitWidth - 1:
    let prefixBase = bitIndex * prefixStride
    let onesCount = onePrefix[prefixBase + rightIndex] - onePrefix[prefixBase + leftIndex]
    let zerosCount = segmentLength - onesCount
    totalCost = totalCost + (int64(1) shl bitIndex) * onesCount * zerosCount
  return totalCost

let bloomCount = nextInt(inputData, scanPos)
let separatorCount = nextInt(inputData, scanPos)
var bloomValues = newSeq[int64](bloomCount)
for valueIndex in 0 .. bloomCount - 1:
  bloomValues[valueIndex] = int64(nextInt(inputData, scanPos))

let prefixStride = bloomCount + 1
var onePrefix = newSeq[int64](bitWidth * prefixStride)
for bitIndex in 0 .. bitWidth - 1:
  let prefixBase = bitIndex * prefixStride
  for valueIndex in 0 .. bloomCount - 1:
    let oneBit = if ((bloomValues[valueIndex] shr bitIndex) and int64(1)) != 0: int64(1) else: int64(0)
    onePrefix[prefixBase + valueIndex + 1] = onePrefix[prefixBase + valueIndex] + oneBit

let infiniteCost = int64(1) shl 62
var previousCosts = newSeq[int64](bloomCount + 1)
var currentCosts = newSeq[int64](bloomCount + 1)
for rightIndex in 1 .. bloomCount:
  previousCosts[rightIndex] = segmentCost(0, rightIndex, prefixStride, onePrefix)

for segmentIndex in 2 .. separatorCount + 1:
  for rightIndex in 0 .. bloomCount:
    currentCosts[rightIndex] = infiniteCost
  for rightIndex in segmentIndex .. bloomCount:
    var bestCost = infiniteCost
    for splitIndex in segmentIndex - 1 .. rightIndex - 1:
      let candidateCost = previousCosts[splitIndex] + segmentCost(splitIndex, rightIndex, prefixStride, onePrefix)
      if candidateCost < bestCost:
        bestCost = candidateCost
    currentCosts[rightIndex] = bestCost
  for rightIndex in 0 .. bloomCount:
    let carriedCost = currentCosts[rightIndex]
    currentCosts[rightIndex] = previousCosts[rightIndex]
    previousCosts[rightIndex] = carriedCost

appendOutput($previousCosts[bloomCount])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
