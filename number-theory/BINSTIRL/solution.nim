proc nextInt(inputData: string, i: var int): int =
  const firstDigitValue = 48
  while i < inputData.len and ord(inputData[i]) < firstDigitValue:
    inc i
  result = 0
  while i < inputData.len and ord(inputData[i]) >= firstDigitValue:
    result = result * 10 + ord(inputData[i]) - firstDigitValue
    inc i

const flushBlockBytes = 1 shl 18

var inputData = newStringOfCap(1 shl 16)
var inputLine: string
while stdin.readLine(inputLine):
  inputData.add(inputLine)
  inputData.add('\n')

var outputBuffer = newStringOfCap(flushBlockBytes)
var i = 0
let dataSetCount = nextInt(inputData, i)
for j in 0 ..< dataSetCount:
  let totalItems = nextInt(inputData, i)
  let subsetCount = nextInt(inputData, i)
  let extraItems = totalItems - subsetCount
  let maskBits = (subsetCount - 1) div 2
  if (extraItems and maskBits) == 0:
    outputBuffer.add('1')
  else:
    outputBuffer.add('0')
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
if outputBuffer.len > 0:
  stdout.write outputBuffer
