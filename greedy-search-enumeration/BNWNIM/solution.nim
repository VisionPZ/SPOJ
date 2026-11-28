const flushBlockBytes = 1 shl 17
const maxBeadCount = 100
const xorStateCount = 128
const decimalDigits = 6
const decimalScale = 1000000

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

proc appendProbability(probabilityValue: float) =
  var scaledValue = int(probabilityValue * float(decimalScale) + 0.5)
  if scaledValue < 0:
    scaledValue = 0
  if scaledValue > decimalScale:
    scaledValue = decimalScale
  let wholePart = scaledValue div decimalScale
  let fractionPart = scaledValue mod decimalScale
  appendOutput($wholePart)
  appendOutput(".")
  var divisorValue = decimalScale div 10
  for digitIndex in 0 .. decimalDigits - 1:
    appendOutput($((fractionPart div divisorValue) mod 10))
    divisorValue = divisorValue div 10
  outputBuffer.add '\n'

var distributionCache = newSeq[seq[float]]((maxBeadCount + 1) * (maxBeadCount + 1))

proc rowDistribution(blackCount: int, whiteCount: int): seq[float] =
  let cacheKey = blackCount * (maxBeadCount + 1) + whiteCount
  if distributionCache[cacheKey].len > 0:
    return distributionCache[cacheKey]
  let maxGrundy = whiteCount + 1
  let stride = maxGrundy + 1
  var counts = newSeq[float]((whiteCount + 1) * stride)
  for spareWhites in 0 .. whiteCount:
    counts[spareWhites * stride + spareWhites] = 1.0
  for gapIndex in 0 .. blackCount - 1:
    var prefixSums = newSeq[float]((whiteCount + 1) * stride)
    var suffixSums = newSeq[float]((whiteCount + 1) * stride)
    for spareWhites in 0 .. whiteCount:
      for grundyValue in 0 .. maxGrundy:
        let cellIndex = spareWhites * stride + grundyValue
        if grundyValue == 0:
          prefixSums[cellIndex] = counts[cellIndex]
        else:
          prefixSums[cellIndex] = prefixSums[cellIndex - 1] + counts[cellIndex]
      for grundyValue in countdown(maxGrundy, 0):
        let cellIndex = spareWhites * stride + grundyValue
        if grundyValue == maxGrundy:
          suffixSums[cellIndex] = counts[cellIndex]
        else:
          suffixSums[cellIndex] = suffixSums[cellIndex + 1] + counts[cellIndex]
    var nextCounts = newSeq[float]((whiteCount + 1) * stride)
    for totalWhites in 0 .. whiteCount:
      for resultGrundy in 0 .. maxGrundy:
        let resultIndex = totalWhites * stride + resultGrundy
        if resultGrundy < maxGrundy:
          let gapSize = resultGrundy
          if gapSize <= totalWhites:
            let sourceIndex = (totalWhites - gapSize) * stride + gapSize + 1
            nextCounts[resultIndex] = nextCounts[resultIndex] + suffixSums[sourceIndex]
        if resultGrundy > 0:
          let gapSize = resultGrundy - 1
          if gapSize <= totalWhites:
            let sourceIndex = (totalWhites - gapSize) * stride + gapSize
            nextCounts[resultIndex] = nextCounts[resultIndex] + prefixSums[sourceIndex]
    counts = nextCounts
  var probabilities = newSeq[float](stride)
  var totalCount = 0.0
  for grundyValue in 0 .. maxGrundy:
    probabilities[grundyValue] = counts[whiteCount * stride + grundyValue]
    totalCount = totalCount + probabilities[grundyValue]
  for grundyValue in 0 .. maxGrundy:
    probabilities[grundyValue] = probabilities[grundyValue] / totalCount
  distributionCache[cacheKey] = probabilities
  return probabilities

proc solveCase(blackCounts: seq[int], whiteCounts: seq[int]): float =
  var combined = newSeq[float](xorStateCount)
  combined[0] = 1.0
  for rowIndex in 0 .. blackCounts.len - 1:
    let singleRow = rowDistribution(blackCounts[rowIndex], whiteCounts[rowIndex])
    var nextCombined = newSeq[float](xorStateCount)
    for stateValue in 0 .. xorStateCount - 1:
      if combined[stateValue] == 0.0:
        continue
      for grundyValue in 0 .. singleRow.len - 1:
        let nextState = stateValue xor grundyValue
        nextCombined[nextState] = nextCombined[nextState] + combined[stateValue] * singleRow[grundyValue]
    combined = nextCombined
  return 1.0 - combined[0]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  var blackCounts = newSeq[int](rowCount)
  var whiteCounts = newSeq[int](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    blackCounts[rowIndex] = nextInt(inputData, scanPos)
  for rowIndex in 0 .. rowCount - 1:
    whiteCounts[rowIndex] = nextInt(inputData, scanPos)
  let winProbability = solveCase(blackCounts, whiteCounts)
  appendProbability(winProbability)

stdout.write outputBuffer
outputBuffer.setLen 0
