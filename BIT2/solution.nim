const flushBlockBytes = 1 shl 17
const highestBitIndex = 50

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
  let targetSum = nextInt(inputData, scanPos)
  var foundK = 0'i64
  var builtSum = 0'i64
  var topBitCount = 0'i64
  for bitIndex in countdown(highestBitIndex, 0):
    var stepSum = (1'i64 shl bitIndex) * topBitCount + 1
    if bitIndex > 0:
      stepSum = stepSum + int64(bitIndex) * (1'i64 shl (bitIndex - 1))
    if builtSum + stepSum <= targetSum:
      builtSum = builtSum + stepSum
      foundK = foundK + (1'i64 shl bitIndex)
      topBitCount += 1
  if builtSum == targetSum:
    appendOutput($foundK)
  else:
    appendOutput("Does Not Exist.")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
