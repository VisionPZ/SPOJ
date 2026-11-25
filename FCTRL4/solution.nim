const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const divisorValue = 5
const smallFactorials = [1, 1, 2, 6, 4]
const powerPattern = [6, 2, 4, 8]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDigits(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let firstDigitPos = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  return data[firstDigitPos ..< pos]

proc divideByFive(numberText: string, quotientText: var string): int =
  quotientText = ""
  var remainderValue = 0
  for digitChar in numberText:
    let partialValue = remainderValue * 10 + int(digitChar) - firstDigitValue
    let quotientDigit = partialValue div divisorValue
    remainderValue = partialValue mod divisorValue
    if quotientText.len > 0 or quotientDigit > 0:
      quotientText.add chr(quotientDigit + firstDigitValue)
  return remainderValue

proc remainderModFour(numberText: string): int =
  var remainderValue = 0
  for digitChar in numberText:
    remainderValue = (remainderValue * 10 + int(digitChar) - firstDigitValue) mod 4
  return remainderValue

proc lastNonZeroDigit(numberText: string): int =
  var quotientText = ""
  let remainderValue = divideByFive(numberText, quotientText)
  if quotientText.len == 0:
    return smallFactorials[remainderValue]
  let exponentParity = remainderModFour(quotientText)
  return (lastNonZeroDigit(quotientText) * smallFactorials[remainderValue] * powerPattern[exponentParity]) mod 10

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let numberText = nextDigits(inputData, scanPos)
  if numberText.len == 0:
    break
  let answerDigit = lastNonZeroDigit(numberText)
  appendOutput($answerDigit)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
