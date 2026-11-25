const flushBlockBytes = 1 shl 17
const ringSquaredLimits = [100, 900, 2500, 4900, 8100, 12100, 16900, 22500, 28900, 36100]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dartCount = nextInt(inputData, scanPos)
var totalScore = 0
for dartIndex in 0 .. dartCount - 1:
  let xCoord = nextInt(inputData, scanPos)
  let yCoord = nextInt(inputData, scanPos)
  let squaredDistance = xCoord * xCoord + yCoord * yCoord
  var shotScore = 0
  for ringIndex in 0 .. ringSquaredLimits.len - 1:
    if squaredDistance <= ringSquaredLimits[ringIndex]:
      shotScore = 10 - ringIndex
      break
  totalScore += shotScore
appendOutput($totalScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
