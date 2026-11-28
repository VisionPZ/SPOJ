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
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendInteger(value: int) =
  var digitStore: array[12, char]
  var digitCount = 0
  var remaining = value
  while remaining > 0:
    digitStore[digitCount] = char(remaining mod 10 + firstDigitValue)
    digitCount += 1
    remaining = remaining div 10
  for index in countdown(digitCount - 1, 0):
    outputBuffer.add digitStore[index]
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextNumber(inputData, scanPos)
for caseIndex in 0..<testCount:
  let upperBound = nextNumber(inputData, scanPos)
  if upperBound <= 0:
    appendOutput("invalid\n")
  else:
    for value in 1..upperBound:
      if value > 1:
        appendOutput(" ")
      appendInteger(value)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
