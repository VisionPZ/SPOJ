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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberCount = nextInt(inputData, scanPos)
var unionBits = 0
var intersectionBits = 0
if numberCount > 0:
  let firstNumber = nextInt(inputData, scanPos)
  unionBits = firstNumber
  intersectionBits = firstNumber
for numberIndex in 1 .. numberCount - 1:
  let currentNumber = nextInt(inputData, scanPos)
  unionBits = unionBits or currentNumber
  intersectionBits = intersectionBits and currentNumber
appendOutput($(unionBits xor intersectionBits))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
