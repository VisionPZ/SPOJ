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

let wordLength = nextInt(inputData, scanPos)
var endingZero: int64 = 1
var endingOne: int64 = 1
var endingTwo: int64 = 1
if wordLength <= 0:
  appendOutput("1")
else:
  var position = 1
  while position < wordLength:
    let nextZero = endingZero + endingOne
    let nextOne = endingZero + endingOne + endingTwo
    let nextTwo = endingOne + endingTwo
    endingZero = nextZero
    endingOne = nextOne
    endingTwo = nextTwo
    position += 1
  appendOutput($(endingZero + endingOne + endingTwo))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
