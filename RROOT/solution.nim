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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 1
while caseIndex <= caseCount:
  let sideLength = float64(nextInt(inputData, scanPos))
  let halfSide = sideLength / 2.0
  var realRootsProbability: float64
  if halfSide <= 1.0:
    realRootsProbability = 0.5 + halfSide / 6.0
  else:
    realRootsProbability = 1.0 - 1.0 / (3.0 * sqrt(halfSide))
  appendOutput(formatFloat(realRootsProbability, ffDecimal, 6))
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
