const flushBlockBytes = 1 shl 17
const maxValue = 1000000

var isPrimeValue = newSeq[bool](maxValue + 1)
for value in 0 .. maxValue:
  isPrimeValue[value] = true
isPrimeValue[0] = false
isPrimeValue[1] = false
var primeCursor = 2
while primeCursor * primeCursor <= maxValue:
  if isPrimeValue[primeCursor]:
    var multiple = primeCursor * primeCursor
    while multiple <= maxValue:
      isPrimeValue[multiple] = false
      multiple = multiple + primeCursor
  primeCursor += 1

var scaryFlags = newSeq[bool](maxValue + 1)
var seedNumbers = @[2, 3, 5, 7]
for seedValue in seedNumbers:
  scaryFlags[seedValue] = true
var currentLevel = seedNumbers
var placeValue = 10
while currentLevel.len > 0:
  var nextLevel = newSeq[int]()
  for baseValue in currentLevel:
    for leadingDigit in 1 .. 9:
      let candidate = leadingDigit * placeValue + baseValue
      if candidate > maxValue:
        continue
      if isPrimeValue[candidate]:
        scaryFlags[candidate] = true
        nextLevel.add candidate
  currentLevel = nextLevel
  placeValue = placeValue * 10

var scaryCounts = newSeq[int](maxValue + 1)
for value in 1 .. maxValue:
  scaryCounts[value] = scaryCounts[value - 1]
  if scaryFlags[value]:
    scaryCounts[value] = scaryCounts[value] + 1

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
for caseIndex in 0 .. caseCount - 1:
  let upperBound = nextInt(inputData, scanPos)
  appendOutput($scaryCounts[upperBound])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
