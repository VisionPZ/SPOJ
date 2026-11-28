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

let lowerBound = nextInt(inputData, scanPos)
let upperBound = nextInt(inputData, scanPos)
var divisorSums = newSeq[int32](upperBound + 1)
for numberValue in 0 .. upperBound:
  divisorSums[numberValue] = 1
divisorSums[0] = 0
if upperBound >= 1:
  divisorSums[1] = 0
var divisor = 2
while divisor <= upperBound div 2:
  var multiple = divisor * 2
  while multiple <= upperBound:
    divisorSums[multiple] += int32(divisor)
    multiple += divisor
  divisor += 1
var abundantCount: int64 = 0
var candidate = lowerBound
if candidate < 1:
  candidate = 1
while candidate <= upperBound:
  if int64(divisorSums[candidate]) > int64(candidate):
    abundantCount += 1
  candidate += 1
appendOutput($abundantCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
