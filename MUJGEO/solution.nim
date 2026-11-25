import math
import strutils

const flushBlockBytes = 1 shl 17
const circlePi = 3.14159265358979323846

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDouble(data: string, pos: var int): float =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-' and data[pos] != '+':
    pos += 1
  var signValue = 1.0
  if pos < data.len and (data[pos] == '-' or data[pos] == '+'):
    if data[pos] == '-':
      signValue = -1.0
    pos += 1
  var wholeValue = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholeValue = wholeValue * 10.0 + float(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var placeValue = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      wholeValue = wholeValue + float(int(data[pos]) - 48) * placeValue
      placeValue = placeValue / 10.0
      pos += 1
  if pos < data.len and (data[pos] == 'e' or data[pos] == 'E'):
    pos += 1
    var exponentSign = 1.0
    if pos < data.len and (data[pos] == '-' or data[pos] == '+'):
      if data[pos] == '-':
        exponentSign = -1.0
      pos += 1
    var exponentValue = 0.0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      exponentValue = exponentValue * 10.0 + float(int(data[pos]) - 48)
      pos += 1
    wholeValue = wholeValue * pow(10.0, exponentSign * exponentValue)
  return signValue * wholeValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let angleAtA = nextDouble(inputData, scanPos)
let angleAtB = nextDouble(inputData, scanPos)
let sideBC = nextDouble(inputData, scanPos)
let sideAD = nextDouble(inputData, scanPos)

let radiansDegree = circlePi / 180.0
let radiansA = angleAtA * radiansDegree
let radiansB = angleAtB * radiansDegree
let radiansC = circlePi - radiansA - radiansB
let sideAC = sideBC * sin(radiansB) / sin(radiansA)
let chordSquared = sideAC * sideAC + sideAD * sideAD - 2.0 * sideAC * sideAD * cos(radiansC)
let circleArea = circlePi * chordSquared / 4.0

appendOutput(formatFloat(circleArea, ffDecimal, 10))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
