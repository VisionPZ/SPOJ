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

let lowBound = nextInt(inputData, scanPos)
let highBound = nextInt(inputData, scanPos)
let targetDivisors = nextInt(inputData, scanPos)

let spanLength = highBound - lowBound + 1
var remainders = newSeq[int](spanLength)
var divisorCounts = newSeq[int](spanLength)
for spanIndex in 0 .. spanLength - 1:
  remainders[spanIndex] = lowBound + spanIndex
  divisorCounts[spanIndex] = 1

var rootBound = 1
while rootBound * rootBound <= highBound:
  rootBound += 1

var isComposite = newSeq[bool](rootBound + 1)
var primeCandidates = newSeq[int]()
for candidate in 2 .. rootBound:
  if not isComposite[candidate]:
    primeCandidates.add candidate
    var multiple = candidate * candidate
    while multiple <= rootBound:
      isComposite[multiple] = true
      multiple += candidate

for primeValue in primeCandidates:
  if primeValue * primeValue > highBound:
    break
  var firstMultiple = ((lowBound + primeValue - 1) div primeValue) * primeValue
  var numberValue = firstMultiple
  while numberValue <= highBound:
    let spanIndex = numberValue - lowBound
    var exponent = 0
    while remainders[spanIndex] mod primeValue == 0:
      remainders[spanIndex] = remainders[spanIndex] div primeValue
      exponent += 1
    if exponent > 0:
      divisorCounts[spanIndex] = divisorCounts[spanIndex] * (exponent + 1)
    numberValue += primeValue

var matchingCount = 0
for spanIndex in 0 .. spanLength - 1:
  var divisorTotal = divisorCounts[spanIndex]
  if remainders[spanIndex] > 1:
    divisorTotal = divisorTotal * 2
  if divisorTotal == targetDivisors:
    matchingCount += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($matchingCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
