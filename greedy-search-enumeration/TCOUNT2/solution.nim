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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let rawLevel = nextInt(inputData, scanPos)
  if rawLevel == 0:
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  var currentLevel = uint64(rawLevel)
  var triangleTotal: uint64 = 0'u64
  if (currentLevel and 1'u64) == 0'u64:
    triangleTotal = 3'u64 * currentLevel * (3'u64 * currentLevel - 1'u64) +
                    3'u64 * currentLevel * (currentLevel - 2'u64) div 2'u64 + 2'u64
    currentLevel = currentLevel - 1'u64
  triangleTotal = triangleTotal +
                  currentLevel * ((7'u64 * currentLevel * currentLevel + 1'u64) div 2'u64) +
                  ((3'u64 * currentLevel + 1'u64) div 2'u64) *
                  ((3'u64 * currentLevel - 1'u64) div 2'u64)
  appendOutput($triangleTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
