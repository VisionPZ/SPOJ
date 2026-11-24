{.passC: "-O2".}
{.push checks: off.}
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxRegionCount = 3000
const infiniteCost = int64.high div 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var sortedValues: seq[int64] = @[]
var prefixSums: array[0..maxRegionCount + 1, int64]
var previousCosts: array[0..maxRegionCount, int64]
var currentCosts: array[0..maxRegionCount, int64]

proc blockCost(leftIndex, rightIndex: int): int64 =
  let medianIndex = (leftIndex + rightIndex) div 2
  let leftCount = medianIndex - leftIndex + 1
  let rightCount = rightIndex - medianIndex
  let leftSum = prefixSums[medianIndex + 1] - prefixSums[leftIndex]
  let rightSum = prefixSums[rightIndex + 1] - prefixSums[medianIndex + 1]
  let medianValue = sortedValues[medianIndex]
  return int64(leftCount) * medianValue - leftSum + rightSum - int64(rightCount) * medianValue

let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let regionCount = nextInt(inputData, scanPos)
  let colorCount = nextInt(inputData, scanPos)
  sortedValues.setLen(regionCount)
  for j in 0..<regionCount:
    sortedValues[j] = int64(nextInt(inputData, scanPos))
  sortedValues.sort(system.cmp[int64])
  prefixSums[0] = 0
  for j in 0..<regionCount:
    prefixSums[j + 1] = prefixSums[j] + sortedValues[j]
  for j in 0..regionCount:
    previousCosts[j] = infiniteCost
  for j in 1..regionCount:
    previousCosts[j] = blockCost(0, j - 1)
  for colorIndex in 2..colorCount:
    for j in 0..regionCount:
      currentCosts[j] = infiniteCost
    for coloredCount in colorIndex..regionCount:
      var bestCost = infiniteCost
      for k in (colorIndex - 1)..(coloredCount - 1):
        let candidateCost = previousCosts[k] + blockCost(k, coloredCount - 1)
        if candidateCost < bestCost:
          bestCost = candidateCost
      currentCosts[coloredCount] = bestCost
    swap previousCosts, currentCosts
  appendOutput($(previousCosts[regionCount]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
