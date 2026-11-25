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
var requestedRanks = newSeq[int](caseCount)
var largestRank = 0
for caseIndex in 0 .. caseCount - 1:
  requestedRanks[caseIndex] = nextInt(inputData, scanPos)
  if requestedRanks[caseIndex] > largestRank:
    largestRank = requestedRanks[caseIndex]
var uglyNumbers = newSeq[int64](largestRank + 1)
if largestRank >= 1:
  uglyNumbers[1] = 1
  var pointerTwo = 1
  var pointerThree = 1
  var pointerFive = 1
  for rankIndex in 2 .. largestRank:
    let nextTwo = uglyNumbers[pointerTwo] * 2
    let nextThree = uglyNumbers[pointerThree] * 3
    let nextFive = uglyNumbers[pointerFive] * 5
    var nextUgly = nextTwo
    if nextThree < nextUgly:
      nextUgly = nextThree
    if nextFive < nextUgly:
      nextUgly = nextFive
    uglyNumbers[rankIndex] = nextUgly
    while uglyNumbers[pointerTwo] * 2 <= nextUgly:
      pointerTwo += 1
    while uglyNumbers[pointerThree] * 3 <= nextUgly:
      pointerThree += 1
    while uglyNumbers[pointerFive] * 5 <= nextUgly:
      pointerFive += 1
for caseIndex in 0 .. caseCount - 1:
  if requestedRanks[caseIndex] >= 1:
    appendOutput($uglyNumbers[requestedRanks[caseIndex]])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
