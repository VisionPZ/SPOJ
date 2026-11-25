const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hugeCost = 1000000000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc minCost(values: seq[int], valueCount, onesTotal, level: int,
             previous: var seq[int], current: var seq[int]): int =
  for ones in 0..onesTotal:
    previous[ones] = hugeCost
    current[ones] = hugeCost
  previous[0] = 0
  var prefixSum = 0
  for valueIndex in 0..<valueCount:
    prefixSum += values[valueIndex]
    let maxOnes = min(valueIndex + 1, onesTotal)
    for ones in 0..maxOnes:
      var bestPrevious = previous[ones]
      if ones > 0 and previous[ones - 1] < bestPrevious:
        bestPrevious = previous[ones - 1]
      var difference = prefixSum - ones - level
      if difference < 0: difference = -difference
      current[ones] = bestPrevious + difference
    swap(previous, current)
  return previous[onesTotal]

proc solveCase(values: seq[int], valueCount: int): int =
  var onesTotal = 0
  for valueIndex in 0..<valueCount:
    onesTotal += values[valueIndex]
  var previous = newSeq[int](onesTotal + 1)
  var current = newSeq[int](onesTotal + 1)
  var lowLevel = -valueCount
  var highLevel = onesTotal
  while highLevel - lowLevel > 3:
    let thirdSpan = (highLevel - lowLevel) div 3
    let leftLevel = lowLevel + thirdSpan
    let rightLevel = highLevel - thirdSpan
    let leftCost = minCost(values, valueCount, onesTotal, leftLevel, previous, current)
    let rightCost = minCost(values, valueCount, onesTotal, rightLevel, previous, current)
    if leftCost <= rightCost:
      highLevel = rightLevel - 1
    else:
      lowLevel = leftLevel + 1
  var bestAnswer = hugeCost
  for level in lowLevel..highLevel:
    let cost = minCost(values, valueCount, onesTotal, level, previous, current)
    if cost < bestAnswer:
      bestAnswer = cost
  return bestAnswer

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for caseIndex in 0..<caseCount:
  let valueCount = nextInt(inputData, scanPos)
  var values = newSeq[int](valueCount)
  for valueIndex in 0..<valueCount:
    values[valueIndex] = nextInt(inputData, scanPos)
  outputBuffer.add $(solveCase(values, valueCount))
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
