const firstDigitValue = 48
const firstLetterCode = 97
const letterCount = 26
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

proc appendOutput(character: char) =
  outputBuffer.add character
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let stringLength = nextInt(inputData, scanPos)
let letterLimit = nextInt(inputData, scanPos)

for positionIndex in 0..<stringLength:
  let letterIndex = (positionIndex div letterLimit) mod letterCount
  appendOutput(chr(firstLetterCode + letterIndex))
appendOutput('\n')

stdout.write outputBuffer
outputBuffer.setLen 0
