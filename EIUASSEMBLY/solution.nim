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

proc affordableRate(baseRates: seq[int64], upgradeCosts: seq[int64], budget, targetRate: int64): bool =
  var remainingBudget = budget
  for robotIndex in 0 .. baseRates.len - 1:
    let missingUnits = targetRate - baseRates[robotIndex]
    if missingUnits <= 0:
      continue
    if missingUnits > remainingBudget div upgradeCosts[robotIndex]:
      return false
    remainingBudget -= missingUnits * upgradeCosts[robotIndex]
  return true

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let robotCount = nextInt(inputData, scanPos)
  let budget = int64(nextInt(inputData, scanPos))
  var baseRates = newSeq[int64](robotCount)
  var upgradeCosts = newSeq[int64](robotCount)
  var largestRate: int64 = 0
  for robotIndex in 0 .. robotCount - 1:
    baseRates[robotIndex] = int64(nextInt(inputData, scanPos))
    upgradeCosts[robotIndex] = int64(nextInt(inputData, scanPos))
    if baseRates[robotIndex] > largestRate:
      largestRate = baseRates[robotIndex]

  var lowRate: int64 = 0
  var highRate = largestRate + budget + 1
  while lowRate < highRate:
    let middleRate = lowRate + (highRate - lowRate + 1) div 2
    if affordableRate(baseRates, upgradeCosts, budget, middleRate):
      lowRate = middleRate
    else:
      highRate = middleRate - 1
  appendOutput($lowRate)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
