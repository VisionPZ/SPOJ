import strutils

const flushBlockBytes = 1 shl 17
const circleConstant = 3.141592653589793
const epsilonOffset = 0.0000001
const feasibilityMargin = 0.000000001

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

proc cylinderVolume(sheetWidth: float, sheetHeight: float, cutPosition: float): float =
  var position = cutPosition
  if position < 0.0:
    position = 0.0
  if position > sheetHeight:
    position = sheetHeight
  let diameter = min(sheetWidth, position)
  let radius = diameter / 2.0
  let circumference = circleConstant * diameter
  var bestVolume = 0.0
  if sheetWidth + feasibilityMargin >= circumference:
    let rollHeight = sheetHeight - position
    let volume = circleConstant * radius * radius * rollHeight
    if volume > bestVolume:
      bestVolume = volume
  if sheetHeight - position + feasibilityMargin >= circumference:
    let rollHeight = sheetWidth
    let volume = circleConstant * radius * radius * rollHeight
    if volume > bestVolume:
      bestVolume = volume
  return bestVolume

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let sheetWidth = float(nextInt(inputData, scanPos))
  let sheetHeight = float(nextInt(inputData, scanPos))
  if sheetWidth == 0.0 and sheetHeight == 0.0:
    break
  var bestVolume = 0.0
  var candidates = @[sheetWidth, sheetWidth / circleConstant,
                     sheetHeight / (circleConstant + 1.0),
                     sheetHeight - circleConstant * sheetWidth,
                     2.0 * sheetHeight / 3.0, sheetHeight / 2.0,
                     sheetHeight / 3.0, 0.0, sheetHeight]
  for candidate in candidates:
    for offsetIndex in 0 .. 2:
      var offset = 0.0
      if offsetIndex == 0:
        offset = -epsilonOffset
      elif offsetIndex == 2:
        offset = epsilonOffset
      let volume = cylinderVolume(sheetWidth, sheetHeight, candidate + offset)
      if volume > bestVolume:
        bestVolume = volume
  appendOutput(formatFloat(bestVolume, ffDecimal, 3))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
