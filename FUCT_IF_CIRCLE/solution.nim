import math
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSigned(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextSigned(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let radius = nextSigned(inputData, scanPos)
  var rendered = ""
  if radius <= 0:
    rendered.add "the radius must be greater than 0"
  else:
    let radiusValue = float(radius)
    let circumference = 2.0 * PI * radiusValue
    let areaValue = PI * radiusValue * radiusValue
    rendered.add formatFloat(circumference, ffDecimal, 6)
    rendered.add ' '
    rendered.add formatFloat(areaValue, ffDecimal, 6)
  rendered.add '\n'
  appendOutput rendered

stdout.write outputBuffer
outputBuffer.setLen 0
