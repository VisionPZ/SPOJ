import math

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

proc modPower(baseValue: int64, exponentValue: int64, modulusValue: int64): int64 =
  var resultValue: int64 = 1
  var reducedBase = baseValue mod modulusValue
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) != 0:
      resultValue = (resultValue * reducedBase) mod modulusValue
    reducedBase = (reducedBase * reducedBase) mod modulusValue
    remaining = remaining shr 1
  return resultValue

let problemCount = nextInt(inputData, scanPos)
var problemNs = newSeq[int](problemCount)
var problemModuli = newSeq[int](problemCount)
var largestN = 0
for problemIndex in 0 ..< problemCount:
  problemNs[problemIndex] = nextInt(inputData, scanPos)
  problemModuli[problemIndex] = nextInt(inputData, scanPos)
  if problemNs[problemIndex] > largestN:
    largestN = problemNs[problemIndex]

var oddComposite = newSeq[bool](largestN div 2 + 1)
oddComposite[0] = true
var baseValue = 3
while int64(baseValue) * int64(baseValue) <= int64(largestN):
  if not oddComposite[baseValue div 2]:
    var multipleValue = int64(baseValue) * int64(baseValue)
    let stepValue = int64(2 * baseValue)
    while multipleValue <= int64(largestN):
      oddComposite[int(multipleValue) div 2] = true
      multipleValue += stepValue
  baseValue += 2

var primeCounts = newSeq[int32](largestN + 1)
var primeList = newSeq[int]()
primeList.add 2
var runningCount = 0
for candidateValue in 0 .. largestN:
  var candidateIsPrime = false
  if candidateValue == 2:
    candidateIsPrime = true
  elif candidateValue > 2 and (candidateValue and 1) == 1:
    candidateIsPrime = not oddComposite[candidateValue div 2]
  if candidateIsPrime:
    runningCount += 1
    if candidateValue != 2:
      primeList.add candidateValue
  primeCounts[candidateValue] = int32(runningCount)

for problemIndex in 0 ..< problemCount:
  let problemN = problemNs[problemIndex]
  let modulusValue = int64(problemModuli[problemIndex])
  let squareRootLimit = int(sqrt(float(problemN)))
  var productValue: int64 = 1
  for primeIndex in 0 ..< primeList.len:
    let primeValue = int64(primeList[primeIndex])
    if primeValue == 2:
      continue
    if primeValue * primeValue > int64(problemN):
      break
    var exponentValue: int64 = 0
    var powerValue = primeValue
    while powerValue <= int64(problemN):
      exponentValue += int64(problemN) div powerValue
      if powerValue > int64(problemN) div primeValue:
        break
      powerValue = powerValue * primeValue
    productValue = (productValue * ((exponentValue + 1) mod modulusValue)) mod modulusValue
  for groupIndex in 1 .. squareRootLimit:
    let upperBound = problemN div groupIndex
    let lowerBound = problemN div (groupIndex + 1)
    var oddUpper = int64(primeCounts[upperBound])
    var oddLower = int64(primeCounts[lowerBound])
    if oddUpper > 0:
      oddUpper -= 1
    if oddLower > 0:
      oddLower -= 1
    let smallUpper = min(upperBound, squareRootLimit)
    let smallLower = min(lowerBound, squareRootLimit)
    var smallUpperCount = int64(primeCounts[smallUpper])
    var smallLowerCount = int64(primeCounts[smallLower])
    if smallUpperCount > 0:
      smallUpperCount -= 1
    if smallLowerCount > 0:
      smallLowerCount -= 1
    let largeCount = oddUpper - oddLower - (smallUpperCount - smallLowerCount)
    if largeCount > 0:
      productValue = (productValue * modPower(int64(groupIndex + 1), largeCount, modulusValue)) mod modulusValue
  let answerValue = if productValue == 0: modulusValue - 1 else: productValue - 1
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
