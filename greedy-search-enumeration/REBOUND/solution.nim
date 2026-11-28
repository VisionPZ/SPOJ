const flushBlockBytes = 1 shl 17
const rootSearchLimit = 2000000000

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

proc integerSquareRoot(value: int64): int64 =
  var lowValue: int64 = 0
  var highValue: int64 = rootSearchLimit
  while lowValue < highValue:
    let middleValue = (lowValue + highValue + 1) div 2
    if middleValue * middleValue <= value:
      lowValue = middleValue
    else:
      highValue = middleValue - 1
  return lowValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let horizontalDistance = int64(nextInt(inputData, scanPos))
  let targetHeight = int64(nextInt(inputData, scanPos))
  let throwHeight = int64(nextInt(inputData, scanPos))
  let discriminant = horizontalDistance * horizontalDistance +
                     targetHeight * targetHeight + 2 * targetHeight * throwHeight
  let reflectionRoot = integerSquareRoot(discriminant)
  if reflectionRoot * reflectionRoot != discriminant:
    appendOutput("Not this time.\n")
  else:
    let numeratorValue = throwHeight * (horizontalDistance + reflectionRoot)
    let denominatorValue = targetHeight + 2 * throwHeight
    if numeratorValue mod denominatorValue != 0:
      appendOutput("Not this time.\n")
    else:
      let landingPoint = numeratorValue div denominatorValue
      if landingPoint < 0 or landingPoint > horizontalDistance:
        appendOutput("Not this time.\n")
      else:
        appendOutput($landingPoint)
        outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
