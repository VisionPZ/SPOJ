const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextSignedInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value * sign

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberCount = nextInt(inputData, scanPos)
var positiveProduct: int64 = 1
var negativeValues: seq[int] = @[]
for itemIndex in 0..<numberCount:
  let heardValue = nextSignedInt(inputData, scanPos)
  if heardValue > 1:
    positiveProduct = positiveProduct * int64(heardValue)
  elif heardValue < 0:
    negativeValues.add heardValue

for sortIndex in 1..<negativeValues.len:
  let currentValue = negativeValues[sortIndex]
  var cursor = sortIndex - 1
  while cursor >= 0 and negativeValues[cursor] > currentValue:
    negativeValues[cursor + 1] = negativeValues[cursor]
    cursor -= 1
  negativeValues[cursor + 1] = currentValue

var negativeProduct: int64 = 1
var pairIndex = 0
while pairIndex + 1 < negativeValues.len:
  negativeProduct = negativeProduct * int64(negativeValues[pairIndex]) * int64(negativeValues[pairIndex + 1])
  pairIndex += 2

appendOutput($(positiveProduct * negativeProduct) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
