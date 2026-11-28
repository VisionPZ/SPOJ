import math

const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

proc combineCount(marbleCount, colorCount: int): int64 =
  var chosenColors = colorCount
  if marbleCount - chosenColors < chosenColors - 1:
    chosenColors = marbleCount - chosenColors + 1
  var ways: int64 = 1
  for step in 1 .. chosenColors - 1:
    let numerator = int64(marbleCount - step)
    let denominator = int64(step)
    let firstDivisor = gcd(denominator, ways)
    let reducedWays = ways div firstDivisor
    let reducedDenominator = denominator div firstDivisor
    let secondDivisor = gcd(reducedDenominator, numerator)
    let reducedNumerator = numerator div secondDivisor
    let finalDenominator = reducedDenominator div secondDivisor
    ways = reducedWays * reducedNumerator div finalDenominator
  return ways

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  var marbleCount = nextInt(inputData, i)
  var colorCount = nextInt(inputData, i)
  outputBuffer.add $combineCount(marbleCount, colorCount)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
