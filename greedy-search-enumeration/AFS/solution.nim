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

let testCount = nextInt(inputData, scanPos)
var queries = newSeq[int](testCount)
var largestQuery = 1
for queryIndex in 0 .. testCount - 1:
  queries[queryIndex] = nextInt(inputData, scanPos)
  if queries[queryIndex] > largestQuery:
    largestQuery = queries[queryIndex]

var divisorSums = newSeq[int64](largestQuery + 1)
var properDivisor = 1
while properDivisor <= largestQuery:
  var multiple = properDivisor * 2
  while multiple <= largestQuery:
    divisorSums[multiple] = divisorSums[multiple] + int64(properDivisor)
    multiple += properDivisor
  properDivisor += 1

var sequenceValues = newSeq[int64](largestQuery + 1)
for position in 2 .. largestQuery:
  sequenceValues[position] = sequenceValues[position - 1] + divisorSums[position]

for queryIndex in 0 .. testCount - 1:
  appendOutput($sequenceValues[queries[queryIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
