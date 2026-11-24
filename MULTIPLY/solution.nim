{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, position: var int): int64 {.inline.} =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(int(data[position]) - firstDigitValue)
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) {.inline.} =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while i < inputData.len:
  let firstValue = nextInt(inputData, i)
  if i >= inputData.len: break
  let secondValue = nextInt(inputData, i)
  appendOutput($(firstValue * secondValue))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
