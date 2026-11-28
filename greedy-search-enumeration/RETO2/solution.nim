const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sonyaStart = nextInt64(inputData, scanPos)
let sonyaEnd = nextInt64(inputData, scanPos)
let filyaStart = nextInt64(inputData, scanPos)
let filyaEnd = nextInt64(inputData, scanPos)
let preenMoment = nextInt64(inputData, scanPos)
var overlapStart = sonyaStart
if filyaStart > overlapStart:
  overlapStart = filyaStart
var overlapEnd = sonyaEnd
if filyaEnd < overlapEnd:
  overlapEnd = filyaEnd
if overlapStart > overlapEnd:
  appendOutput("0\n")
else:
  var answer = overlapEnd - overlapStart + 1
  if preenMoment >= overlapStart and preenMoment <= overlapEnd:
    answer -= 1
  appendOutput($answer & "\n")
stdout.write outputBuffer
