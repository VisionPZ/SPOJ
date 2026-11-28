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

let instructionCount = nextInt(inputData, scanPos)
var northSouth: int64 = 0
var eastWest: int64 = 0
for instructionIndex in 0 .. instructionCount - 1:
  let stepCount = int64(nextInt(inputData, scanPos))
  while scanPos < inputData.len and inputData[scanPos] != 'N' and inputData[scanPos] != 'S' and inputData[scanPos] != 'E' and inputData[scanPos] != 'W':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let directionChar = inputData[scanPos]
  scanPos += 1
  case directionChar:
    of 'N':
      northSouth += stepCount
    of 'S':
      northSouth -= stepCount
    of 'E':
      eastWest += stepCount
    of 'W':
      eastWest -= stepCount
    else:
      discard

let squaredDistance = northSouth * northSouth + eastWest * eastWest
var highRoot: int64 = 0
while highRoot * highRoot < squaredDistance:
  if highRoot == 0:
    highRoot = 1
  else:
    highRoot = highRoot * 2
var lowRoot: int64 = 0
while highRoot - lowRoot > 1:
  let midRoot = (lowRoot + highRoot) div 2
  if midRoot * midRoot >= squaredDistance:
    highRoot = midRoot
  else:
    lowRoot = midRoot
appendOutput($highRoot)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
