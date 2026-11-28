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

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let elementCount = rowCount * columnCount
var smallestValue = nextInt(inputData, scanPos)
var elementsRead = 1
while elementsRead < elementCount:
  let currentValue = nextInt(inputData, scanPos)
  if currentValue < smallestValue:
    smallestValue = currentValue
  elementsRead += 1
appendOutput($smallestValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
