import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = 1 shl 60
const maxColumns = 1000
const maxPeaks = 25

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc compareValues(leftValue, rightValue: int): int =
  if leftValue < rightValue: return -1
  if leftValue > rightValue: return 1
  return 0

proc heightLevel(heightValues: seq[int], levelCount: int, target: int): int =
  var low = 0
  var high = levelCount - 1
  while low <= high:
    let middle = (low + high) div 2
    if heightValues[middle] < target:
      low = middle + 1
    else:
      high = middle - 1
  return low + 1

proc solveCase(elevations: seq[int], columnCount: int, budget: int, peakRun: var seq[int], valleyRun: var seq[int], nextPeak: var seq[int], nextValley: var seq[int], prefixBest: var seq[int], suffixPeak: var seq[int], suffixValley: var seq[int]): int =
  var sortedValues = newSeq[int](columnCount)
  for column in 0 .. columnCount - 1:
    sortedValues[column] = elevations[column]
  sort(sortedValues, compareValues)
  var distinctValues = newSeq[int](columnCount)
  var distinctCount = 0
  for value in sortedValues:
    if distinctCount == 0 or distinctValues[distinctCount - 1] != value:
      distinctValues[distinctCount] = value
      distinctCount += 1
  let stride = budget + 1
  let levelCount = distinctCount
  for index in 0 .. (levelCount + 2) * stride - 1:
    peakRun[index] = infinity
    valleyRun[index] = infinity
    nextPeak[index] = infinity
    nextValley[index] = infinity
    prefixBest[index] = infinity
    suffixPeak[index] = infinity
    suffixValley[index] = infinity
  let firstLevel = heightLevel(distinctValues, distinctCount, elevations[0])
  for level in 1 .. firstLevel:
    peakRun[level * stride] = elevations[0] - distinctValues[level - 1]
  var maxTopSeen = firstLevel
  for column in 1 .. columnCount - 1:
    let elevation = elevations[column]
    let topLevel = heightLevel(distinctValues, distinctCount, elevation)
    maxTopSeen = max(maxTopSeen, topLevel)
    for count in 0 .. budget:
      prefixBest[count] = infinity
      suffixPeak[(maxTopSeen + 1) * stride + count] = infinity
      suffixValley[(maxTopSeen + 1) * stride + count] = infinity
    for level in 1 .. topLevel - 1:
      let base = level * stride
      for count in 0 .. budget:
        prefixBest[base + count] = min(prefixBest[base - stride + count], min(peakRun[base + count], valleyRun[base + count]))
    for level in countdown(maxTopSeen, 1):
      let base = level * stride
      for count in 0 .. budget:
        suffixPeak[base + count] = min(suffixPeak[base + stride + count], peakRun[base + count])
        suffixValley[base + count] = min(suffixValley[base + stride + count], valleyRun[base + count])
      if level > topLevel:
        for count in 0 .. budget:
          nextPeak[base + count] = infinity
          nextValley[base + count] = infinity
    for level in 1 .. topLevel:
      let base = level * stride
      let addCost = elevation - distinctValues[level - 1]
      for count in 0 .. budget:
        var valleyCost = min(valleyRun[base + count], suffixValley[base + stride + count]) + addCost
        if count > 0:
          valleyCost = min(valleyCost, suffixPeak[base + stride + count - 1] + addCost)
        nextValley[base + count] = valleyCost
        nextPeak[base + count] = min(peakRun[base + count], prefixBest[base - stride + count]) + addCost
    swap(peakRun, nextPeak)
    swap(valleyRun, nextValley)
  var answer = infinity
  for level in 1 .. levelCount:
    let base = level * stride
    for count in 0 .. budget:
      answer = min(answer, valleyRun[base + count])
    if budget > 0:
      for count in 0 .. budget - 1:
        answer = min(answer, peakRun[base + count])
  return answer

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
let bufferSize = (maxColumns + 2) * (maxPeaks + 1)
var peakRun = newSeq[int](bufferSize)
var valleyRun = newSeq[int](bufferSize)
var nextPeak = newSeq[int](bufferSize)
var nextValley = newSeq[int](bufferSize)
var prefixBest = newSeq[int](bufferSize)
var suffixPeak = newSeq[int](bufferSize)
var suffixValley = newSeq[int](bufferSize)
var elevations = newSeq[int](maxColumns)
var outputBuffer = ""

for caseIndex in 0 .. caseCount - 1:
  let columnCount = nextInt(inputData, scanPos)
  let requestedBudget = nextInt(inputData, scanPos)
  let budget = min(requestedBudget, maxPeaks)
  for column in 0 .. columnCount - 1:
    elevations[column] = nextInt(inputData, scanPos)
  let answer = solveCase(elevations, columnCount, budget, peakRun, valleyRun, nextPeak, nextValley, prefixBest, suffixPeak, suffixValley)
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
