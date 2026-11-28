const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc reverseDigits(value: string): string =
  result = newString(value.len)
  for digitIndex in 0 ..< value.len:
    result[digitIndex] = value[value.len - 1 - digitIndex]

proc doubleDecimal(value: string): string =
  var reversedDigits = ""
  var carry = 0
  for digitIndex in countdown(value.len - 1, 0):
    let digitValue = int(value[digitIndex]) - firstDigitValue
    let doubledValue = digitValue * 2 + carry
    reversedDigits.add char(doubledValue mod 10 + firstDigitValue)
    carry = doubledValue div 10
  if carry > 0:
    reversedDigits.add char(carry + firstDigitValue)
  return reverseDigits(reversedDigits)

proc decrementDecimal(value: string): string =
  var digits = newString(value.len)
  for digitIndex in 0 ..< value.len:
    digits[digitIndex] = value[digitIndex]
  var borrowIndex = value.len - 1
  while borrowIndex >= 0 and digits[borrowIndex] == '0':
    digits[borrowIndex] = '9'
    borrowIndex -= 1
  if borrowIndex >= 0:
    digits[borrowIndex] = char(int(digits[borrowIndex]) - 1)
  var firstNonZero = 0
  while firstNonZero < digits.len - 1 and digits[firstNonZero] == '0':
    firstNonZero += 1
  return digits[firstNonZero .. digits.len - 1]

proc bishopsAnswer(boardSize: string): string =
  if boardSize == "0": return "0"
  if boardSize == "1": return "1"
  return doubleDecimal(decrementDecimal(boardSize))

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  if tokenStart == pos:
    return ""
  var firstDigit = tokenStart
  while firstDigit < pos - 1 and data[firstDigit] == '0':
    firstDigit += 1
  return data[firstDigit .. pos - 1]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

while true:
  let boardSize = nextToken(inputData, scanPos)
  if boardSize.len == 0: break
  outputBuffer.add bishopsAnswer(boardSize)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
