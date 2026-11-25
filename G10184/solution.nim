const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const riceDenominator: int64 = 8
const chickenDenominator: int64 = 16
const costDenominator: int64 = 16
const hundredScale: int64 = 100

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): tuple[value: int64, found: bool] =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  result.found = pos < data.len
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  result.value = value

proc formatAmount(numerator: int64, denominator: int64): string =
  let scaledTotal = numerator * hundredScale
  var scaledValue = scaledTotal div denominator
  let remainder = scaledTotal mod denominator
  if remainder * 2 >= denominator:
    scaledValue += 1
  let wholePart = scaledValue div hundredScale
  let centPart = scaledValue mod hundredScale
  if centPart == 0:
    result = $wholePart
  elif centPart < 10:
    result = $wholePart & ".0" & $centPart
  else:
    result = $wholePart & "." & $centPart

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let dinerResult = nextNumber(inputData, scanPos)
  if not dinerResult.found:
    break
  let riceResult = nextNumber(inputData, scanPos)
  let chickenResult = nextNumber(inputData, scanPos)
  let dinerCount = dinerResult.value
  let ricePrice = riceResult.value
  let chickenPrice = chickenResult.value
  if dinerCount == 0 and ricePrice == 0 and chickenPrice == 0:
    break
  let riceText = formatAmount(dinerCount, riceDenominator)
  let chickenText = formatAmount(dinerCount, chickenDenominator)
  let costNumerator = dinerCount * (2 * ricePrice + chickenPrice)
  let costText = formatAmount(costNumerator, costDenominator)
  appendOutput(riceText)
  appendOutput(" ")
  appendOutput(chickenText)
  appendOutput(" ")
  appendOutput(costText)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
