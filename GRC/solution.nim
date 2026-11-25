const flushBlockBytes = 1 shl 17
const stickerCount = 54

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

proc nextLine(data: string, pos: var int): string =
  var line = ""
  while pos < data.len and data[pos] != '\n':
    line.add data[pos]
    pos += 1
  if pos < data.len:
    pos += 1
  return line

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var positionX = newSeq[int](stickerCount)
var positionY = newSeq[int](stickerCount)
var positionZ = newSeq[int](stickerCount)
var normalX = newSeq[int](stickerCount)
var normalY = newSeq[int](stickerCount)
var normalZ = newSeq[int](stickerCount)
var stickerColor = newSeq[int](stickerCount)

proc colorCode(letter: char): int =
  case letter
  of 'Y': return 0
  of 'R': return 1
  of 'B': return 2
  of 'G': return 3
  of 'W': return 4
  of 'M': return 5
  else: return -1

proc placeSticker(faceNumber: int, row: int, column: int, color: int) =
  let stickerIndex = (faceNumber - 1) * 9 + row * 3 + column
  stickerColor[stickerIndex] = color
  case faceNumber
  of 1:
    positionX[stickerIndex] = -1
    positionY[stickerIndex] = 1 - row
    positionZ[stickerIndex] = column - 1
    normalX[stickerIndex] = -1
    normalY[stickerIndex] = 0
    normalZ[stickerIndex] = 0
  of 2:
    positionX[stickerIndex] = column - 1
    positionY[stickerIndex] = 1 - row
    positionZ[stickerIndex] = 1
    normalX[stickerIndex] = 0
    normalY[stickerIndex] = 0
    normalZ[stickerIndex] = 1
  of 3:
    positionX[stickerIndex] = 1
    positionY[stickerIndex] = 1 - row
    positionZ[stickerIndex] = 1 - column
    normalX[stickerIndex] = 1
    normalY[stickerIndex] = 0
    normalZ[stickerIndex] = 0
  of 4:
    positionX[stickerIndex] = 1 - column
    positionY[stickerIndex] = 1 - row
    positionZ[stickerIndex] = -1
    normalX[stickerIndex] = 0
    normalY[stickerIndex] = 0
    normalZ[stickerIndex] = -1
  of 5:
    positionX[stickerIndex] = column - 1
    positionY[stickerIndex] = 1
    positionZ[stickerIndex] = row - 1
    normalX[stickerIndex] = 0
    normalY[stickerIndex] = 1
    normalZ[stickerIndex] = 0
  else:
    positionX[stickerIndex] = column - 1
    positionY[stickerIndex] = -1
    positionZ[stickerIndex] = 1 - row
    normalX[stickerIndex] = 0
    normalY[stickerIndex] = -1
    normalZ[stickerIndex] = 0

proc rotateVector(valueX: var int, valueY: var int, valueZ: var int,
                  axisCode: int, direction: int) =
  case axisCode
  of 0:
    let oldY = valueY
    let oldZ = valueZ
    if direction > 0:
      valueY = -oldZ
      valueZ = oldY
    else:
      valueY = oldZ
      valueZ = -oldY
  of 1:
    let oldX = valueX
    let oldZ = valueZ
    if direction > 0:
      valueX = oldZ
      valueZ = -oldX
    else:
      valueX = -oldZ
      valueZ = oldX
  else:
    let oldX = valueX
    let oldY = valueY
    if direction > 0:
      valueX = -oldY
      valueY = oldX
    else:
      valueX = oldY
      valueY = -oldX

proc applyRotation(rotation: int) =
  let faceNumber = abs(rotation)
  var axisCode = 0
  var layerValue = 0
  var direction = 1
  case faceNumber
  of 1:
    axisCode = 0
    layerValue = -1
    direction = if rotation > 0: 1 else: -1
  of 2:
    axisCode = 2
    layerValue = 1
    direction = if rotation > 0: -1 else: 1
  of 3:
    axisCode = 0
    layerValue = 1
    direction = if rotation > 0: -1 else: 1
  of 4:
    axisCode = 2
    layerValue = -1
    direction = if rotation > 0: 1 else: -1
  of 5:
    axisCode = 1
    layerValue = 1
    direction = if rotation > 0: -1 else: 1
  of 6:
    axisCode = 1
    layerValue = -1
    direction = if rotation > 0: 1 else: -1
  else:
    return
  for stickerIndex in 0 .. stickerCount - 1:
    var inLayer = false
    case axisCode
    of 0: inLayer = positionX[stickerIndex] == layerValue
    of 1: inLayer = positionY[stickerIndex] == layerValue
    else: inLayer = positionZ[stickerIndex] == layerValue
    if inLayer:
      rotateVector(positionX[stickerIndex], positionY[stickerIndex],
                   positionZ[stickerIndex], axisCode, direction)
      rotateVector(normalX[stickerIndex], normalY[stickerIndex],
                   normalZ[stickerIndex], axisCode, direction)

proc isWinning(): bool =
  for axisCode in 0 .. 2:
    for signValue in [-1, 1]:
      var firstColor = -1
      for stickerIndex in 0 .. stickerCount - 1:
        var belongs = false
        case axisCode
        of 0: belongs = normalX[stickerIndex] == signValue and
                        normalY[stickerIndex] == 0 and normalZ[stickerIndex] == 0
        of 1: belongs = normalY[stickerIndex] == signValue and
                        normalX[stickerIndex] == 0 and normalZ[stickerIndex] == 0
        else: belongs = normalZ[stickerIndex] == signValue and
                        normalX[stickerIndex] == 0 and normalY[stickerIndex] == 0
        if belongs:
          if firstColor == -1:
            firstColor = stickerColor[stickerIndex]
          elif stickerColor[stickerIndex] != firstColor:
            return false
  return true

let testCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
if scanPos < inputData.len:
  scanPos += 1
for testIndex in 0 .. testCount - 1:
  for lineIndex in 0 .. 8:
    let gridLine = nextLine(inputData, scanPos)
    var letterIndex = 0
    for characterIndex in 0 .. gridLine.len - 1:
      let letter = gridLine[characterIndex]
      if letter == ' ':
        continue
      var faceNumber = 0
      var row = 0
      var column = 0
      if lineIndex < 3:
        faceNumber = 5
        row = lineIndex
        column = letterIndex
      elif lineIndex < 6:
        faceNumber = letterIndex div 3 + 1
        row = lineIndex - 3
        column = letterIndex mod 3
      else:
        faceNumber = 6
        row = lineIndex - 6
        column = letterIndex
      placeSticker(faceNumber, row, column, colorCode(letter))
      letterIndex += 1
  while true:
    let rotation = nextInt(inputData, scanPos)
    if rotation == 0:
      break
    applyRotation(rotation)
  while scanPos < inputData.len and inputData[scanPos] != '\n':
    scanPos += 1
  if scanPos < inputData.len:
    scanPos += 1
  if isWinning():
    appendOutput("Yes, grandpa!\n")
  else:
    appendOutput("No, you are wrong!\n")
stdout.write outputBuffer
outputBuffer.setLen 0
