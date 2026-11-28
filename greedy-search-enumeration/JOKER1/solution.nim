const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007

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
  let knifeCount = nextInt(inputData, scanPos)
  var maxNumbers = newSeq[int](knifeCount)
  for knifeIndex in 0 .. knifeCount - 1:
    maxNumbers[knifeIndex] = nextInt(inputData, scanPos)
  for rightIndex in 1 .. knifeCount - 1:
    let currentMax = maxNumbers[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and maxNumbers[leftIndex] > currentMax:
      maxNumbers[leftIndex + 1] = maxNumbers[leftIndex]
      leftIndex -= 1
    maxNumbers[leftIndex + 1] = currentMax
  var ways: int64 = 1
  for knifeIndex in 0 .. knifeCount - 1:
    let freeNumbers = maxNumbers[knifeIndex] - knifeIndex
    if freeNumbers <= 0:
      ways = 0
    else:
      ways = (ways * int64(freeNumbers)) mod int64(modulusValue)
  appendOutput($ways)
  outputBuffer.add '\n'
appendOutput("KILL BATMAN")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
