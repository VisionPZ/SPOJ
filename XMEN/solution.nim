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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let elementCount = nextInt(inputData, scanPos)
  var positionInFirst = newSeq[int](elementCount + 1)
  for elementIndex in 0 ..< elementCount:
    let dnaValue = nextInt(inputData, scanPos)
    positionInFirst[dnaValue] = elementIndex
  var tails = newSeq[int](elementCount)
  var subsequenceLength = 0
  for elementIndex in 0 ..< elementCount:
    let mappedValue = positionInFirst[nextInt(inputData, scanPos)]
    var lowIndex = 0
    var highIndex = subsequenceLength
    while lowIndex < highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if tails[middleIndex] < mappedValue:
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex
    tails[lowIndex] = mappedValue
    if lowIndex == subsequenceLength:
      subsequenceLength = subsequenceLength + 1
  appendOutput($subsequenceLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
