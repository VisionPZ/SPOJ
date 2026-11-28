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

let seriesLength = nextInt(inputData, scanPos)
let lowerDistinct = nextInt(inputData, scanPos)
let upperDistinct = nextInt(inputData, scanPos)
var seriesValues = newSeq[int](seriesLength)
for valueIndex in 0 .. seriesLength - 1:
  seriesValues[valueIndex] = nextInt(inputData, scanPos)

var subsequenceCount: int64 = 0
for leftIndex in 0 .. seriesLength - 1:
  var distinctCount = 0
  for rightIndex in leftIndex .. seriesLength - 1:
    var seenBefore = false
    for checkIndex in leftIndex ..< rightIndex:
      if seriesValues[checkIndex] == seriesValues[rightIndex]:
        seenBefore = true
        break
    if not seenBefore:
      distinctCount += 1
    if distinctCount > upperDistinct:
      break
    if distinctCount >= lowerDistinct:
      subsequenceCount += 1

appendOutput($subsequenceCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
