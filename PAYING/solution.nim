const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const decimalBase = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextNumberBounds(data: string, position: var int, numberStart: var int, numberEnd: var int) =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  numberStart = position
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    position += 1
  numberEnd = position

proc coinCount(data: string, numberStart: int, numberEnd: int): int =
  var digits: seq[int] = @[0]
  for parseIndex in numberStart..<numberEnd:
    digits.add int(data[parseIndex]) - firstDigitValue

  var carryOver = 1
  var carryIndex = digits.len - 1
  while carryOver > 0:
    let updatedDigit = digits[carryIndex] + carryOver
    digits[carryIndex] = updatedDigit mod decimalBase
    carryOver = updatedDigit div decimalBase
    carryIndex -= 1

  var firstDigit = 0
  while firstDigit < digits.len and digits[firstDigit] == 0:
    firstDigit += 1
  var digitCount = digits.len - firstDigit

  var bitLength = 0
  var setBits = 0
  while digitCount > 0:
    bitLength += 1
    var halfCarry = 0
    for digitOffset in 0..<digitCount:
      let digitIndex = firstDigit + digitOffset
      let currentValue = halfCarry * decimalBase + digits[digitIndex]
      digits[digitIndex] = currentValue div 2
      halfCarry = currentValue mod 2
    setBits += halfCarry
    while digitCount > 0 and digits[firstDigit] == 0:
      firstDigit += 1
      digitCount -= 1

  return bitLength + setBits - 2

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  var numberStart = 0
  var numberEnd = 0
  nextNumberBounds(inputData, scanPos, numberStart, numberEnd)
  appendOutput($coinCount(inputData, numberStart, numberEnd))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
