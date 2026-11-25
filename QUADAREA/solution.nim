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
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.':
    pos += 1
  var whole = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    whole = whole * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var fraction = 0.0
    var scale = 10.0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fraction = fraction + float64(int(data[pos]) - 48) / scale
      scale = scale * 10.0
      pos += 1
    whole = whole + fraction
  return whole

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sideFirst = nextReal(inputData, scanPos)
  let sideSecond = nextReal(inputData, scanPos)
  let sideThird = nextReal(inputData, scanPos)
  let sideFourth = nextReal(inputData, scanPos)
  let semiperimeter = (sideFirst + sideSecond + sideThird + sideFourth) / 2.0
  var areaProduct = (semiperimeter - sideFirst) * (semiperimeter - sideSecond) * (semiperimeter - sideThird) * (semiperimeter - sideFourth)
  if areaProduct < 0.0:
    areaProduct = 0.0
  let largestArea = sqrt(areaProduct)
  appendOutput(formatFloat(largestArea, ffDecimal, 2))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
