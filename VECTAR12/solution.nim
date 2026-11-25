const flushBlockBytes = 1 shl 17
const pathModulus: int64 = 1000000007

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

let queryCount = nextInt(inputData, scanPos)
var querySteps = newSeq[int](queryCount)
var queryHeights = newSeq[int](queryCount)
var nextInBucket = newSeq[int](queryCount)
var maxSteps = 0
for queryIndex in 0 .. queryCount - 1:
  querySteps[queryIndex] = nextInt(inputData, scanPos)
  queryHeights[queryIndex] = nextInt(inputData, scanPos)
  if querySteps[queryIndex] > maxSteps:
    maxSteps = querySteps[queryIndex]

var bucketHeads = newSeq[int](maxSteps + 1)
for stepIndex in 0 .. maxSteps:
  bucketHeads[stepIndex] = -1
for queryIndex in 0 .. queryCount - 1:
  let stepIndex = querySteps[queryIndex]
  nextInBucket[queryIndex] = bucketHeads[stepIndex]
  bucketHeads[stepIndex] = queryIndex

var answers = newSeq[int](queryCount)
var previousHeights = newSeq[int64](maxSteps + 2)
var currentHeights = newSeq[int64](maxSteps + 2)
previousHeights[0] = 1

var cursor = bucketHeads[0]
while cursor >= 0:
  answers[cursor] = int(previousHeights[queryHeights[cursor]])
  cursor = nextInBucket[cursor]

var stepIndex = 1
while stepIndex <= maxSteps:
  for heightIndex in 0 .. stepIndex:
    var pathTotal = previousHeights[heightIndex]
    if heightIndex > 0:
      pathTotal = pathTotal + previousHeights[heightIndex - 1]
    if heightIndex + 1 < stepIndex:
      pathTotal = pathTotal + previousHeights[heightIndex + 1]
    currentHeights[heightIndex] = pathTotal mod pathModulus
  swap previousHeights, currentHeights
  cursor = bucketHeads[stepIndex]
  while cursor >= 0:
    answers[cursor] = int(previousHeights[queryHeights[cursor]])
    cursor = nextInBucket[cursor]
  stepIndex += 1

for queryIndex in 0 .. queryCount - 1:
  appendOutput($answers[queryIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
