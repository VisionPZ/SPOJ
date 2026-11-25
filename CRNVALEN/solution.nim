const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let girlCount = nextInt(inputData, scanPos)
  var highestReport = -1'i64
  var nextReport = -1'i64
  var highestCount = 0'i64
  var nextCount = 0'i64
  var extraReport = false
  for girlIndex in 0 .. girlCount - 1:
    let report = nextInt(inputData, scanPos)
    if report > highestReport:
      nextReport = highestReport
      nextCount = highestCount
      highestReport = report
      highestCount = 1
    elif report == highestReport:
      highestCount += 1
    elif report > nextReport:
      nextReport = report
      nextCount = 1
    elif report == nextReport:
      nextCount += 1
    else:
      extraReport = true
  var answer = -1'i64
  if highestCount == girlCount:
    if highestReport == 0:
      answer = 0
    elif highestReport == girlCount - 1:
      answer = girlCount
  elif not extraReport and nextReport == highestReport - 1 and nextCount == highestReport:
    answer = highestReport
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
