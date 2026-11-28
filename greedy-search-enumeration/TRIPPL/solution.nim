const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInteger(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc pairsOf(value: int64): int64 =
  value * (value - 1) div 2

proc triplesOf(value: int64): int64 =
  value * (value - 1) * (value - 2) div 6

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

let testCount = nextInteger(inputData, scanPos)
for caseIndex in 0..<testCount:
  let teamCount = int64(nextInteger(inputData, scanPos))
  if teamCount < 3:
    appendOutput("0\n")
  else:
    let degreeSum = teamCount * (teamCount - 1) div 2
    let baseDegree = degreeSum div teamCount
    let extraCount = degreeSum mod teamCount
    let highDegree = baseDegree + 1
    let transitiveCount = extraCount * pairsOf(highDegree) +
                          (teamCount - extraCount) * pairsOf(baseDegree)
    appendOutput($(triplesOf(teamCount) - transitiveCount))
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
