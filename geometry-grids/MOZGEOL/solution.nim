import math
import strutils

const flushBlockBytes = 1 shl 17
const degreesPerTurn = 180

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

proc nextFloat(data: string, pos: var int): float =
  while pos < data.len and data[pos] != '.' and data[pos] != '-' and
       (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1.0
  if pos < data.len and data[pos] == '-':
    signValue = -1.0
    pos += 1
  var wholePart = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10.0 + float(int(data[pos]) - 48)
    pos += 1
  var fractionPart = 0.0
  var scaleValue = 1.0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      scaleValue = scaleValue * 10.0
      fractionPart = fractionPart + float(int(data[pos]) - 48) / scaleValue
      pos += 1
  return signValue * (wholePart + fractionPart)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let shortSide = nextFloat(inputData, scanPos)
  let smallAngle = nextFloat(inputData, scanPos)
  let angleRadians = smallAngle * PI / float(degreesPerTurn)
  let hypotenuseLength = shortSide / sin(angleRadians)
  appendOutput("Case " & $caseIndex & ": " & formatFloat(hypotenuseLength, ffDecimal, 6))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
