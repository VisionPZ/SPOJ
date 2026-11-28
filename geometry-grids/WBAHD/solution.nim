const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
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
  let leftCarCount = nextInt(inputData, scanPos)
  let rightCarCount = nextInt(inputData, scanPos)
  var totalCrossingTime: int64 = 0
  var lastLeftCrossing = 0
  var lastRightCrossing = 0
  for carIndex in 0 ..< leftCarCount:
    let crossingTime = nextInt(inputData, scanPos)
    totalCrossingTime += int64(crossingTime)
    if carIndex == leftCarCount - 1:
      lastLeftCrossing = crossingTime
  for carIndex in 0 ..< rightCarCount:
    let crossingTime = nextInt(inputData, scanPos)
    totalCrossingTime += int64(crossingTime)
    if carIndex == rightCarCount - 1:
      lastRightCrossing = crossingTime
  let largestFinalCrossing = if lastLeftCrossing > lastRightCrossing: lastLeftCrossing else: lastRightCrossing
  let answer = totalCrossingTime - int64(largestFinalCrossing)
  appendOutput("Case " & $(caseIndex + 1) & ": " & $answer & "\n")
stdout.write outputBuffer
