import algorithm

const flushBlockBytes = 1 shl 17

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

proc compareAscending(leftValue: int64, rightValue: int64): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

proc compareDescending(leftValue: int64, rightValue: int64): int =
  return compareAscending(rightValue, leftValue)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let classCount = nextInt(inputData, scanPos)
  if classCount == 0:
    break
  var classSizes = newSeq[int64](classCount)
  var candyPrices = newSeq[int64](classCount)
  for indexValue in 0 .. classCount - 1:
    classSizes[indexValue] = int64(nextInt(inputData, scanPos))
  for indexValue in 0 .. classCount - 1:
    candyPrices[indexValue] = int64(nextInt(inputData, scanPos))
  classSizes.sort(compareAscending)
  candyPrices.sort(compareDescending)
  var totalCost: int64 = 0
  for indexValue in 0 .. classCount - 1:
    totalCost = totalCost + classSizes[indexValue] * candyPrices[indexValue]
  appendOutput($totalCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
