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

let arrayLength = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var baseNumbers = newSeq[int](arrayLength)
for arrayIndex in 0 .. arrayLength - 1:
  baseNumbers[arrayIndex] = nextInt(inputData, scanPos)
var querySpans = newSeq[int](queryCount)
var queryStarts = newSeq[int](queryCount)
var maxEndIndex = 0
for queryIndex in 0 .. queryCount - 1:
  querySpans[queryIndex] = nextInt(inputData, scanPos)
  queryStarts[queryIndex] = nextInt(inputData, scanPos) - 1
  let endIndex = queryStarts[queryIndex] + querySpans[queryIndex] - 1
  if endIndex > maxEndIndex:
    maxEndIndex = endIndex
let copiesNeeded = (maxEndIndex + 1 + arrayLength - 1) div arrayLength
let totalSlots = arrayLength * copiesNeeded
var prefixSums = newSeq[int64](totalSlots + 1)
for slotIndex in 0 .. totalSlots - 1:
  prefixSums[slotIndex + 1] = prefixSums[slotIndex] + int64(baseNumbers[slotIndex mod arrayLength])
for queryIndex in 0 .. queryCount - 1:
  let startIndex = queryStarts[queryIndex]
  let endIndex = startIndex + querySpans[queryIndex] - 1
  let answerValue = prefixSums[endIndex + 1] - prefixSums[startIndex]
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
