import math

const flushBlockBytes = 1 shl 17
const degreesToRadians = 0.017453292519943295
const spinFactor = 2.5
const largeSpinFactor = 11.25

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

proc hasAnotherNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasAnotherNumber(inputData, scanPos):
  let centerRadius = nextInt(inputData, scanPos)
  let ballRadius = nextInt(inputData, scanPos)
  let coneDegrees = nextInt(inputData, scanPos)
  let angle = float(coneDegrees) * degreesToRadians
  let sineValue = sin(angle)
  let cosineValue = cos(angle)
  let radiusRatio = float(centerRadius) / float(ballRadius)
  let sineSquared = sineValue * sineValue
  let cosineSquared = cosineValue * cosineValue
  let crossTerm = 2.0 * cosineValue * radiusRatio * (1.0 + spinFactor * sineSquared)
  let squareTerm = radiusRatio * radiusRatio * (1.0 + largeSpinFactor * sineSquared)
  let denominator = sqrt(cosineSquared + crossTerm + squareTerm)
  let contactCircleRadius = float(ballRadius) * cosineValue * (radiusRatio + cosineValue) / denominator
  appendOutput($(int(contactCircleRadius + 0.5)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
