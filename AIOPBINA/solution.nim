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
for caseIndex in 0 .. caseCount - 1:
  let numberCount = nextInt(inputData, scanPos)
  let targetValue = nextInt(inputData, scanPos)
  var sortedValues = newSeq[int](numberCount)
  for numberIndex in 0 .. numberCount - 1:
    sortedValues[numberIndex] = nextInt(inputData, scanPos)
  var lowIndex = 0
  var highIndex = numberCount - 1
  var found = false
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedValues[middleIndex] == targetValue:
      found = true
      break
    if sortedValues[middleIndex] < targetValue:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  if found:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
