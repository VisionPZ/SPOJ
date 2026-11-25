import math
import tables

const flushBlockBytes = 1 shl 17
const sieveLimit = 10000000
const keyStride = 512

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

var isComposite = newSeq[bool](sieveLimit + 1)
isComposite[0] = true
isComposite[1] = true
let sieveRoot = int(sqrt(float64(sieveLimit))) + 1
for candidate in 2 .. sieveRoot:
  if not isComposite[candidate]:
    var multiple = candidate * candidate
    while multiple <= sieveLimit:
      isComposite[multiple] = true
      multiple += candidate

var primeList = newSeq[int](0)
var primePrefix = newSeq[int32](sieveLimit + 1)
for number in 2 .. sieveLimit:
  if not isComposite[number]:
    primeList.add number
for number in 1 .. sieveLimit:
  if isComposite[number]:
    primePrefix[number] = primePrefix[number - 1]
  else:
    primePrefix[number] = primePrefix[number - 1] + 1

var phiCache = initTable[int64, int64]()
var piCache = initTable[int64, int64]()

proc phiCount(value: int64, primeCount: int): int64 =
  var effectiveCount = primeCount
  if value <= 1:
    return value
  if value <= int64(sieveLimit):
    let possibleCount = int(primePrefix[int(value)])
    if effectiveCount > possibleCount:
      effectiveCount = possibleCount
  if effectiveCount == 0:
    return value
  if effectiveCount == 1:
    return value - value div 2
  let cacheKey = value * int64(keyStride) + int64(effectiveCount)
  if phiCache.hasKey(cacheKey):
    return phiCache[cacheKey]
  let counted = phiCount(value, effectiveCount - 1) -
    phiCount(value div int64(primeList[effectiveCount - 1]), effectiveCount - 1)
  phiCache[cacheKey] = counted
  return counted

proc powerFits(baseValue: int64, exponentValue, limitValue: int64): bool =
  var product: int64 = 1
  for unusedIndex in 1 .. exponentValue:
    if product > limitValue div baseValue:
      return false
    product = product * baseValue
  return true

proc integerRoot(value: int64, exponentValue: int): int64 =
  case exponentValue
  of 2:
    var root = int64(sqrt(float64(value)))
    while powerFits(root + 1, 2, value):
      root += 1
    while not powerFits(root, 2, value):
      root -= 1
    return root
  of 3:
    var root = int64(pow(float64(value), 1.0 / 3.0))
    while powerFits(root + 1, 3, value):
      root += 1
    while not powerFits(root, 3, value):
      root -= 1
    return root
  else:
    var root = int64(sqrt(sqrt(float64(value))))
    while powerFits(root + 1, 4, value):
      root += 1
    while not powerFits(root, 4, value):
      root -= 1
    return root

proc primePi(value: int64): int64 =
  if value <= int64(sieveLimit):
    return int64(primePrefix[int(value)])
  if piCache.hasKey(value):
    return piCache[value]
  let fourthRoot = integerRoot(value, 4)
  let cubeRoot = integerRoot(value, 3)
  let squareRoot = integerRoot(value, 2)
  let smallCount = primePi(fourthRoot)
  let cubeCount = primePi(cubeRoot)
  let largeCount = primePi(squareRoot)
  var counted = phiCount(value, int(smallCount)) +
    (largeCount + smallCount - 2) * (largeCount - smallCount + 1) div 2
  var primeIndex = int(smallCount)
  while primeIndex < int(largeCount):
    let quotient = value div int64(primeList[primeIndex])
    counted -= primePi(quotient)
    primeIndex += 1
  primeIndex = int(smallCount)
  while primeIndex < int(cubeCount):
    let quotient = value div int64(primeList[primeIndex])
    let limit = primePi(integerRoot(quotient, 2))
    var secondIndex = primeIndex
    while secondIndex < int(limit):
      let doubledQuotient = quotient div int64(primeList[secondIndex])
      counted -= primePi(doubledQuotient) - int64(secondIndex)
      secondIndex += 1
    primeIndex += 1
  piCache[value] = counted
  return counted

let primeIndexWanted = int64(nextInt(inputData, scanPos))
var answer: int64
if primeIndexWanted <= int64(primeList.len):
  answer = int64(primeList[int(primeIndexWanted) - 1])
else:
  var lowValue = int64(primeList[primeList.len - 1])
  let approximate = float64(primeIndexWanted)
  let logIndex = ln(approximate)
  let logLogIndex = ln(logIndex)
  var highValue: int64
  if primeIndexWanted >= 688383:
    let lowerEstimate = approximate *
      (logIndex + logLogIndex - 1.0 + (logLogIndex - 2.1) / logIndex)
    if int64(lowerEstimate) > lowValue:
      lowValue = int64(lowerEstimate)
    highValue = int64(approximate *
      (logIndex + logLogIndex - 1.0 + (logLogIndex - 2.0) / logIndex)) + 100
  else:
    highValue = int64(approximate * (logIndex + logLogIndex)) + 100
  if highValue <= lowValue:
    highValue = lowValue + 1000
  while lowValue < highValue:
    let middleValue = lowValue + (highValue - lowValue) div 2
    if primePi(middleValue) >= primeIndexWanted:
      highValue = middleValue
    else:
      lowValue = middleValue + 1
  answer = lowValue

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
