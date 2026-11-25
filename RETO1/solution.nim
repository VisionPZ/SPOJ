const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let wordCount = nextInt(inputData, scanPos)
let delay = nextInt(inputData, scanPos)
var remainingCount = 1
var previousTime = nextInt(inputData, scanPos)
for wordIndex in 1 ..< wordCount:
  let currentTime = nextInt(inputData, scanPos)
  if currentTime - previousTime > delay:
    remainingCount = 1
  else:
    remainingCount += 1
  previousTime = currentTime
appendOutput($remainingCount & "\n")
stdout.write outputBuffer
