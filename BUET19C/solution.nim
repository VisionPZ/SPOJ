const flushBlockBytes = 1 shl 17
const maximumIdValue = 100000

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

let offlineCount = nextInt(inputData, scanPos)
var seenId = newSeq[bool](maximumIdValue + 1)
var distinctCount = 0
var readIndex = 0
while readIndex < offlineCount:
  let submittedId = nextInt(inputData, scanPos)
  if not seenId[submittedId]:
    seenId[submittedId] = true
    distinctCount += 1
  readIndex += 1
appendOutput($distinctCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
