const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007

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

let testCount = nextInt(inputData, scanPos)
var targets = newSeq[int](testCount)
var maxTarget = 0
for testIndex in 0 .. testCount - 1:
  targets[testIndex] = nextInt(inputData, scanPos)
  if targets[testIndex] > maxTarget:
    maxTarget = targets[testIndex]

var ways = newSeq[int64](maxTarget + 1)
ways[0] = 1
if maxTarget >= 2:
  ways[2] = 1
for targetValue in 3 .. maxTarget:
  ways[targetValue] = (ways[targetValue - 2] + ways[targetValue - 3]) mod int64(answerModulus)

for testIndex in 0 .. testCount - 1:
  appendOutput($ways[targets[testIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
