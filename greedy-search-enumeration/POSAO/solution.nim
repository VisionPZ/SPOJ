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

let gridSize = nextInt(inputData, scanPos)
let computerCount = nextInt(inputData, scanPos)
var totalSeconds: int64 = 0
if computerCount >= gridSize:
  totalSeconds = int64(2 * gridSize - 1)
else:
  let jobTotal = int64(gridSize) * int64(gridSize)
  let machineCount = int64(computerCount)
  totalSeconds = machineCount + jobTotal div machineCount
  if jobTotal mod machineCount == 0:
    totalSeconds -= 1
appendOutput($totalSeconds)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
