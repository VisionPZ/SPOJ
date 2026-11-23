const maxBitPosition = 60
const flushBlockBytes = 1 shl 17

proc nextIdentifier(identifier: int64): int64 =
  if identifier == 0:
    return 0
  var nodeCount = 0
  var probe = identifier
  while probe > 0:
    nodeCount = nodeCount + 1
    probe = probe shr 1
  var slotHeights: array[0 .. maxBitPosition, int]
  var slots = 1
  for bitPosition in countdown(nodeCount - 1, 0):
    if ((identifier shr bitPosition) and 1) == 1:
      slots = slots + 1
    else:
      slots = slots - 1
    slotHeights[bitPosition] = slots
  for flipPosition in 0 .. nodeCount - 2:
    if ((identifier shr flipPosition) and 1) == 0:
      let currentHeight = slotHeights[flipPosition + 1] + 1
      if flipPosition >= currentHeight and (flipPosition - currentHeight) mod 2 == 0:
        var resultCode = (identifier shr (flipPosition + 1)) shl (flipPosition + 1)
        resultCode = resultCode or (int64(1) shl flipPosition)
        var height = currentHeight
        var remainingDownSteps = (flipPosition + currentHeight - 2) div 2
        for bitPosition in countdown(flipPosition - 1, 1):
          if height >= 2 and remainingDownSteps > 0:
            height = height - 1
            remainingDownSteps = remainingDownSteps - 1
          else:
            resultCode = resultCode or (int64(1) shl bitPosition)
            height = height + 1
        return resultCode
  var smallestCode: int64 = 0
  var powerOfTwo: int64 = 4
  var exponent = 2
  while exponent <= nodeCount - 1:
    smallestCode = smallestCode or powerOfTwo
    powerOfTwo = powerOfTwo shl 2
    exponent = exponent + 2
  return smallestCode

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer: string
for _ in 1 .. caseCount:
  let identifier = int64(nextInt(inputData, scanPos))
  let successorCode = nextIdentifier(identifier)
  outputBuffer.add $successorCode
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
