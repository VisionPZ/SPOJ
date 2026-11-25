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

let testCaseCount = nextInt(inputData, scanPos)
for testCaseIndex in 0 .. testCaseCount - 1:
  let sourceCount = nextInt(inputData, scanPos)
  let cubeSide = nextInt(inputData, scanPos)
  var firstWallTime = cubeSide
  for sourceIndex in 0 .. sourceCount - 1:
    let coordinateX = nextInt(inputData, scanPos)
    let coordinateY = nextInt(inputData, scanPos)
    let coordinateZ = nextInt(inputData, scanPos)
    var bestDistance = coordinateX
    if cubeSide - coordinateX > bestDistance:
      bestDistance = cubeSide - coordinateX
    if coordinateY > bestDistance:
      bestDistance = coordinateY
    if cubeSide - coordinateY > bestDistance:
      bestDistance = cubeSide - coordinateY
    if coordinateZ > bestDistance:
      bestDistance = coordinateZ
    if cubeSide - coordinateZ > bestDistance:
      bestDistance = cubeSide - coordinateZ
    if bestDistance < firstWallTime:
      firstWallTime = bestDistance
  appendOutput($firstWallTime)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
