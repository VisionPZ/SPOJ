const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

proc appendInteger(value: int) =
  if value == 0:
    outputBuffer.add '0'
    flushIfReady()
    return
  var digitStore: array[20, char]
  var digitCount = 0
  var remaining = value
  while remaining > 0:
    digitStore[digitCount] = char(remaining mod 10 + firstDigitValue)
    digitCount += 1
    remaining = remaining div 10
  for index in countdown(digitCount - 1, 0):
    outputBuffer.add digitStore[index]
  flushIfReady()
proc appendFraction(fraction: int) =
  var digitStore: array[6, char]
  var remaining = fraction
  for index in countdown(5, 0):
    digitStore[index] = char(remaining mod 10 + firstDigitValue)
    remaining = remaining div 10
  var digitCount = 6
  while digitCount > 0 and digitStore[digitCount - 1] == '0':
    digitCount -= 1
  if digitCount > 0:
    outputBuffer.add '.'
    for index in 0..<digitCount:
      outputBuffer.add digitStore[index]
  flushIfReady()

proc appendDecimal(scaledValue: int) =
  appendInteger(scaledValue div 1000000)
  appendFraction(scaledValue mod 1000000)
proc integerSquareRoot(target: int): int =
  var low = 0
  var high = 1000000000
  while low < high:
    let middle = (low + high + 1) div 2
    if middle <= target div middle:
      low = middle
    else:
      high = middle - 1
  return low

let testCount = nextNumber(inputData, scanPos)
for caseIndex in 0..<testCount:
  let number = nextNumber(inputData, scanPos)
  if number < 0:
    appendOutput("invalid")
  elif number == 0:
    appendOutput("0 ")
  else:
    let target = number * 1000000 * 1000000
    let root = integerSquareRoot(target)
    var scaledValue = root
    if 4 * root * root + 4 * root + 1 <= 4 * target:
      scaledValue += 1
    appendDecimal(scaledValue)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
