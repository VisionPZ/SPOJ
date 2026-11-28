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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let elementCount = nextInt(inputData, scanPos)
for skipIndex in 0..<elementCount:
  discard nextInt(inputData, scanPos)

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0..<queryCount:
  let leftIndex = nextInt(inputData, scanPos)
  let rightIndex = nextInt(inputData, scanPos)
  let evenIndexCount = rightIndex div 2 - (leftIndex - 1) div 2
  if evenIndexCount mod 2 == 0:
    appendOutput("Even\n")
  else:
    appendOutput("Odd\n")

stdout.write outputBuffer
outputBuffer.setLen 0
