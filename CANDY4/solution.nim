import math
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maximumBoxSize = 20000

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

proc nextProbability(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  var fractionalPart = 0
  var fractionalDigits = 0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionalPart = fractionalPart * 10 + int(data[pos]) - firstDigitValue
      fractionalDigits += 1
      pos += 1
  var scale = 1.0
  if fractionalDigits > 0:
    for digitIndex in 0 .. fractionalDigits - 1:
      scale = scale * 10.0
  return float64(wholePart) + float64(fractionalPart) / scale

var logFactorials = newSeq[float64](2 * maximumBoxSize + 1)
var summationCompensation = 0.0
for valueIndex in 1 .. 2 * maximumBoxSize:
  let compensatedTerm = ln(float64(valueIndex)) - summationCompensation
  let updatedSum = logFactorials[valueIndex - 1] + compensatedTerm
  summationCompensation = (updatedSum - logFactorials[valueIndex - 1]) - compensatedTerm
  logFactorials[valueIndex] = updatedSum

proc sideExpectation(boxSize: int, ownProbability: float64, otherProbability: float64): float64 =
  if ownProbability <= 0.0:
    return 0.0
  if otherProbability <= 0.0:
    return float64(boxSize)
  var total = 0.0
  for eatenCandies in 0 .. boxSize:
    let combinationLog = logFactorials[boxSize + eatenCandies] -
                         logFactorials[boxSize] - logFactorials[eatenCandies]
    let exponent = combinationLog +
                   float64(boxSize + 1) * ln(ownProbability) +
                   float64(eatenCandies) * ln(otherProbability)
    total += float64(boxSize - eatenCandies) * exp(exponent)
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseIndex = 0
while true:
  let boxSize = nextInt(inputData, scanPos)
  if boxSize == 0:
    break
  let firstProbability = nextProbability(inputData, scanPos)
  let secondProbability = 1.0 - firstProbability
  let expectedValue = sideExpectation(boxSize, firstProbability, secondProbability) +
                      sideExpectation(boxSize, secondProbability, firstProbability)
  caseIndex += 1
  appendOutput("Case " & $caseIndex & ": " & formatFloat(expectedValue, ffDecimal, 6))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
