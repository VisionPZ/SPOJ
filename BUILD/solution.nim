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

proc nextNumberText(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var text = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    text.add data[pos]
    pos += 1
  return text

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc countHeightBits(heightText: string, requirements: var seq[int]): int =
  var digits = newSeq[int](heightText.len)
  for digitIndex in 0 .. heightText.len - 1:
    digits[digitIndex] = int(heightText[digitIndex]) - 48
  var firstDigit = 0
  var bitIndex = 0
  while firstDigit < digits.len:
    var remainder = 0
    for digitIndex in firstDigit .. digits.len - 1:
      let divided = remainder * 10 + digits[digitIndex]
      digits[digitIndex] = divided div 2
      remainder = divided mod 2
    requirements[bitIndex] += remainder
    while firstDigit < digits.len and digits[firstDigit] == 0:
      firstDigit += 1
    bitIndex += 1
  return bitIndex

proc sortValues(values: var seq[int]) =
  for rightIndex in 1 .. values.len - 1:
    let carriedValue = values[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and values[leftIndex] < carriedValue:
      values[leftIndex + 1] = values[leftIndex]
      leftIndex -= 1
    values[leftIndex + 1] = carriedValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let stoneCount = nextInt(inputData, scanPos)
  var exponents = newSeq[int](stoneCount)
  var strengths = newSeq[int](stoneCount)
  var highestLevel = 0
  for stoneIndex in 0 .. stoneCount - 1:
    exponents[stoneIndex] = nextInt(inputData, scanPos)
    strengths[stoneIndex] = nextInt(inputData, scanPos)
    if exponents[stoneIndex] > highestLevel:
      highestLevel = exponents[stoneIndex]
  let towerCount = nextInt(inputData, scanPos)
  var requirements = newSeq[int](1200)
  for towerIndex in 0 .. towerCount - 1:
    let heightText = nextNumberText(inputData, scanPos)
    let bitCount = countHeightBits(heightText, requirements)
    if bitCount - 1 > highestLevel:
      highestLevel = bitCount - 1
  var valuesByLevel = newSeq[seq[int]](highestLevel + 1)
  for levelIndex in 0 .. highestLevel:
    valuesByLevel[levelIndex] = newSeq[int](0)
  for stoneIndex in 0 .. stoneCount - 1:
    valuesByLevel[exponents[stoneIndex]].add strengths[stoneIndex]
  var prefixSums = newSeq[seq[int]](highestLevel + 1)
  for levelIndex in 0 .. highestLevel:
    sortValues(valuesByLevel[levelIndex])
    prefixSums[levelIndex] = newSeq[int](valuesByLevel[levelIndex].len + 1)
    prefixSums[levelIndex][0] = 0
    for valueIndex in 0 .. valuesByLevel[levelIndex].len - 1:
      prefixSums[levelIndex][valueIndex + 1] = prefixSums[levelIndex][valueIndex] + valuesByLevel[levelIndex][valueIndex]
  let maxCarry = stoneCount + 2
  var currentBest = newSeq[int64](maxCarry + 1)
  var nextBest = newSeq[int64](maxCarry + 1)
  for carryValue in 0 .. maxCarry:
    currentBest[carryValue] = -1
    nextBest[carryValue] = -1
  currentBest[0] = 0
  for levelIndex in 0 .. highestLevel:
    for carryValue in 0 .. maxCarry:
      nextBest[carryValue] = -1
    let availableCount = valuesByLevel[levelIndex].len
    let neededCount = requirements[levelIndex]
    for carryValue in 0 .. maxCarry:
      if currentBest[carryValue] < 0:
        continue
      for usedCount in 0 .. availableCount:
        let totalUnits = carryValue + usedCount
        if totalUnits < neededCount:
          continue
        if (totalUnits - neededCount) mod 2 != 0:
          continue
        let nextCarry = (totalUnits - neededCount) div 2
        if nextCarry > maxCarry:
          continue
        let candidate = currentBest[carryValue] + int64(prefixSums[levelIndex][usedCount])
        if candidate > nextBest[nextCarry]:
          nextBest[nextCarry] = candidate
    for carryValue in 0 .. maxCarry:
      currentBest[carryValue] = nextBest[carryValue]
  if currentBest[0] < 0:
    appendOutput("Plan Failed!\n")
  else:
    appendOutput($currentBest[0])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
