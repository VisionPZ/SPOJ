import strutils

const flushBlockBytes = 1 shl 17
const decimalPlaces = 2

proc readAllInput(): string =
  var inputData = ""
  var line: string
  while readLine(stdin, line):
    inputData.add line
    inputData.add "\n"
  return inputData

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var negativeValue = inputData[scanPos] == '-'
  if negativeValue: scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return if negativeValue: -value else: value

proc fixedString(value: float, places: int): string =
  var scale = 1
  for _ in 1 .. places: scale = scale * 10
  var absoluteValue = if value < 0.0: -value else: value
  var rounded = int64(absoluteValue * float(scale) + 0.5)
  var wholePart = rounded div int64(scale)
  var fractionPart = rounded mod int64(scale)
  var fractionText = $fractionPart
  while fractionText.len < places: fractionText = "0" & fractionText
  var result: string
  if value < 0.0 and rounded > 0: result.add "-"
  result.add $wholePart
  result.add "."
  result.add fractionText
  return result

var inputData = readAllInput()
var scanPos = 0
var caseCount = nextInt(inputData, scanPos)
var outputBuffer: string
for _ in 1 .. caseCount:
  var pointCount = nextInt(inputData, scanPos)
  var firstX = nextInt(inputData, scanPos)
  var firstY = nextInt(inputData, scanPos)
  var previousX = firstX
  var previousY = firstY
  var crossSum = 0.0
  var weightedXSum = 0.0
  var weightedYSum = 0.0
  for _ in 1 .. pointCount - 1:
    var currentX = nextInt(inputData, scanPos)
    var currentY = nextInt(inputData, scanPos)
    var crossValue = float(previousX * currentY - currentX * previousY)
    crossSum = crossSum + crossValue
    weightedXSum = weightedXSum + crossValue * float(previousX + currentX)
    weightedYSum = weightedYSum + crossValue * float(previousY + currentY)
    previousX = currentX
    previousY = currentY
  var closingCross = float(previousX * firstY - firstX * previousY)
  crossSum = crossSum + closingCross
  weightedXSum = weightedXSum + closingCross * float(previousX + firstX)
  weightedYSum = weightedYSum + closingCross * float(previousY + firstY)
  var gravityX = weightedXSum / (3.0 * crossSum)
  var gravityY = weightedYSum / (3.0 * crossSum)
  outputBuffer.add fixedString(gravityX, decimalPlaces)
  outputBuffer.add " "
  outputBuffer.add fixedString(gravityY, decimalPlaces)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
