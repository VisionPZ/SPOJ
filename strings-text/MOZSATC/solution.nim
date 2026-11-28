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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sourceText = nextToken(inputData, scanPos)
let allowedCommas = nextInt(inputData, scanPos)
var leftBound = 0
var commaCount = 0
var bestLength = 0
for rightBound in 0 .. sourceText.len - 1:
  if sourceText[rightBound] == ',':
    commaCount += 1
  while commaCount > allowedCommas:
    if sourceText[leftBound] == ',':
      commaCount -= 1
    leftBound += 1
  let windowLength = rightBound - leftBound + 1
  if windowLength > bestLength:
    bestLength = windowLength
appendOutput($bestLength)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
