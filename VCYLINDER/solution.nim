import strutils

const flushBlockBytes = 1 shl 17
const circlePi = 3.14
const diameterHalves = 2.0

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let diameter = float(nextInt(inputData, scanPos))
let height = float(nextInt(inputData, scanPos))
let radius = diameter / diameterHalves
let volume = circlePi * radius * radius * height
appendOutput(formatFloat(volume, ffDecimal, 2))
appendOutput(" cm^3")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
