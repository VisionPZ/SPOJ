const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc skipWhitespace(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let peopleCount = nextInt(inputData, scanPos)
  let boyTarget = nextInt(inputData, scanPos)
  skipWhitespace(inputData, scanPos)
  let tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos += 1
  let tokenLength = scanPos - tokenStart
  var prefixFrequency = newSeq[int64](peopleCount + 1)
  prefixFrequency[0] = 1
  var boysSoFar = 0
  var pairCount: int64 = 0
  for personIndex in 0 ..< tokenLength:
    if inputData[tokenStart + personIndex] == '1':
      boysSoFar = boysSoFar + 1
    let neededPrefix = boysSoFar - boyTarget
    if neededPrefix >= 0:
      pairCount = pairCount + prefixFrequency[neededPrefix]
    prefixFrequency[boysSoFar] = prefixFrequency[boysSoFar] + 1
  appendOutput($pairCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
