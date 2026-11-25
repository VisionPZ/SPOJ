const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let notation = nextToken(inputData, scanPos)
var decimalPoint = 0
var exponentMark = 0
for charIndex in 0..<notation.len:
  if notation[charIndex] == '.':
    decimalPoint = charIndex
  elif notation[charIndex] == 'e':
    exponentMark = charIndex

var digitString = ""
digitString.add notation[0]
for charIndex in (decimalPoint + 1)..<exponentMark:
  digitString.add notation[charIndex]

var exponentValue = 0
for charIndex in (exponentMark + 1)..<notation.len:
  exponentValue = exponentValue * 10 + int(notation[charIndex]) - firstDigitValue

let fractionLength = exponentMark - decimalPoint - 1
var resultText = ""
if exponentValue >= fractionLength:
  resultText.add digitString
  for zeroIndex in 0..<(exponentValue - fractionLength):
    resultText.add '0'
else:
  let integerLength = 1 + exponentValue
  for charIndex in 0..<integerLength:
    resultText.add digitString[charIndex]
  var fractionEnd = digitString.len
  while fractionEnd > integerLength and digitString[fractionEnd - 1] == '0':
    fractionEnd -= 1
  if fractionEnd > integerLength:
    resultText.add '.'
    for charIndex in integerLength..<fractionEnd:
      resultText.add digitString[charIndex]

appendOutput(resultText)
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
