import math
import strutils

const flushBlockBytes = 1 shl 17
const directionX = [1, 0, 1, -1, 0, 1, -1, -1]
const directionY = [0, 1, 1, 1, -1, -1, -1, 0]
const directionName = ["E", "N", "NE", "NW", "S", "SE", "SW", "W"]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc costLess(firstLinear, firstDiagonal, secondLinear, secondDiagonal: int64): bool =
  let linearDifference = firstLinear - secondLinear
  let diagonalDifference = firstDiagonal - secondDiagonal
  if linearDifference == 0 and diagonalDifference == 0:
    return false
  if diagonalDifference == 0:
    return linearDifference < 0
  if linearDifference == 0:
    return diagonalDifference < 0
  if linearDifference > 0 and diagonalDifference > 0:
    return false
  if linearDifference < 0 and diagonalDifference < 0:
    return true
  if linearDifference > 0:
    return linearDifference * linearDifference < 2 * diagonalDifference * diagonalDifference
  return linearDifference * linearDifference > 2 * diagonalDifference * diagonalDifference

proc appendCoordinate(halfValue: int) =
  var magnitude = halfValue
  if magnitude < 0:
    appendOutput("-")
    magnitude = -magnitude
  appendOutput($(magnitude div 2))
  if magnitude mod 2 == 0:
    appendOutput(".00 ")
  else:
    appendOutput(".50 ")

while true:
  var hasNextCase = false
  var checkPos = scanPos
  while checkPos < inputData.len:
    if (inputData[checkPos] >= '0' and inputData[checkPos] <= '9') or inputData[checkPos] == '-':
      hasNextCase = true
      break
    checkPos += 1
  if not hasNextCase:
    break
  let startX = nextInt(inputData, scanPos)
  let startY = nextInt(inputData, scanPos)
  let targetX = nextInt(inputData, scanPos)
  let targetY = nextInt(inputData, scanPos)
  let deltaX = targetX - startX
  let deltaY = targetY - startY
  var bestFirst = -1
  var bestSecond = -1
  var bestLinear: int64 = 0
  var bestDiagonal: int64 = 0
  var splitHalfX = 0
  var splitHalfY = 0
  var eventCount = 0

  for firstDirection in 0 .. 7:
    let cross = deltaX * directionY[firstDirection] - deltaY * directionX[firstDirection]
    let dot = deltaX * directionX[firstDirection] + deltaY * directionY[firstDirection]
    if cross != 0 or dot <= 0:
      continue
    let steps = if directionX[firstDirection] != 0: deltaX div directionX[firstDirection] else: deltaY div directionY[firstDirection]
    let candidateLinear = if directionX[firstDirection] == 0 or directionY[firstDirection] == 0: int64(2 * steps) else: 0'i64
    let candidateDiagonal = if directionX[firstDirection] == 0 or directionY[firstDirection] == 0: 0'i64 else: int64(2 * steps)
    if bestFirst == -1 or costLess(candidateLinear, candidateDiagonal, bestLinear, bestDiagonal):
      bestFirst = firstDirection
      bestSecond = -1
      bestLinear = candidateLinear
      bestDiagonal = candidateDiagonal
      eventCount = 2

  if bestFirst == -1:
    for firstDirection in 0 .. 7:
      for secondDirection in 0 .. 7:
        if firstDirection == secondDirection:
          continue
        var determinant = directionX[firstDirection] * directionY[secondDirection] - directionY[firstDirection] * directionX[secondDirection]
        if determinant == 0:
          continue
        var firstSteps = deltaX * directionY[secondDirection] - deltaY * directionX[secondDirection]
        var secondSteps = directionX[firstDirection] * deltaY - directionY[firstDirection] * deltaX
        if determinant < 0:
          determinant = -determinant
          firstSteps = -firstSteps
          secondSteps = -secondSteps
        if firstSteps <= 0 or secondSteps <= 0:
          continue
        let scale = 2 div determinant
        var candidateLinear: int64 = 0
        var candidateDiagonal: int64 = 0
        if directionX[firstDirection] == 0 or directionY[firstDirection] == 0:
          candidateLinear += int64(firstSteps * scale)
        else:
          candidateDiagonal += int64(firstSteps * scale)
        if directionX[secondDirection] == 0 or directionY[secondDirection] == 0:
          candidateLinear += int64(secondSteps * scale)
        else:
          candidateDiagonal += int64(secondSteps * scale)
        let better = costLess(candidateLinear, candidateDiagonal, bestLinear, bestDiagonal)
        let tied = (not better) and (not costLess(bestLinear, bestDiagonal, candidateLinear, candidateDiagonal))
        if bestFirst == -1 or better or (tied and (firstDirection < bestFirst or (firstDirection == bestFirst and secondDirection < bestSecond))):
          bestFirst = firstDirection
          bestSecond = secondDirection
          bestLinear = candidateLinear
          bestDiagonal = candidateDiagonal
          splitHalfX = startX * 2 + firstSteps * directionX[firstDirection] * scale
          splitHalfY = startY * 2 + firstSteps * directionY[firstDirection] * scale
          eventCount = 3

  appendOutput($eventCount)
  outputBuffer.add '\n'
  appendCoordinate(startX * 2)
  appendCoordinate(startY * 2)
  appendOutput(directionName[bestFirst])
  outputBuffer.add '\n'
  if bestSecond >= 0:
    appendCoordinate(splitHalfX)
    appendCoordinate(splitHalfY)
    appendOutput(directionName[bestSecond])
    outputBuffer.add '\n'
  appendCoordinate(targetX * 2)
  appendCoordinate(targetY * 2)
  appendOutput("X")
  outputBuffer.add '\n'
  let distance = (float(bestLinear) + float(bestDiagonal) * sqrt(2.0)) / 2.0
  appendOutput(formatFloat(distance, ffDecimal, 3))
  outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
