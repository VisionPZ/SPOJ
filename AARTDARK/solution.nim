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

proc nextPixel(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let imageCount = nextInt(inputData, scanPos)
for imageIndex in 0 .. imageCount - 1:
  let sideLength = nextInt(inputData, scanPos)
  let pixelCount = sideLength * sideLength
  var darkPixels = 0
  for pixelIndex in 0 .. pixelCount - 1:
    let pixelValue = nextPixel(inputData, scanPos)
    if pixelValue == '*':
      darkPixels += 1
  appendOutput($(float(darkPixels) / float(pixelCount)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
