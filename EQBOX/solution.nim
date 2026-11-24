import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var value = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i += 1
  return value

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer = ""

var j = 0
while j < caseCount:
  let tileFirst = nextInt(inputData, i)
  let tileSecond = nextInt(inputData, i)
  let boxFirst = nextInt(inputData, i)
  let boxSecond = nextInt(inputData, i)

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
  j += 1

stdout.write outputBuffer
