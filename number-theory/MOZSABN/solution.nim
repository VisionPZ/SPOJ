const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let binaryDigits = nextToken(inputData, scanPos)
var setBitCount = 0
for index in 0..<binaryDigits.len:
  if binaryDigits[index] == '1':
    setBitCount += 1
appendOutput($(setBitCount) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
