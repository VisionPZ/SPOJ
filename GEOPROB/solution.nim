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

proc nextDigits(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var token = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    token.add data[pos]
    pos += 1
  return token

proc digitValues(token: string): seq[int] =
  var digits = newSeq[int](token.len)
  for index in 0 .. token.len - 1:
    digits[index] = int(token[token.len - 1 - index]) - firstDigitValue
  var length = digits.len
  while length > 1 and digits[length - 1] == 0:
    length -= 1
  digits.setLen(length)
  return digits

proc doubledDigits(digits: seq[int]): seq[int] =
  var doubledResult = newSeq[int](digits.len + 1)
  var carry = 0
  for index in 0 .. digits.len - 1:
    let doubled = digits[index] * 2 + carry
    doubledResult[index] = doubled mod 10
    carry = doubled div 10
  doubledResult[digits.len] = carry
  if carry == 0:
    doubledResult.setLen(digits.len)
  return doubledResult

proc subtractDigits(leftDigits: seq[int], rightDigits: seq[int]): seq[int] =
  var subtractedResult = newSeq[int](leftDigits.len)
  var borrow = 0
  for index in 0 .. leftDigits.len - 1:
    var digitValue = leftDigits[index] - borrow
    if index < rightDigits.len:
      digitValue -= rightDigits[index]
    if digitValue < 0:
      digitValue += 10
      borrow = 1
    else:
      borrow = 0
    subtractedResult[index] = digitValue
  var length = subtractedResult.len
  while length > 1 and subtractedResult[length - 1] == 0:
    length -= 1
  subtractedResult.setLen(length)
  return subtractedResult

proc digitsToString(digits: seq[int]): string =
  var text = ""
  var index = digits.len - 1
  while index >= 0:
    text.add char(digits[index] + firstDigitValue)
    index -= 1
  return text

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let bToken = nextDigits(inputData, scanPos)
  let cToken = nextDigits(inputData, scanPos)
  let dToken = nextDigits(inputData, scanPos)
  var answerDigits = doubledDigits(digitValues(cToken))
  answerDigits = subtractDigits(answerDigits, digitValues(bToken))
  answerDigits = subtractDigits(answerDigits, digitValues(dToken))
  appendOutput(digitsToString(answerDigits))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
