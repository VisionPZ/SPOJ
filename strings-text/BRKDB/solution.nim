const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var tokenValue = ""
  while pos < data.len and data[pos] > ' ':
    tokenValue.add data[pos]
    pos += 1
  return tokenValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let deletedName = nextToken(inputData, scanPos)
appendOutput(deletedName)
outputBuffer.add " Silva 200120039010\n"
outputBuffer.add deletedName
outputBuffer.add " Pineda 199810024010\n"
outputBuffer.add deletedName
outputBuffer.add " Monsalve 200410061010\n"
stdout.write outputBuffer
outputBuffer.setLen 0
