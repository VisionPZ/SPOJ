import math, strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

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

var scanPos = 0

while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let pointX = nextInt(inputData, scanPos)
  discard pointX
  let pointY = nextInt(inputData, scanPos)
  let radius = nextInt(inputData, scanPos)
  let heightRatio = float(pointY) / float(radius)
  let sectorAngle = arcsin(heightRatio)
  let sectorArea = 0.5 * float(radius) * float(radius) * sectorAngle
  appendOutput(formatFloat(sectorArea, ffDecimal, 3))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
