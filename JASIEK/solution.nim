const flushBlockBytes = 1 shl 18

var inputData = ""
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer

var outputBuffer = ""

var scanPos = 0
var centerX: int64 = 0
var centerY: int64 = 0
var doubledArea: int64 = 0
var moveCount: int64 = 0
var insideDescription = false

while scanPos < inputData.len:
  let currentChar = inputData[scanPos]
  scanPos += 1
  if currentChar == 'P':
    insideDescription = true
    centerX = 0
    centerY = 0
    doubledArea = 0
    moveCount = 0
  elif currentChar == 'K':
    if insideDescription:
      let areaValue = if doubledArea < 0: -doubledArea else: doubledArea
      let squareCount = (areaValue + moveCount + 2) div 2
      outputBuffer.add $squareCount
      outputBuffer.add '\n'
      if outputBuffer.len >= flushBlockBytes:
        stdout.write outputBuffer
        outputBuffer.setLen 0
    insideDescription = false
  elif insideDescription:
    var stepX = 0
    var stepY = 0
    case currentChar
    of 'N':
      stepY = 1
    of 'S':
      stepY = -1
    of 'E':
      stepX = 1
    of 'W':
      stepX = -1
    else:
      continue
    doubledArea += centerX * int64(stepY) - int64(stepX) * centerY
    centerX += int64(stepX)
    centerY += int64(stepY)
    moveCount += 1

stdout.write outputBuffer
