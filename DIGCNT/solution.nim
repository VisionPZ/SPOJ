const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const lastTrackedDigit = 9

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc countDigit(limitValue: int64, digitValue: int): int64 =
  if limitValue <= 0:
    return 0
  var placeValue: int64 = 1
  while placeValue <= limitValue:
    let higherPart = limitValue div (placeValue * 10)
    let currentDigit = (limitValue div placeValue) mod 10
    let lowerPart = limitValue mod placeValue
    if currentDigit > digitValue:
      result += (higherPart + 1) * placeValue
    elif currentDigit == digitValue:
      result += higherPart * placeValue + lowerPart + 1
    else:
      result += higherPart * placeValue
    placeValue *= 10

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let lowerInput = nextInt(inputData, scanPos)
  if lowerInput == 0:
    break
  let upperInput = nextInt(inputData, scanPos)
  var rangeStart = int64(lowerInput)
  var rangeEnd = int64(upperInput)
  if rangeStart > rangeEnd:
    let swapValue = rangeStart
    rangeStart = rangeEnd
    rangeEnd = swapValue
  for digitValue in 1 .. lastTrackedDigit:
    if digitValue > 1:
      appendOutput(" ")
    let digitTotal = countDigit(rangeEnd, digitValue) - countDigit(rangeStart - 1, digitValue)
    appendOutput($digitTotal)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
