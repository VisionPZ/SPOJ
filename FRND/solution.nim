const flushBlockBytes = 1 shl 17
const nameBits = 20

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

let residentCount = nextInt(inputData, scanPos)
if residentCount == 1:
  let onlyName = nextInt(inputData, scanPos)
  appendOutput($onlyName)
  outputBuffer.add '\n'
else:
  var setBitCounts = newSeq[int64](nameBits)
  var residentIndex = 0
  while residentIndex < residentCount:
    let nameValue = nextInt(inputData, scanPos)
    var bitIndex = 0
    while bitIndex < nameBits:
      if (nameValue and (1 shl bitIndex)) != 0:
        setBitCounts[bitIndex] += 1
      bitIndex += 1
    residentIndex += 1
  var planetValue: int64 = 0
  var bitIndex = 0
  while bitIndex < nameBits:
    let onesCount = setBitCounts[bitIndex]
    planetValue += onesCount * (int64(residentCount) - onesCount) * (int64(1) shl bitIndex)
    bitIndex += 1
  appendOutput($planetValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
