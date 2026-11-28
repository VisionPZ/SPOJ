const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const doubled = 2

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  let operationCount = nextInt(inputData, scanPos)
  var totalSum: int64 = 0
  var gain: int64 = 0
  var negativeCount = 0
  var zeroCount = 0
  var smallestAbsolute: int64 = 0
  for elementIndex in 0 .. elementCount - 1:
    let elementValue = int64(nextInt(inputData, scanPos))
    totalSum = totalSum + elementValue
    if elementValue < 0:
      if negativeCount < operationCount:
        gain = gain - elementValue
      negativeCount += 1
    elif elementValue == 0:
      zeroCount += 1
    if elementValue != 0:
      let absoluteValue = if elementValue < 0: -elementValue else: elementValue
      if smallestAbsolute == 0 or absoluteValue < smallestAbsolute:
        smallestAbsolute = absoluteValue
  var flippedNegatives = negativeCount
  if flippedNegatives > operationCount:
    flippedNegatives = operationCount
  let leftover = operationCount - flippedNegatives
  var penalty: int64 = 0
  if zeroCount == 0 and leftover mod 2 == 1:
    penalty = doubled * smallestAbsolute
  let bestSum = totalSum + doubled * gain - penalty
  appendOutput($bestSum)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
