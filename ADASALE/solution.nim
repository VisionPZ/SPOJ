const flushBlockBytes = 1 shl 17
const negativeInfinity = -1000000000000000'i64

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

let cityCount = nextInt(inputData, scanPos)
let bagLimit = nextInt(inputData, scanPos)
let modulus = nextInt(inputData, scanPos)
var licenceCosts = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  licenceCosts[cityIndex] = nextInt(inputData, scanPos)
var magicConstants = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  magicConstants[cityIndex] = nextInt(inputData, scanPos)

var currentProfit = newSeq[int64](bagLimit + 1)
var nextProfit = newSeq[int64](bagLimit + 1)
for countIndex in 0 .. bagLimit:
  currentProfit[countIndex] = negativeInfinity
currentProfit[0] = 0
var cumulativePrices = newSeq[int](bagLimit + 1)

for cityIndex in 0 .. cityCount - 1:
  let cityNumber = cityIndex + 1
  let stepPrice = (int64(magicConstants[cityIndex]) * int64(cityNumber)) mod int64(modulus)
  var runningPrice = 0
  cumulativePrices[0] = 0
  for countIndex in 1 .. bagLimit:
    runningPrice = (runningPrice + int(stepPrice)) mod modulus
    cumulativePrices[countIndex] = cumulativePrices[countIndex - 1] + runningPrice
  var bestBase = negativeInfinity
  for countIndex in 0 .. bagLimit:
    let candidateBase = currentProfit[countIndex] + int64(cumulativePrices[countIndex])
    if candidateBase > bestBase:
      bestBase = candidateBase
  let licenceFee = int64(licenceCosts[cityIndex])
  for countIndex in 0 .. bagLimit:
    let tradedProfit = bestBase - licenceFee - int64(cumulativePrices[countIndex])
    let skippedProfit = currentProfit[countIndex]
    if tradedProfit > skippedProfit:
      nextProfit[countIndex] = tradedProfit
    else:
      nextProfit[countIndex] = skippedProfit
  swap currentProfit, nextProfit

var bestProfit = currentProfit[0]
for countIndex in 1 .. bagLimit:
  if currentProfit[countIndex] > bestProfit:
    bestProfit = currentProfit[countIndex]

appendOutput($bestProfit)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
