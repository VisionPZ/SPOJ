const flushBlockBytes = 1 shl 17
const infinityValue = 4000000000000000000'i64

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

var warriorCount = 0
var inversionCosts: seq[int32]
var previousCosts: seq[int64]
var currentCosts: seq[int64]

proc computeSplitRange(lowIndex, highIndex, optLow, optHigh: int) =
  if lowIndex > highIndex:
    return
  let middleIndex = (lowIndex + highIndex) div 2
  var upperSplit = optHigh
  if upperSplit > middleIndex - 1:
    upperSplit = middleIndex - 1
  var bestValue = infinityValue
  var bestSplit = optLow
  var splitIndex = optLow
  while splitIndex <= upperSplit:
    let previousValue = previousCosts[splitIndex]
    if previousValue < infinityValue:
      let candidateValue = previousValue + int64(inversionCosts[(splitIndex + 1) * warriorCount + middleIndex])
      if candidateValue < bestValue:
        bestValue = candidateValue
        bestSplit = splitIndex
    splitIndex += 1
  currentCosts[middleIndex] = bestValue
  computeSplitRange(lowIndex, middleIndex - 1, optLow, bestSplit)
  computeSplitRange(middleIndex + 1, highIndex, bestSplit, optHigh)

let totalWarriors = nextInt(inputData, scanPos)
let wantedRows = nextInt(inputData, scanPos)
var heights = newSeq[int32](totalWarriors)
for heightIndex in 0 .. totalWarriors - 1:
  heights[heightIndex] = int32(nextInt(inputData, scanPos))

var answerValue: int64 = 0
if wantedRows >= totalWarriors:
  answerValue = 0
elif wantedRows == 1:
  var totalInversions: int64 = 0
  for leftIndex in 0 .. totalWarriors - 1:
    for rightIndex in leftIndex + 1 .. totalWarriors - 1:
      if heights[leftIndex] > heights[rightIndex]:
        totalInversions += 1
  answerValue = totalInversions
else:
  warriorCount = totalWarriors
  inversionCosts = newSeq[int32](warriorCount * warriorCount)
  for rightIndex in 0 .. warriorCount - 1:
    var greaterCount: int32 = 0
    var leftIndex = rightIndex - 1
    while leftIndex >= 0:
      if heights[leftIndex] > heights[rightIndex]:
        greaterCount += 1
      inversionCosts[leftIndex * warriorCount + rightIndex] = inversionCosts[leftIndex * warriorCount + rightIndex - 1] + greaterCount
      leftIndex -= 1
  previousCosts = newSeq[int64](warriorCount)
  for endIndex in 0 .. warriorCount - 1:
    previousCosts[endIndex] = int64(inversionCosts[endIndex])
  for rowCount in 2 .. wantedRows:
    currentCosts = newSeq[int64](warriorCount)
    computeSplitRange(rowCount - 1, warriorCount - 1, rowCount - 2, warriorCount - 1)
    swap(previousCosts, currentCosts)
    if previousCosts[warriorCount - 1] == 0'i64:
      break
  answerValue = previousCosts[warriorCount - 1]

appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
