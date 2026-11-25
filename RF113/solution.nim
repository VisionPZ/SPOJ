const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    inc pos
  if pos >= data.len:
    return 0
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    inc pos
  return value

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

while scanPos < inputData.len:
  let dimension = nextInt(inputData, scanPos)
  if dimension == 0:
    break
  if dimension < 0:
    break
  let columnCount = int(dimension)
  let cellCount = columnCount * columnCount
  var diagonalIsZero = true
  for cell in 0..<cellCount:
    let cellValue = nextInt(inputData, scanPos)
    if cell mod (columnCount + 1) == 0 and cellValue != 0:
      diagonalIsZero = false
  if diagonalIsZero:
    appendOutput("true\n")
  else:
    appendOutput("false\n")

stdout.write outputBuffer
outputBuffer.setLen 0
