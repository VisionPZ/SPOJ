const flushBlockBytes = 1 shl 17
const digitKinds = 10

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

proc countDigitUpTo(limitValue: int64, digitValue: int): int64 =
  if limitValue <= 0:
    return 0
  var placeValue: int64 = 1
  while placeValue <= limitValue:
    let higherPart = limitValue div (placeValue * 10)
    let currentDigit = (limitValue div placeValue) mod 10
    let lowerPart = limitValue mod placeValue
    if digitValue == 0:
      if higherPart != 0:
        if currentDigit == 0:
          result += (higherPart - 1) * placeValue + lowerPart + 1
        else:
          result += (higherPart - 1) * placeValue + placeValue
    else:
      result += higherPart * placeValue
      if currentDigit > int64(digitValue):
        result += placeValue
      elif currentDigit == int64(digitValue):
        result += lowerPart + 1
    placeValue *= 10

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let firstValue = int64(nextInt(inputData, scanPos))
  let secondValue = int64(nextInt(inputData, scanPos))
  if firstValue == 0 and secondValue == 0:
    break
  var lowLimit = firstValue
  var highLimit = secondValue
  if lowLimit > highLimit:
    let previousLow = lowLimit
    lowLimit = highLimit
    highLimit = previousLow
  var digitCounts = newSeq[int64](digitKinds)
  for digitValue in 0 .. digitKinds - 1:
    digitCounts[digitValue] = countDigitUpTo(highLimit, digitValue) - countDigitUpTo(lowLimit - 1, digitValue)
  for digitValue in 0 .. digitKinds - 1:
    if digitValue > 0:
      appendOutput " "
    appendOutput($digitCounts[digitValue])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
