const flushBlockBytes = 1 shl 17
const precisionScale = 10000.0
const decisionCoins = [1, 4, 9, 16]

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

proc formatProbability(value: float64): string =
  var scaled: int64 = int64(value * precisionScale + 0.5)
  if scaled < 0:
    scaled = 0
  if scaled > int64(precisionScale):
    scaled = int64(precisionScale)
  let wholePart = int(scaled div int64(precisionScale))
  let fracPart = int(scaled mod int64(precisionScale))
  result = $wholePart
  result.add '.'
  if fracPart < 1000:
    result.add '0'
  if fracPart < 100:
    result.add '0'
  if fracPart < 10:
    result.add '0'
  result.add $fracPart

let testCaseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCaseCount - 1:
  let pileCount = nextInt(inputData, scanPos)
  let minusWeight = float64(nextInt(inputData, scanPos))
  let sameWeight = float64(nextInt(inputData, scanPos))
  let plusWeight = float64(nextInt(inputData, scanPos))
  let aliceMood = nextInt(inputData, scanPos)
  let bobMood = nextInt(inputData, scanPos)
  let pairDivisor = 1.0 / (sameWeight + plusWeight)
  let singleDivisor = 1.0 / sameWeight
  let tripleDivisor = 1.0 / (minusWeight + sameWeight + plusWeight)
  let doubleDivisor = 1.0 / (minusWeight + sameWeight)
  var aliceWins = newSeq[float64](pileCount + 1)
  var bobWins = newSeq[float64](pileCount + 1)
  aliceWins[0] = 1.0
  for remaining in 1 .. pileCount:
    var aliceLowest = 2.0
    var aliceHighest = -1.0
    var bobLowest = 2.0
    var bobHighest = -1.0
    for decisionIndex in 0 .. 3:
      let decidedCoins = decisionCoins[decisionIndex]
      if decidedCoins > remaining:
        break
      var aliceExpected: float64
      var bobExpected: float64
      var divisor: float64
      if decidedCoins == 1:
        divisor = pairDivisor
        aliceExpected = sameWeight * bobWins[remaining - 1]
        bobExpected = sameWeight * aliceWins[remaining - 1]
        if remaining >= 2:
          aliceExpected = aliceExpected + plusWeight * bobWins[remaining - 2]
          bobExpected = bobExpected + plusWeight * aliceWins[remaining - 2]
        else:
          divisor = singleDivisor
      else:
        divisor = tripleDivisor
        aliceExpected = minusWeight * bobWins[remaining - decidedCoins + 1]
        bobExpected = minusWeight * aliceWins[remaining - decidedCoins + 1]
        aliceExpected = aliceExpected + sameWeight * bobWins[remaining - decidedCoins]
        bobExpected = bobExpected + sameWeight * aliceWins[remaining - decidedCoins]
        if remaining >= decidedCoins + 1:
          aliceExpected = aliceExpected + plusWeight * bobWins[remaining - decidedCoins - 1]
          bobExpected = bobExpected + plusWeight * aliceWins[remaining - decidedCoins - 1]
        else:
          divisor = doubleDivisor
      aliceExpected = aliceExpected * divisor
      bobExpected = bobExpected * divisor
      if aliceExpected < aliceLowest:
        aliceLowest = aliceExpected
      if aliceExpected > aliceHighest:
        aliceHighest = aliceExpected
      if bobExpected < bobLowest:
        bobLowest = bobExpected
      if bobExpected > bobHighest:
        bobHighest = bobExpected
    if aliceMood == 1:
      aliceWins[remaining] = aliceLowest
    else:
      aliceWins[remaining] = aliceHighest
    if bobMood == 1:
      bobWins[remaining] = bobHighest
    else:
      bobWins[remaining] = bobLowest
  let bobWinningChance = aliceWins[pileCount]
  let answer = if bobMood == 1: bobWinningChance else: 1.0 - bobWinningChance
  appendOutput(formatProbability(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
