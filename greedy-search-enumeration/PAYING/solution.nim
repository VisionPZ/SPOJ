const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const decimalBase = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc nextNumberBounds(data: string, i: var int, numberStart: var int, numberEnd: var int) =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  numberStart = i
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    i += 1
  numberEnd = i

proc coinCount(data: string, numberStart: int, numberEnd: int): int =
  var digits: seq[int] = @[0]
  for i in numberStart..<numberEnd:
    digits.add int(data[i]) - firstDigitValue

  var carryOver = 1
  var j = digits.len - 1
  while carryOver > 0:
    let updatedDigit = digits[j] + carryOver
    digits[j] = updatedDigit mod decimalBase
    carryOver = updatedDigit div decimalBase
    j -= 1

  var k = 0
  while k < digits.len and digits[k] == 0:
    k += 1
  var digitCount = digits.len - k

  var bitLength = 0
  var setBits = 0
  while digitCount > 0:
    bitLength += 1
    var halfCarry = 0
    for l in 0..<digitCount:
      let i = k + l
      let currentValue = halfCarry * decimalBase + digits[i]
      digits[i] = currentValue div 2
      halfCarry = currentValue mod 2
    setBits += halfCarry
    while digitCount > 0 and digits[k] == 0:
      k += 1
      digitCount -= 1

  return bitLength + setBits - 2

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  var numberStart = 0
  var numberEnd = 0
  nextNumberBounds(inputData, i, numberStart, numberEnd)
  appendOutput($coinCount(inputData, numberStart, numberEnd))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
