const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and not ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '-'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc removeAt(values: var seq[int], position: int) =
  var index = position
  while index < values.len - 1:
    values[index] = values[index + 1]
    index += 1
  values.setLen(values.len - 1)

var targetSigns = newSeq[int]()
var currentStarts = newSeq[int]()
var currentValues = newSeq[int]()

proc findPosition(firstNumber: int): int =
  for position in 0 .. currentStarts.len - 1:
    if currentStarts[position] == firstNumber:
      return position
  return -1

proc effectiveSign(numberIndex: int, inverted: bool): int =
  if inverted:
    return -targetSigns[numberIndex]
  return targetSigns[numberIndex]

proc buildGroup(firstNumber: int, lastNumber: int, inverted: bool): int =
  if firstNumber == lastNumber:
    return findPosition(firstNumber)
  var splitNumber = -1
  var candidate = firstNumber + 1
  while candidate <= lastNumber:
    if effectiveSign(candidate, inverted) == -1 and (candidate == lastNumber or effectiveSign(candidate + 1, inverted) == 1):
      splitNumber = candidate
      break
    candidate += 1
  let leftPosition = buildGroup(firstNumber, splitNumber - 1, inverted)
  let rightPosition = buildGroup(splitNumber, lastNumber, not inverted)
  appendOutput($(leftPosition + 1))
  outputBuffer.add '\n'
  currentValues[leftPosition] = currentValues[leftPosition] - currentValues[rightPosition]
  removeAt(currentValues, rightPosition)
  removeAt(currentStarts, rightPosition)
  return leftPosition

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberCount = nextInt(inputData, scanPos)
  let targetValue = nextInt(inputData, scanPos)
  var originalNumbers = newSeq[int](numberCount)
  for numberIndex in 0 .. numberCount - 1:
    originalNumbers[numberIndex] = nextInt(inputData, scanPos)
  targetSigns = newSeq[int](numberCount)
  if numberCount == 1:
    targetSigns[0] = 1
  else:
    targetSigns[0] = 1
    targetSigns[1] = -1
    var remainingTotal = 0
    for numberIndex in 2 .. numberCount - 1:
      remainingTotal += originalNumbers[numberIndex]
    let wantedTotal = targetValue - originalNumbers[0] + originalNumbers[1]
    let columnCount = 2 * remainingTotal + 1
    let sumOffset = remainingTotal
    var reachable = newSeq[bool](numberCount * columnCount)
    reachable[sumOffset] = true
    for usedCount in 1 .. numberCount - 2:
      let currentValue = originalNumbers[usedCount + 1]
      let rowStart = usedCount * columnCount
      let previousStart = (usedCount - 1) * columnCount
      for sumValue in 0 .. columnCount - 1:
        var possible = false
        if sumValue >= currentValue and reachable[previousStart + sumValue - currentValue]:
          possible = true
        if not possible and sumValue + currentValue < columnCount and reachable[previousStart + sumValue + currentValue]:
          possible = true
        reachable[rowStart + sumValue] = possible
    var walkSum = sumOffset + wantedTotal
    for usedCount in countdown(numberCount - 2, 1):
      let currentValue = originalNumbers[usedCount + 1]
      let previousStart = (usedCount - 1) * columnCount
      if walkSum - currentValue >= 0 and reachable[previousStart + walkSum - currentValue]:
        targetSigns[usedCount + 1] = 1
        walkSum -= currentValue
      else:
        targetSigns[usedCount + 1] = -1
        walkSum += currentValue
  currentStarts = newSeq[int](numberCount)
  currentValues = newSeq[int](numberCount)
  for numberIndex in 0 .. numberCount - 1:
    currentStarts[numberIndex] = numberIndex
    currentValues[numberIndex] = originalNumbers[numberIndex]
  discard buildGroup(0, numberCount - 1, false)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
