const flushBlockBytes = 1 shl 17
const maxLeaveDay = 366

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

let requestCount = nextInt(inputData, scanPos)
var dayChanges = newSeq[int](maxLeaveDay + 2)
for requestIndex in 0 .. requestCount - 1:
  var startDay = nextInt(inputData, scanPos)
  var endDay = nextInt(inputData, scanPos)
  if startDay < 1:
    startDay = 1
  if endDay > maxLeaveDay + 1:
    endDay = maxLeaveDay + 1
  if startDay < endDay:
    dayChanges[startDay] += 1
    dayChanges[endDay] -= 1
var usedDayCount: int64 = 0
var activeRequests = 0
for dayIndex in 1 .. maxLeaveDay:
  activeRequests += dayChanges[dayIndex]
  if activeRequests > 0:
    usedDayCount += 1
appendOutput($usedDayCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
