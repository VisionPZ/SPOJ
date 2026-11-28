const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and ((data[pos] < '0' or data[pos] > '9') and data[pos] != '-'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let elementCount = nextInt(inputData, scanPos)
  let prefixOffset = 10 * elementCount
  var prefixFrequency = newSeq[int32](2 * prefixOffset + 1)
  var runningPrefix: int64 = 0
  prefixFrequency[prefixOffset] = 1
  var zeroSumCount: int64 = 0
  for elementIndex in 0 ..< elementCount:
    runningPrefix = runningPrefix + int64(nextInt(inputData, scanPos))
    let frequencyIndex = int(runningPrefix) + prefixOffset
    zeroSumCount = zeroSumCount + int64(prefixFrequency[frequencyIndex])
    prefixFrequency[frequencyIndex] = prefixFrequency[frequencyIndex] + 1
  appendOutput($zeroSumCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
