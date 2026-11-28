import algorithm

const flushBlockBytes = 1 shl 17
const neverVisible = -(1 shl 60)

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

proc multiplyPositive(firstValue: int64, secondValue: int64): tuple[highPart: int64, lowPart: uint64] =
  let firstLow = uint64(firstValue) and 0xffffffff'u64
  let firstHigh = uint64(firstValue) shr 32
  let secondLow = uint64(secondValue) and 0xffffffff'u64
  let secondHigh = uint64(secondValue) shr 32
  let bottom = firstLow * secondLow
  let crossOne = firstLow * secondHigh
  let crossTwo = firstHigh * secondLow
  let middle = (bottom shr 32) + (crossOne and 0xffffffff'u64) + (crossTwo and 0xffffffff'u64)
  result.lowPart = (bottom and 0xffffffff'u64) or (middle shl 32)
  result.highPart = int64(firstHigh * secondHigh + (crossOne shr 32) +
                          (crossTwo shr 32) + (middle shr 32))

proc compareFractions(firstNumerator: int64, firstDenominator: int64,
                      secondNumerator: int64, secondDenominator: int64): int =
  let firstNegative = firstNumerator < 0
  let secondNegative = secondNumerator < 0
  if firstNegative != secondNegative:
    if firstNegative:
      return -1
    return 1
  let firstMagnitude = if firstNegative: -firstNumerator else: firstNumerator
  let secondMagnitude = if secondNegative: -secondNumerator else: secondNumerator
  let leftProduct = multiplyPositive(firstMagnitude, secondDenominator)
  let rightProduct = multiplyPositive(secondMagnitude, firstDenominator)
  var magnitude = 0
  if leftProduct.highPart > rightProduct.highPart:
    magnitude = 1
  elif leftProduct.highPart < rightProduct.highPart:
    magnitude = -1
  elif leftProduct.lowPart > rightProduct.lowPart:
    magnitude = 1
  elif leftProduct.lowPart < rightProduct.lowPart:
    magnitude = -1
  if firstNegative:
    return -magnitude
  return magnitude

proc floorDivide(numerator: int64, denominator: int64): int64 =
  if numerator >= 0:
    return numerator div denominator
  return -((-numerator + denominator - 1) div denominator)

proc compareThresholds(firstValue: int64, secondValue: int64): int =
  if firstValue < secondValue:
    return -1
  if firstValue > secondValue:
    return 1
  return 0

proc countBelow(values: seq[int64], target: int64): int =
  var lowBound = 0
  var highBound = values.len
  while lowBound < highBound:
    let middle = (lowBound + highBound) div 2
    if values[middle] < target:
      lowBound = middle + 1
    else:
      highBound = middle
  return lowBound

let buildingCount = nextInt(inputData, scanPos)
var buildingHeights = newSeq[int](buildingCount)
for buildingIndex in 0 .. buildingCount - 1:
  buildingHeights[buildingIndex] = nextInt(inputData, scanPos)

var visibilityThreshold = newSeq[int64](buildingCount)
var hullBuildings: seq[int] = @[]
var hullNumerators: seq[int64] = @[]
var hullDenominators: seq[int64] = @[]

for currentBuilding in 0 .. buildingCount - 1:
  var placed = false
  while hullBuildings.len > 0:
    let lastBuilding = hullBuildings[hullBuildings.len - 1]
    let lastPosition = int64(lastBuilding + 1)
    let lastHeight = int64(buildingHeights[lastBuilding])
    let currentPosition = int64(currentBuilding + 1)
    let currentHeight = int64(buildingHeights[currentBuilding])
    let crossNumerator = currentPosition * lastHeight - lastPosition * currentHeight
    let crossDenominator = currentPosition - lastPosition
    if hullBuildings.len >= 2:
      let previousNumerator = hullNumerators[hullNumerators.len - 1]
      let previousDenominator = hullDenominators[hullDenominators.len - 1]
      if compareFractions(crossNumerator, crossDenominator,
                          previousNumerator, previousDenominator) <= 0:
        hullBuildings.setLen(hullBuildings.len - 1)
        hullNumerators.setLen(hullNumerators.len - 1)
        hullDenominators.setLen(hullDenominators.len - 1)
        continue
    hullBuildings.add currentBuilding
    hullNumerators.add crossNumerator
    hullDenominators.add crossDenominator
    visibilityThreshold[currentBuilding] = floorDivide(crossNumerator, crossDenominator)
    placed = true
    break
  if not placed:
    hullBuildings.add currentBuilding
    hullNumerators.add 0
    hullDenominators.add 1
    visibilityThreshold[currentBuilding] = neverVisible

visibilityThreshold.sort(compareThresholds)

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let eyeHeight = int64(nextInt(inputData, scanPos))
  appendOutput($countBelow(visibilityThreshold, eyeHeight))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
