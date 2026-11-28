const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const lowerBase = 97
const upperBase = 65

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
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var availableKeys = newSeq[int](alphabetSize)
for caseIndex in 0 .. caseCount - 1:
  let roomCount = nextInt(inputData, scanPos)
  let plan = nextToken(inputData, scanPos)
  for letterIndex in 0 .. alphabetSize - 1:
    availableKeys[letterIndex] = 0
  var boughtKeys = 0
  var doorIndex = 0
  while doorIndex < roomCount - 1:
    let keyLetter = plan[2 * doorIndex]
    availableKeys[int(keyLetter) - lowerBase] += 1
    let doorLetter = plan[2 * doorIndex + 1]
    let neededKey = int(doorLetter) - upperBase
    if availableKeys[neededKey] > 0:
      availableKeys[neededKey] -= 1
    else:
      boughtKeys += 1
    doorIndex += 1
  appendOutput($boughtKeys)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
