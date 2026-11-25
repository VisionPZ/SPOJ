const flushBlockBytes = 1 shl 17
const signCount = 8

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

var signLayer = newSeq[int](signCount)
var signCoordX = newSeq[int](signCount)
var signCoordY = newSeq[int](signCount)
for mask in 0 .. signCount - 1:
  signLayer[mask] = if (mask and 1) == 0: 1 else: -1
  signCoordX[mask] = if (mask and 2) == 0: 1 else: -1
  signCoordY[mask] = if (mask and 4) == 0: 1 else: -1

var extremeMin = newSeq[int64](signCount)
var extremeMax = newSeq[int64](signCount)
while true:
  let particleCount = nextInt(inputData, scanPos)
  if particleCount == 0:
    break
  for mask in 0 .. signCount - 1:
    extremeMin[mask] = high(int64)
    extremeMax[mask] = low(int64)
  for particleIndex in 0 .. particleCount - 1:
    let layerValue = nextInt(inputData, scanPos)
    let coordXValue = nextInt(inputData, scanPos)
    let coordYValue = nextInt(inputData, scanPos)
    for mask in 0 .. signCount - 1:
      let signedValue = int64(signLayer[mask]) * int64(layerValue) +
                        int64(signCoordX[mask]) * int64(coordXValue) +
                        int64(signCoordY[mask]) * int64(coordYValue)
      if signedValue < extremeMin[mask]:
        extremeMin[mask] = signedValue
      if signedValue > extremeMax[mask]:
        extremeMax[mask] = signedValue
  var farthestDistance = int64(0)
  for mask in 0 .. signCount - 1:
    let spread = extremeMax[mask] - extremeMin[mask]
    if spread > farthestDistance:
      farthestDistance = spread
  appendOutput($farthestDistance)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
