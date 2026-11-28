const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const transformDigits = "0125986"
const baseValue = 7

proc nextDigitToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  return data[tokenStart .. pos - 1]

proc tokenToInt(token: string): int =
  var value = 0
  for digitChar in token:
    value = value * 10 + int(digitChar) - firstDigitValue
  return value

proc divideBySeven(value: string): tuple[remainder: int, quotient: string] =
  var quotient = ""
  var remainder = 0
  for digitChar in value:
    let current = remainder * 10 + int(digitChar) - firstDigitValue
    let digit = current div baseValue
    remainder = current mod baseValue
    if quotient.len > 0 or digit > 0:
      quotient.add chr(firstDigitValue + digit)
  return (remainder, quotient)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = tokenToInt(nextDigitToken(inputData, scanPos))
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for _ in 0 ..< caseCount:
  var currentValue = nextDigitToken(inputData, scanPos)
  var answerText = ""
  while currentValue.len > 0:
    let divided = divideBySeven(currentValue)
    answerText.add transformDigits[divided.remainder]
    currentValue = divided.quotient
  appendOutput(answerText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
