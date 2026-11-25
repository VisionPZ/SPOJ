import algorithm

const flushBlockBytes = 1 shl 17
const modulus: int64 = 1000000007

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

let testCount = nextInt(inputData, scanPos)
var querySizes = newSeq[int](testCount)
var queryLimits = newSeq[int](testCount)
var largestSize = 0
var largestLimit = 0
for testIndex in 0 .. testCount - 1:
  querySizes[testIndex] = nextInt(inputData, scanPos)
  queryLimits[testIndex] = nextInt(inputData, scanPos)
  if querySizes[testIndex] > largestSize:
    largestSize = querySizes[testIndex]
  if queryLimits[testIndex] > largestLimit:
    largestLimit = queryLimits[testIndex]

var queryOrder = newSeq[int](testCount)
for testIndex in 0 .. testCount - 1:
  queryOrder[testIndex] = testIndex
queryOrder.sort(proc(leftIndex, rightIndex: int): int =
  if querySizes[leftIndex] < querySizes[rightIndex]:
    return -1
  if querySizes[leftIndex] > querySizes[rightIndex]:
    return 1
  return 0)

var partitionCounts = newSeq[int64](largestLimit + 1)
partitionCounts[0] = 1
var cumulativeCounts = newSeq[int64](largestLimit + 1)
var answers = newSeq[int](testCount)
var orderPosition = 0

for partCount in 1 .. largestSize:
  for sumValue in partCount .. largestLimit:
    partitionCounts[sumValue] = (partitionCounts[sumValue] + partitionCounts[sumValue - partCount]) mod modulus
  cumulativeCounts[0] = partitionCounts[0]
  for sumValue in 1 .. largestLimit:
    cumulativeCounts[sumValue] = (cumulativeCounts[sumValue - 1] + partitionCounts[sumValue]) mod modulus
  while orderPosition < testCount and querySizes[queryOrder[orderPosition]] == partCount:
    let queryIndex = queryOrder[orderPosition]
    let spareSum = queryLimits[queryIndex] - partCount * (partCount + 1) div 2
    if spareSum < 0:
      answers[queryIndex] = 0
    else:
      answers[queryIndex] = int(cumulativeCounts[spareSum])
    orderPosition += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for testIndex in 0 .. testCount - 1:
  appendOutput($(answers[testIndex]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
