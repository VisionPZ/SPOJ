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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc prefixTotal(limitIndex: int64): int64 =
  if limitIndex <= 0:
    return 0
  let pairCount = limitIndex div 2
  let pairTotal = 2 * pairCount * pairCount + pairCount
  if limitIndex mod 2 == 0:
    return pairTotal
  return pairTotal + limitIndex + 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var leftIndex = int64(nextInt(inputData, scanPos))
  var rightIndex = int64(nextInt(inputData, scanPos))
  if leftIndex > rightIndex:
    let swapValue = leftIndex
    leftIndex = rightIndex
    rightIndex = swapValue
  let rangeTotal = prefixTotal(rightIndex) - prefixTotal(leftIndex - 1)
  appendOutput($rangeTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
