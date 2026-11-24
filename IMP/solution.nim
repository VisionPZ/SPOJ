import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextSigned(inputData: string, i: var int): int64 =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1
  var signValue = 1'i64
  if i < inputData.len and inputData[i] == '-':
    signValue = -1'i64
    i = i + 1
  elif i < inputData.len and inputData[i] == '+':
    i = i + 1
  var value = 0'i64
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int64(int(inputData[i]) - firstDigitValue)
    i = i + 1
  return signValue * value

proc bezoutCoefficients(firstValue, secondValue: int64): tuple[gcdValue, firstCoef, secondCoef: int64] =
  var oldRemainder = firstValue
  var remainder = secondValue
  var oldFirstCoef = 1'i64
  var firstCoef = 0'i64
  var oldSecondCoef = 0'i64
  var secondCoef = 1'i64
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    oldRemainder = remainder
    remainder = nextRemainder
    let nextFirstCoef = oldFirstCoef - quotient * firstCoef
    oldFirstCoef = firstCoef
    firstCoef = nextFirstCoef
    let nextSecondCoef = oldSecondCoef - quotient * secondCoef
    oldSecondCoef = secondCoef
    secondCoef = nextSecondCoef
  return (oldRemainder, oldFirstCoef, oldSecondCoef)

proc shortestDistance(firstX, firstY, secondX, secondY: int64): int64 =
  let absFirstX = abs(firstX)
  let absFirstY = abs(firstY)
  let absSecondX = abs(secondX)
  let absSecondY = abs(secondY)
  let searchRadius = min(absFirstX + absFirstY, absSecondX + absSecondY)
  let gcdX = gcd(absFirstX, absSecondX)
  if gcdX == 0:
    return gcd(absFirstY, absSecondY)
  var coefficients = bezoutCoefficients(absFirstX, absSecondX)
  var coefFirst = coefficients.firstCoef
  var coefSecond = coefficients.secondCoef
  if firstX < 0:
    coefFirst = -coefFirst
  if secondX < 0:
    coefSecond = -coefSecond
  let stepY = coefFirst * firstY + coefSecond * secondY
  let determinant = firstX * secondY - firstY * secondX
  let stepSize = abs(determinant div gcdX)
  var bestValue = searchRadius
  if stepSize > 0:
    bestValue = min(bestValue, stepSize)
  let maxIndex = searchRadius div gcdX
  var i = -maxIndex
  while i <= maxIndex:
    if i != 0:
      var distance: int64
      if stepSize == 0:
        distance = abs(i * stepY)
      else:
        var residue = (i * stepY) mod stepSize
        if residue < 0:
          residue = residue + stepSize
        distance = min(residue, stepSize - residue)
      let candidate = abs(gcdX * i) + distance
      if candidate < bestValue:
        bestValue = candidate
    i = i + 1
  return bestValue

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var outputBuffer: string
while true:
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1
  if i >= inputData.len:
    break
  let firstX = nextSigned(inputData, i)
  let firstY = nextSigned(inputData, i)
  let secondX = nextSigned(inputData, i)
  let secondY = nextSigned(inputData, i)
  outputBuffer.add $shortestDistance(firstX, firstY, secondX, secondY)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
