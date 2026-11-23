import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

var caseIndex = 0
while caseIndex < caseCount:
  let tileFirst = nextInt(inputData, scanPos)
  let tileSecond = nextInt(inputData, scanPos)
  let boxFirst = nextInt(inputData, scanPos)
  let boxSecond = nextInt(inputData, scanPos)

  var tileShort = tileFirst
  var tileLong = tileSecond
  if tileShort > tileLong:
    swap tileShort, tileLong
  var boxShort = boxFirst
  var boxLong = boxSecond
  if boxShort > boxLong:
    swap boxShort, boxLong

  var escapePossible = false
  if boxShort <= tileShort and boxLong <= tileLong:
    escapePossible = true
  elif boxShort > tileShort:
    escapePossible = false
  else:
    let boxDiagonal = sqrt(float(boxShort) * float(boxShort) + float(boxLong) * float(boxLong))
    let boxAngle = arctan(float(boxShort) / float(boxLong))
    let wideAngle = arcsin(float(tileLong) / boxDiagonal)
    let requiredAngle = arccos(float(tileShort) / boxDiagonal)
    if wideAngle - 2.0 * boxAngle >= requiredAngle - 1e-12:
      escapePossible = true

  if escapePossible:
    outputBuffer.add "Escape is possible.\n"
  else:
    outputBuffer.add "Box cannot be dropped.\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

stdout.write outputBuffer
