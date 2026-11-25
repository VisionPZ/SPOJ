const flushBlockBytes = 1 shl 17
const solutionModulus = int64(1000000007)

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

var queries = newSeq[int](0)
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  queries.add nextInt(inputData, scanPos)

var largestQuery = 1
for queryValue in queries:
  if queryValue > largestQuery:
    largestQuery = queryValue

var stepCount = newSeq[int](largestQuery + 1)
var pathWays = newSeq[int64](largestQuery + 1)
for index in 0 .. largestQuery:
  stepCount[index] = -1
stepCount[1] = 0
pathWays[1] = 1

var queue = newSeq[int](largestQuery + 1)
var queueHead = 0
var queueTail = 0
queue[queueTail] = 1
queueTail += 1
while queueHead < queueTail:
  let currentNumber = queue[queueHead]
  queueHead += 1
  let nextStep = stepCount[currentNumber] + 1
  var remainder = currentNumber
  var usedDigits = 0
  while remainder > 0:
    let digitValue = remainder mod 10
    remainder = remainder div 10
    if digitValue == 0:
      continue
    let digitBit = 1 shl digitValue
    if (usedDigits and digitBit) != 0:
      continue
    usedDigits = usedDigits or digitBit
    let nextNumber = currentNumber + digitValue
    if nextNumber > largestQuery:
      continue
    if stepCount[nextNumber] < 0:
      stepCount[nextNumber] = nextStep
      pathWays[nextNumber] = pathWays[currentNumber]
      queue[queueTail] = nextNumber
      queueTail += 1
    elif stepCount[nextNumber] == nextStep:
      pathWays[nextNumber] = (pathWays[nextNumber] + pathWays[currentNumber]) mod solutionModulus

for queryValue in queries:
  if stepCount[queryValue] < 0:
    appendOutput("IMPOSSIBLE")
  else:
    appendOutput($stepCount[queryValue] & " " & $pathWays[queryValue])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
