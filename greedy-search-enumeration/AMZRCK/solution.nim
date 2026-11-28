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
var trackCounts = newSeq[int](caseCount)
var largestCount = 0
for caseIndex in 0 .. caseCount - 1:
  trackCounts[caseIndex] = nextInt(inputData, scanPos)
  if trackCounts[caseIndex] > largestCount:
    largestCount = trackCounts[caseIndex]
var waysTable = newSeq[int64](largestCount + 1)
waysTable[0] = 1
if largestCount >= 1:
  waysTable[1] = 2
for trackSize in 2 .. largestCount:
  waysTable[trackSize] = waysTable[trackSize - 1] + waysTable[trackSize - 2]
for caseIndex in 0 .. caseCount - 1:
  appendOutput($(waysTable[trackCounts[caseIndex]]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
