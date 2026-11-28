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

let weightCount = nextInt(inputData, scanPos)
var imbalance = int64(nextInt(inputData, scanPos))
var currentPower = int64(1)
for ignoredIndex in 1 .. weightCount - 1:
  currentPower = currentPower * 3

var firstWeights = newSeq[int](0)
var secondWeights = newSeq[int](0)
for weightIndex in 0 .. weightCount - 1:
  let halfPower = currentPower div 2
  if imbalance > halfPower:
    imbalance -= currentPower
    secondWeights.add(weightCount - weightIndex)
  elif imbalance < -halfPower:
    imbalance += currentPower
    firstWeights.add(weightCount - weightIndex)
  currentPower = currentPower div 3

if imbalance != 0:
  appendOutput("-1")
  outputBuffer.add '\n'
else:
  var firstPosition = firstWeights.len - 1
  while firstPosition >= 0:
    appendOutput($firstWeights[firstPosition])
    if firstPosition > 0:
      appendOutput(" ")
    firstPosition -= 1
  outputBuffer.add '\n'
  var secondPosition = secondWeights.len - 1
  while secondPosition >= 0:
    appendOutput($secondWeights[secondPosition])
    if secondPosition > 0:
      appendOutput(" ")
    secondPosition -= 1
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
