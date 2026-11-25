const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextCommand(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

proc nextSigned(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    return -value
  return value

proc nextDigitText(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var digits = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    digits.add data[pos]
    pos += 1
  return digits

proc convertToNegabase(decimalValue: int64, baseValue: int64): string =
  if decimalValue == 0:
    return "0"
  let positiveBase = -baseValue
  var current = decimalValue
  var reversedDigits = ""
  while current != 0:
    var remainder = current mod positiveBase
    if remainder < 0:
      remainder = remainder + positiveBase
    reversedDigits.add char(int(remainder) + 48)
    current = (current - remainder) div baseValue
  var forwardDigits = ""
  for index in 0 .. reversedDigits.len - 1:
    forwardDigits.add reversedDigits[reversedDigits.len - 1 - index]
  return forwardDigits

proc convertFromNegabase(digitText: string, baseValue: int64): int64 =
  var value: int64 = 0
  for index in 0 .. digitText.len - 1:
    value = value * baseValue + int64(int(digitText[index]) - 48)
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let command = nextCommand(inputData, scanPos)
  if command == "" or command == "end":
    break
  let baseValue = nextSigned(inputData, scanPos)
  if command == "to":
    let decimalValue = nextSigned(inputData, scanPos)
    appendOutput(convertToNegabase(decimalValue, baseValue))
  else:
    let digitText = nextDigitText(inputData, scanPos)
    appendOutput($convertFromNegabase(digitText, baseValue))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
