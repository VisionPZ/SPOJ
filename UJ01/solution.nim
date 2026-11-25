const flushBlockBytes = 1 shl 17

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

proc gcdValues(left: int64, right: int64): int64 =
  var first = left
  var second = right
  while second != 0:
    let remainder = first mod second
    first = second
    second = remainder
  return first

proc countMultiples(limit: int64, firstStep: int64, secondStep: int64, commonStep: int64): int64 =
  return limit div firstStep + limit div secondStep - limit div commonStep

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstStep = int64(nextInt(inputData, scanPos))
  let secondStep = int64(nextInt(inputData, scanPos))
  let targetRank = int64(nextInt(inputData, scanPos))
  let smallerStep = if firstStep < secondStep: firstStep else: secondStep
  let divisor = gcdValues(firstStep, secondStep)
  let commonStep = firstStep div divisor * secondStep
  var lowBound: int64 = 1
  var highBound: int64 = targetRank * smallerStep
  while lowBound < highBound:
    let middle = lowBound + (highBound - lowBound) div 2
    if countMultiples(middle, firstStep, secondStep, commonStep) >= targetRank:
      highBound = middle
    else:
      lowBound = middle + 1
  appendOutput($lowBound)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
