import math
import strutils

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
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

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let fireflyCount = nextInt(inputData, scanPos)
  var positionX: int64 = 0
  var positionY: int64 = 0
  var positionZ: int64 = 0
  var velocityX: int64 = 0
  var velocityY: int64 = 0
  var velocityZ: int64 = 0
  for fireflyIndex in 0 .. fireflyCount - 1:
    positionX += int64(nextInt(inputData, scanPos))
    positionY += int64(nextInt(inputData, scanPos))
    positionZ += int64(nextInt(inputData, scanPos))
    velocityX += int64(nextInt(inputData, scanPos))
    velocityY += int64(nextInt(inputData, scanPos))
    velocityZ += int64(nextInt(inputData, scanPos))
  let crossTerm = float64(positionX * velocityX + positionY * velocityY +
                          positionZ * velocityZ)
  let speedTerm = float64(velocityX * velocityX + velocityY * velocityY +
                          velocityZ * velocityZ)
  var bestTime = 0.0
  if speedTerm > 0.0 and crossTerm < 0.0:
    bestTime = -crossTerm / speedTerm
  let centerX = (float64(positionX) + float64(velocityX) * bestTime) /
                float64(fireflyCount)
  let centerY = (float64(positionY) + float64(velocityY) * bestTime) /
                float64(fireflyCount)
  let centerZ = (float64(positionZ) + float64(velocityZ) * bestTime) /
                float64(fireflyCount)
  let closestDistance = sqrt(centerX * centerX + centerY * centerY +
                             centerZ * centerZ)
  appendOutput("Case #" & $caseNumber & ": " &
               formatFloat(closestDistance, ffDecimal, 8) & " " &
               formatFloat(bestTime, ffDecimal, 8) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
