const flushBlockBytes = 1 shl 17
const maximumBitPosition = 30

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

proc countSetBits(value: int): int =
  var bitCount = 0
  var remaining = value
  while remaining > 0:
    bitCount = bitCount + (remaining and 1)
    remaining = remaining shr 1
  return bitCount

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let evenLimit = nextInt(inputData, scanPos)
  let onesBudget = nextInt(inputData, scanPos)
  if onesBudget < 1:
    appendOutput("-1")
  else:
    var chosenPosition = -1
    var higherOnes = 0
    for bitPosition in 0 .. maximumBitPosition:
      if (evenLimit and (1 shl bitPosition)) != 0:
        let prefixOnes = countSetBits(evenLimit shr (bitPosition + 1))
        if prefixOnes <= onesBudget - 1:
          chosenPosition = bitPosition
          higherOnes = prefixOnes
          break
    if chosenPosition < 0:
      appendOutput("-1")
    else:
      var lowerBits = 1
      var spareOnes = onesBudget - 1 - higherOnes
      var bitPosition = chosenPosition - 1
      while bitPosition >= 1 and spareOnes > 0:
        lowerBits = lowerBits or (1 shl bitPosition)
        spareOnes = spareOnes - 1
        bitPosition = bitPosition - 1
      let blockSize = 1 shl (chosenPosition + 1)
      let answer = evenLimit - (evenLimit mod blockSize) + lowerBits
      appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
