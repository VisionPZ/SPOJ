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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareSums(firstSum: int64, secondSum: int64): int =
  if firstSum < secondSum: return -1
  if firstSum > secondSum: return 1
  return 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let treeCount = nextInt(inputData, scanPos)
  let basketCapacity = int64(nextInt(inputData, scanPos))
  var appleCounts = newSeq[int64](treeCount)
  for treeIndex in 0 .. treeCount - 1:
    appleCounts[treeIndex] = int64(nextInt(inputData, scanPos))
  let leftSize = treeCount div 2
  let rightSize = treeCount - leftSize
  let leftComboCount = 1 shl leftSize
  let rightComboCount = 1 shl rightSize
  var leftSums = newSeq[int64](leftComboCount)
  for comboMask in 1 .. leftComboCount - 1:
    let lowestBit = comboMask and -comboMask
    var bitPosition = 0
    var bitMarker = 1
    while (comboMask and bitMarker) == 0:
      bitMarker = bitMarker shl 1
      bitPosition += 1
    leftSums[comboMask] = leftSums[comboMask - lowestBit] + appleCounts[bitPosition]
  var rightSums = newSeq[int64](rightComboCount)
  for comboMask in 1 .. rightComboCount - 1:
    let lowestBit = comboMask and -comboMask
    var bitPosition = 0
    var bitMarker = 1
    while (comboMask and bitMarker) == 0:
      bitMarker = bitMarker shl 1
      bitPosition += 1
    rightSums[comboMask] = rightSums[comboMask - lowestBit] + appleCounts[leftSize + bitPosition]
  rightSums.sort(compareSums)
  var bestHarvest: int64 = 0
  for comboMask in 0 .. leftComboCount - 1:
    let leftTotal = leftSums[comboMask]
    if leftTotal > basketCapacity:
      continue
    let remainingCapacity = basketCapacity - leftTotal
    var lowBound = 0
    var highBound = rightComboCount - 1
    var chosenIndex = -1
    while lowBound <= highBound:
      let middleIndex = (lowBound + highBound) div 2
      if rightSums[middleIndex] <= remainingCapacity:
        chosenIndex = middleIndex
        lowBound = middleIndex + 1
      else:
        highBound = middleIndex - 1
    if chosenIndex >= 0:
      let totalHarvest = leftTotal + rightSums[chosenIndex]
      if totalHarvest > bestHarvest:
        bestHarvest = totalHarvest
  appendOutput($bestHarvest)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
