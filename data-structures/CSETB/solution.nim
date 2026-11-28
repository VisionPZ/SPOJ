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

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var limitNumber = 0
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > limitNumber:
    limitNumber = queries[caseIndex]

var bitCounts = newSeq[int](limitNumber + 1)
var prefixCounts = newSeq[int](limitNumber + 1)
for numberValue in 1 .. limitNumber:
  bitCounts[numberValue] = bitCounts[numberValue div 2] + (numberValue mod 2)
  prefixCounts[numberValue] = prefixCounts[numberValue - 1] + bitCounts[numberValue]
for caseIndex in 0 .. caseCount - 1:
  appendOutput($prefixCounts[queries[caseIndex]])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
