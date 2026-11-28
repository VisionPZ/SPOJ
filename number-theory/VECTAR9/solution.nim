const flushBlockBytes = 1 shl 17
const periodValue: int64 = 304250263527210
const periodCount: int64 = 260105476071210
const basePrimes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]
const searchMargin: int64 = 40000

var subsetProducts: array[0 .. 8191, int64]
var subsetSigns: array[0 .. 8191, int]
subsetProducts[0] = 1
subsetSigns[0] = -1
for mask in 1 .. 8191:
  var lowestBit = 1
  var bitIndex = 0
  while (mask and lowestBit) == 0:
    lowestBit = lowestBit shl 1
    bitIndex += 1
  let previousMask = mask - lowestBit
  subsetProducts[mask] = subsetProducts[previousMask] * int64(basePrimes[bitIndex])
  subsetSigns[mask] = -subsetSigns[previousMask]

proc countMangu(value: int64): int64 =
  var total: int64 = 0
  for mask in 1 .. 8191:
    let quotient = value div subsetProducts[mask]
    if subsetSigns[mask] == 1:
      total = total + quotient
    else:
      total = total - quotient
  return total

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let requestedRank = int64(nextInt(inputData, scanPos))
  let periodNumber = (requestedRank - 1) div periodCount
  let localRank = (requestedRank - 1) mod periodCount + 1
  let estimate = int64(float(localRank) * float(periodValue) / float(periodCount))
  var lowBound = estimate - searchMargin
  if lowBound < 1:
    lowBound = 1
  var highBound = estimate + searchMargin
  if highBound > periodValue:
    highBound = periodValue
  while lowBound < highBound:
    let middle = lowBound + (highBound - lowBound) div 2
    if countMangu(middle) >= localRank:
      highBound = middle
    else:
      lowBound = middle + 1
  let answer = periodNumber * periodValue + lowBound
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
