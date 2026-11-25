const flushBlockBytes = 1 shl 17
const primeDigitBase = 48

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
    value = value * 10 + int(data[pos]) - primeDigitBase
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var cardValues = newSeq[int]()
var caseBoundaries = newSeq[int]()
caseBoundaries.add 0
var largestCard = 2
for caseIndex in 0 .. caseCount - 1:
  let cardCount = nextInt(inputData, scanPos)
  for cardIndex in 0 .. cardCount - 1:
    let cardValue = nextInt(inputData, scanPos)
    cardValues.add cardValue
    if cardValue > largestCard:
      largestCard = cardValue
  caseBoundaries.add cardValues.len

var smallestFactor = newSeq[int32](largestCard + 1)
var candidatePrime = 2
while candidatePrime * candidatePrime <= largestCard:
  if smallestFactor[candidatePrime] == 0:
    var multipleValue = candidatePrime * candidatePrime
    while multipleValue <= largestCard:
      if smallestFactor[multipleValue] == 0:
        smallestFactor[multipleValue] = int32(candidatePrime)
      multipleValue += candidatePrime
  candidatePrime += 1

var primeBalance = newSeq[int32](largestCard + 1)
var touchedPrimes = newSeq[int]()
for caseIndex in 0 .. caseCount - 1:
  let lowerBound = caseBoundaries[caseIndex]
  let upperBound = caseBoundaries[caseIndex + 1]
  touchedPrimes.setLen 0
  var longestPrimeRun = 0
  var currentPrimeRun = 0
  for cardPosition in lowerBound .. upperBound - 1:
    let cardValue = cardValues[cardPosition]
    let cardIsPrime = cardValue >= 2 and smallestFactor[cardValue] == 0
    if cardIsPrime:
      currentPrimeRun += 1
      if currentPrimeRun > longestPrimeRun:
        longestPrimeRun = currentPrimeRun
    else:
      currentPrimeRun = 0
    var remainingValue = cardValue
    while remainingValue > 1:
      var factorValue = int(smallestFactor[remainingValue])
      if factorValue == 0:
        factorValue = remainingValue
      var factorCount = 0
      while remainingValue mod factorValue == 0:
        remainingValue = remainingValue div factorValue
        factorCount += 1
      if primeBalance[factorValue] == 0:
        touchedPrimes.add factorValue
      if cardIsPrime:
        primeBalance[factorValue] += 1
      else:
        primeBalance[factorValue] -= int32(factorCount)
  var longestValidRun = 0
  var currentValidRun = 0
  for cardPosition in lowerBound .. upperBound - 1:
    let cardValue = cardValues[cardPosition]
    if cardValue >= 2 and smallestFactor[cardValue] == 0 and primeBalance[cardValue] > 0:
      currentValidRun += 1
      if currentValidRun > longestValidRun:
        longestValidRun = currentValidRun
    else:
      currentValidRun = 0
  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $longestPrimeRun & " > " & $longestValidRun)
  outputBuffer.add '\n'
  for primeIndex in 0 .. touchedPrimes.len - 1:
    primeBalance[touchedPrimes[primeIndex]] = 0
stdout.write outputBuffer
outputBuffer.setLen 0
