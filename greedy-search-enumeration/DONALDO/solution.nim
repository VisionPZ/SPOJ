const flushBlockBytes = 1 shl 17
const secondsPerDay = 86400
const secondsPerHour = 3600
const secondsPerMinute = 60

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

var secondCounts = newSeq[int](secondsPerDay)
var prefixCounts = newSeq[int](secondsPerDay + 1)

let testCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. testCount:
  secondCounts.setLen 0
  secondCounts.setLen secondsPerDay
  let textCount = nextInt(inputData, scanPos)
  for textIndex in 0 .. textCount - 1:
    let hourValue = nextInt(inputData, scanPos)
    let minuteValue = nextInt(inputData, scanPos)
    let secondValue = nextInt(inputData, scanPos)
    let totalSeconds = hourValue * secondsPerHour + minuteValue * secondsPerMinute + secondValue
    secondCounts[totalSeconds] += 1
  let intervalLength = nextInt(inputData, scanPos)
  prefixCounts[0] = 0
  for secondIndex in 0 .. secondsPerDay - 1:
    prefixCounts[secondIndex + 1] = prefixCounts[secondIndex] + secondCounts[secondIndex]
  var bestCrowd = 0
  for startSecond in 0 .. secondsPerDay - 1:
    var endSecond = startSecond + intervalLength - 1
    if endSecond >= secondsPerDay:
      endSecond = secondsPerDay - 1
    let crowdSize = prefixCounts[endSecond + 1] - prefixCounts[startSecond]
    if crowdSize > bestCrowd:
      bestCrowd = crowdSize
  appendOutput("Case " & $caseNumber & ": " & $bestCrowd & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
