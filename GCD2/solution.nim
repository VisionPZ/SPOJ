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

proc remainderOfDigits(digits: string, divisor: int): int =
  var remainder = 0
  for digitChar in digits:
    remainder = (remainder * 10 + int(digitChar) - firstDigitValue) mod divisor
  return remainder

proc gcdValues(firstValue: int, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let nextRemainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = nextRemainder
  return leftValue

proc trimmedDigits(digits: string): string =
  var firstIndex = 0
  while firstIndex < digits.len - 1 and digits[firstIndex] == '0':
    firstIndex += 1
  return digits[firstIndex .. digits.len - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let pairCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. pairCount - 1:
  let smallValue = nextInt(inputData, scanPos)
  let bigDigits = nextDigits(inputData, scanPos)
  if smallValue == 0:
    appendOutput(trimmedDigits(bigDigits))
  else:
    let smallRemainder = remainderOfDigits(bigDigits, smallValue)
    appendOutput($gcdValues(smallValue, smallRemainder))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
