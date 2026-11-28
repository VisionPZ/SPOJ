import strutils

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

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and data[pos] != '.' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var scale = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      value = value + scale * float64(int(data[pos]) - 48)
      scale = scale * 0.1
      pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let fishCount = nextInt(inputData, scanPos)
  var moveProbabilities = newSeq[float64](fishCount * fishCount)
  for rowIndex in 0 .. fishCount - 1:
    for columnIndex in 0 .. fishCount - 1:
      moveProbabilities[rowIndex * fishCount + columnIndex] = nextReal(inputData, scanPos)
  let stateCount = 1 shl fishCount
  var dynamicProbability = newSeq[float64](stateCount)
  var populatedBits = newSeq[int](stateCount)
  var bitPositions = newSeq[int](stateCount)
  for aquariumIndex in 0 .. fishCount - 1:
    bitPositions[1 shl aquariumIndex] = aquariumIndex
  dynamicProbability[0] = 1.0
  for maskValue in 1 .. stateCount - 1:
    populatedBits[maskValue] = populatedBits[maskValue shr 1] + (maskValue and 1)
  let fullMask = stateCount - 1
  for maskValue in 0 .. fullMask:
    let currentProbability = dynamicProbability[maskValue]
    if currentProbability == 0.0:
      continue
    let fishIndex = populatedBits[maskValue]
    let rowStart = fishIndex * fishCount
    var remainingAquariums = fullMask xor maskValue
    while remainingAquariums != 0:
      let aquariumBit = remainingAquariums and (-remainingAquariums)
      let aquariumIndex = bitPositions[aquariumBit]
      let nextMask = maskValue or aquariumBit
      dynamicProbability[nextMask] = dynamicProbability[nextMask] + currentProbability * moveProbabilities[rowStart + aquariumIndex]
      remainingAquariums = remainingAquariums xor aquariumBit
  appendOutput(formatFloat(dynamicProbability[stateCount - 1], ffDecimal, 6))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
