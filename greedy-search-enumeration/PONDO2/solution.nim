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

proc nextLandString(data: string, pos: var int): string =
  while pos < data.len and data[pos] != 'u' and data[pos] != 'o':
    pos += 1
  var land = ""
  while pos < data.len and (data[pos] == 'u' or data[pos] == 'o'):
    land.add data[pos]
    pos += 1
  return land

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let landLength = nextInt(inputData, scanPos)
let land = nextLandString(inputData, scanPos)
var landBalance = 0
var givenLength = 0
var bestLength = 0
var landIndex = landLength - 1
while landIndex >= 0:
  if land[landIndex] == 'o':
    landBalance += 1
  else:
    landBalance -= 1
  givenLength += 1
  if landBalance >= 0:
    bestLength = givenLength
  landIndex -= 1
appendOutput($bestLength)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
