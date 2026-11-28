import math, strutils

const flushBlockBytes = 1 shl 17
const radiusSlack = 1e-9

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

proc nextDecimal(data: string, pos: var int): float64 =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1.0
  if pos < data.len and data[pos] == '-':
    signValue = -1.0
    pos += 1
  var wholePart = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  var fractionPart = 0.0
  var scaleValue = 1.0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionPart = fractionPart * 10.0 + float64(int(data[pos]) - 48)
      scaleValue = scaleValue * 10.0
      pos += 1
  return signValue * (wholePart + fractionPart / scaleValue)

proc squaredDistance(pointX: float64, pointY: float64, centerX: float64, centerY: float64): float64 =
  let diffX = pointX - centerX
  let diffY = pointY - centerY
  return diffX * diffX + diffY * diffY

proc setFromPair(pointX: float64, pointY: float64, otherX: float64, otherY: float64, centerX: var float64, centerY: var float64, radius: var float64) =
  centerX = (pointX + otherX) / 2.0
  centerY = (pointY + otherY) / 2.0
  radius = sqrt(squaredDistance(pointX, pointY, centerX, centerY))

proc setFromTriple(firstX: float64, firstY: float64, secondX: float64, secondY: float64, thirdX: float64, thirdY: float64, centerX: var float64, centerY: var float64, radius: var float64) =
  let divisor = 2.0 * (firstX * (secondY - thirdY) + secondX * (thirdY - firstY) + thirdX * (firstY - secondY))
  if divisor > -1e-12 and divisor < 1e-12:
    let firstSecond = squaredDistance(firstX, firstY, secondX, secondY)
    let firstThird = squaredDistance(firstX, firstY, thirdX, thirdY)
    let secondThird = squaredDistance(secondX, secondY, thirdX, thirdY)
    if firstSecond >= firstThird and firstSecond >= secondThird:
      setFromPair(firstX, firstY, secondX, secondY, centerX, centerY, radius)
    elif firstThird >= secondThird:
      setFromPair(firstX, firstY, thirdX, thirdY, centerX, centerY, radius)
    else:
      setFromPair(secondX, secondY, thirdX, thirdY, centerX, centerY, radius)
    return
  let firstNorm = firstX * firstX + firstY * firstY
  let secondNorm = secondX * secondX + secondY * secondY
  let thirdNorm = thirdX * thirdX + thirdY * thirdY
  centerX = (firstNorm * (secondY - thirdY) + secondNorm * (thirdY - firstY) + thirdNorm * (firstY - secondY)) / divisor
  centerY = (firstNorm * (thirdX - secondX) + secondNorm * (firstX - thirdX) + thirdNorm * (secondX - firstX)) / divisor
  radius = sqrt(squaredDistance(firstX, firstY, centerX, centerY))

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fixedText(value: float64): string =
  if value > -0.00005 and value < 0.00005:
    return formatFloat(0.0, ffDecimal, 4)
  return formatFloat(value, ffDecimal, 4)

var randomState = 2463534242'u32

proc nextRandom(): uint32 =
  randomState = randomState xor (randomState shl 13'u32)
  randomState = randomState xor (randomState shr 17'u32)
  randomState = randomState xor (randomState shl 5'u32)
  return randomState

while true:
  let communityCount = nextInt(inputData, scanPos)
  if communityCount == 0:
    break
  var pointX = newSeq[float64](communityCount)
  var pointY = newSeq[float64](communityCount)
  for pointIndex in 0 .. communityCount - 1:
    pointX[pointIndex] = nextDecimal(inputData, scanPos)
    pointY[pointIndex] = nextDecimal(inputData, scanPos)
  var shuffleIndex = communityCount - 1
  while shuffleIndex >= 1:
    let swapIndex = int(nextRandom() mod uint32(shuffleIndex + 1))
    let keptX = pointX[shuffleIndex]
    let keptY = pointY[shuffleIndex]
    pointX[shuffleIndex] = pointX[swapIndex]
    pointY[shuffleIndex] = pointY[swapIndex]
    pointX[swapIndex] = keptX
    pointY[swapIndex] = keptY
    shuffleIndex -= 1

  var centerX = 0.0
  var centerY = 0.0
  var radius = -1.0
  for pointIndex in 0 .. communityCount - 1:
    let currentX = pointX[pointIndex]
    let currentY = pointY[pointIndex]
    if radius >= 0.0 and squaredDistance(currentX, currentY, centerX, centerY) <= radius * radius + radiusSlack:
      continue
    setFromPair(currentX, currentY, currentX, currentY, centerX, centerY, radius)
    for firstIndex in 0 .. pointIndex - 1:
      let firstX = pointX[firstIndex]
      let firstY = pointY[firstIndex]
      if squaredDistance(firstX, firstY, centerX, centerY) <= radius * radius + radiusSlack:
        continue
      setFromPair(currentX, currentY, firstX, firstY, centerX, centerY, radius)
      for secondIndex in 0 .. firstIndex - 1:
        let secondX = pointX[secondIndex]
        let secondY = pointY[secondIndex]
        if squaredDistance(secondX, secondY, centerX, centerY) <= radius * radius + radiusSlack:
          continue
        setFromTriple(currentX, currentY, firstX, firstY, secondX, secondY, centerX, centerY, radius)
  appendOutput(fixedText(centerX) & ", " & fixedText(centerY))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
