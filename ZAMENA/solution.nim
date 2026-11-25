const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let memberCount = nextInt(inputData, scanPos)
var memberIds = newSeq[int](memberCount)
for memberIndex in 0 .. memberCount - 1:
  memberIds[memberIndex] = nextInt(inputData, scanPos)

var digitLength = 1
var largestPlace = 10
while largestPlace <= memberIds[0]:
  digitLength += 1
  largestPlace = largestPlace * 10

var placeValues = newSeq[int](digitLength)
var placeMultiplier = 1
for placeIndex in countdown(digitLength - 1, 0):
  placeValues[placeIndex] = placeMultiplier
  placeMultiplier = placeMultiplier * 10

var bestExactScore = newSeq[int64](largestPlace)
for scoreIndex in 0 .. largestPlace - 1:
  bestExactScore[scoreIndex] = -1

var bestTotalScore: int64 = 0
for memberIndex in 0 .. memberCount - 1:
  let currentId = memberIds[memberIndex]
  var chainScore: int64 = 0
  for placeIndex in 0 .. digitLength - 1:
    let placeValue = placeValues[placeIndex]
    let currentDigit = (currentId div placeValue) mod 10
    let idWithoutDigit = currentId - currentDigit * placeValue
    for candidateDigit in 0 .. 9:
      let variantId = idWithoutDigit + candidateDigit * placeValue
      let priorScore = bestExactScore[variantId]
      if priorScore >= 0:
        let changeAmount = abs(candidateDigit - currentDigit)
        let candidateScore = priorScore + int64(changeAmount)
        if candidateScore > chainScore:
          chainScore = candidateScore
  if chainScore > bestTotalScore:
    bestTotalScore = chainScore
  if chainScore > bestExactScore[currentId]:
    bestExactScore[currentId] = chainScore

appendOutput($bestTotalScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
