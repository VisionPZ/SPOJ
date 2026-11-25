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
var numberLimits = newSeq[int](caseCount)
var progressionOffsets = newSeq[int](caseCount)
var largestLimit = 0
for caseIndex in 0 .. caseCount - 1:
  numberLimits[caseIndex] = nextInt(inputData, scanPos)
  progressionOffsets[caseIndex] = nextInt(inputData, scanPos)
  if numberLimits[caseIndex] > largestLimit:
    largestLimit = numberLimits[caseIndex]

var divisorCounts = newSeq[int16](largestLimit + 1)
for divisor in 1 .. largestLimit:
  var multiple = divisor
  while multiple <= largestLimit:
    inc divisorCounts[multiple]
    multiple += divisor

for caseIndex in 0 .. caseCount - 1:
  let numberLimit = numberLimits[caseIndex]
  let progressionStep = progressionOffsets[caseIndex]
  var bestNumber = 0
  var bestDivisors = 0
  var termIndex = 0
  while true:
    let termValue = 1 + termIndex * progressionStep + termIndex * (termIndex + 1) div 2
    if termValue > numberLimit:
      break
    let divisorTotal = int(divisorCounts[termValue])
    if divisorTotal > bestDivisors:
      bestDivisors = divisorTotal
      bestNumber = termValue
    termIndex += 1
  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $bestNumber & " " & $bestDivisors)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
