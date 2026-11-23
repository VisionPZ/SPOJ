proc nextInt(inputData: string, scanPos: var int): int =
  const firstDigitValue = 48
  while scanPos < inputData.len and ord(inputData[scanPos]) < firstDigitValue:
    inc scanPos
  result = 0
  while scanPos < inputData.len and ord(inputData[scanPos]) >= firstDigitValue:
    result = result * 10 + ord(inputData[scanPos]) - firstDigitValue
    inc scanPos

const flushBlockBytes = 1 shl 18

var inputData = newStringOfCap(1 shl 16)
var inputLine: string
while stdin.readLine(inputLine):
  inputData.add(inputLine)
  inputData.add('\n')

var outputBuffer = newStringOfCap(flushBlockBytes)
var scanPos = 0
let dataSetCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< dataSetCount:
  let totalItems = nextInt(inputData, scanPos)
  let subsetCount = nextInt(inputData, scanPos)
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
