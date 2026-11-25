import algorithm

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextForm(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'b' and data[pos] != 'd':
    pos += 1
  let foundForm = data[pos]
  pos += 1
  return foundForm

proc nextLong(data: string, pos: var int, inputForm: char): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let numberBase = if inputForm == 'b': 2 else: 10
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * int64(numberBase) + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc toBinaryString(value: int64): string =
  if value == 0:
    return "0"
  var reversedDigits = ""
  var remaining = value
  while remaining > 0:
    reversedDigits.add chr(int(remaining mod 2) + 48)
    remaining = remaining div 2
  var forwardDigits = ""
  var digitIndex = reversedDigits.len - 1
  while digitIndex >= 0:
    forwardDigits.add reversedDigits[digitIndex]
    digitIndex -= 1
  return forwardDigits

proc compareValues(leftValue, rightValue: int64): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberCount = nextInt(inputData, scanPos)
var sortedValues = newSeq[int64](numberCount)
var binaryForms = 0
var decimalForms = 0
for itemIndex in 0 .. numberCount - 1:
  let inputForm = nextForm(inputData, scanPos)
  sortedValues[itemIndex] = nextLong(inputData, scanPos, inputForm)
  if inputForm == 'b':
    binaryForms += 1
  else:
    decimalForms += 1
sortedValues.sort(compareValues)
let printBinary = binaryForms > decimalForms
for valueIndex in 0 .. numberCount - 1:
  if printBinary:
    appendOutput(toBinaryString(sortedValues[valueIndex]))
  else:
    appendOutput($sortedValues[valueIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
