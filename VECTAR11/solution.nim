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
var numberQueries = newSeq[int](caseCount)
var largestNumber = 0
for queryIndex in 0 .. caseCount - 1:
  numberQueries[queryIndex] = nextInt(inputData, scanPos)
  if numberQueries[queryIndex] > largestNumber:
    largestNumber = numberQueries[queryIndex]

var squareValues = newSeq[int](0)
var squareRoot = 1
while squareRoot * squareRoot <= largestNumber:
  squareValues.add squareRoot * squareRoot
  squareRoot += 1

var isWinning = newSeq[bool](largestNumber + 1)
for numberValue in 1 .. largestNumber:
  for squareValue in squareValues:
    if squareValue > numberValue:
      break
    if not isWinning[numberValue - squareValue]:
      isWinning[numberValue] = true
      break

for queryIndex in 0 .. caseCount - 1:
  if isWinning[numberQueries[queryIndex]]:
    appendOutput("Win\n")
  else:
    appendOutput("Lose\n")

stdout.write outputBuffer
outputBuffer.setLen 0
