const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusValue = 1000000007

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var powerOfTwo = newSeq[int64](61)
powerOfTwo[0] = 1
for bitIndex in 1 .. 60:
  powerOfTwo[bitIndex] = (powerOfTwo[bitIndex - 1] * 2) mod modulusValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  var upperBound = nextInt(inputData, scanPos)
  var pairCount: int64 = 0
  while upperBound > 0:
    var highestBit = 0
    var highestPower = 1
    while highestPower * 2 <= upperBound:
      highestPower = highestPower * 2
      highestBit = highestBit + 1
    if highestBit >= 1:
      pairCount = (pairCount + int64(highestBit) * powerOfTwo[highestBit - 1]) mod modulusValue
    upperBound = upperBound - highestPower
    pairCount = (pairCount + int64(upperBound) + 1) mod modulusValue
  appendOutput($pairCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
