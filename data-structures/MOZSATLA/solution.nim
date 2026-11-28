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
for testIndex in 0 .. testCount - 1:
  let arraySize = nextInt(inputData, scanPos)
  var relations = newSeq[int](arraySize - 1)
  for relationIndex in 0 .. arraySize - 2:
    relations[relationIndex] = nextInt(inputData, scanPos)
  var forwardLevels = newSeq[int](arraySize)
  var backwardLevels = newSeq[int](arraySize)
  forwardLevels[0] = 0
  for relationIndex in 0 .. arraySize - 2:
    forwardLevels[relationIndex + 1] = 0
    if relations[relationIndex] == 0:
      forwardLevels[relationIndex + 1] = forwardLevels[relationIndex]
    elif relations[relationIndex] == 1:
      forwardLevels[relationIndex + 1] = forwardLevels[relationIndex] + 1
  backwardLevels[arraySize - 1] = 0
  var reverseIndex = arraySize - 2
  while reverseIndex >= 0:
    backwardLevels[reverseIndex] = 0
    if relations[reverseIndex] == 0:
      backwardLevels[reverseIndex] = backwardLevels[reverseIndex + 1]
    elif relations[reverseIndex] == 2:
      backwardLevels[reverseIndex] = backwardLevels[reverseIndex + 1] + 1
    reverseIndex -= 1
  let leadingLevel = if forwardLevels[0] > backwardLevels[0]: forwardLevels[0] else: backwardLevels[0]
  appendOutput($(leadingLevel + 1))
  for position in 1 .. arraySize - 1:
    let neededLevel = if forwardLevels[position] > backwardLevels[position]: forwardLevels[position] else: backwardLevels[position]
    appendOutput(" ")
    appendOutput($(neededLevel + 1))
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
