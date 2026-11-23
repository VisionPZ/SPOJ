const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value

proc combineCount(marbleCount, colorCount: int): int64 =
  var chosenColors = colorCount
  if marbleCount - chosenColors < chosenColors - 1:
    chosenColors = marbleCount - chosenColors + 1
  var ways: int64 = 1
  for step in 1 .. chosenColors - 1:
    ways = ways * int64(marbleCount - step) div int64(step)
  return ways

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var scanPos = 0
var caseCount = nextInt(inputData, scanPos)
var outputBuffer: string
for caseIndex in 1 .. caseCount:
  var marbleCount = nextInt(inputData, scanPos)
  var colorCount = nextInt(inputData, scanPos)
  outputBuffer.add $combineCount(marbleCount, colorCount)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
