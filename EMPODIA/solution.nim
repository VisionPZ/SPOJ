const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)

for caseIndex in 0 ..< caseCount:
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int](elementCount)
  for position in 0 ..< elementCount:
    values[position] = nextInt(inputData, scanPos)

  var minStack = newSeq[int](elementCount)
  var maxStack = newSeq[int](elementCount)
  var keyStackLink = newSeq[int](elementCount)
  var keyTop = newSeq[int](2 * elementCount + 1)
  var foundStarts = newSeq[int](elementCount)
  var foundEnds = newSeq[int](elementCount)
  var minStackTop = -1
  var maxStackTop = -1
  var foundCount = 0
  var rightmostStart = -1

  for rightPos in 0 ..< elementCount:
    let currentValue = values[rightPos]
    while maxStackTop >= 0 and values[maxStack[maxStackTop]] < currentValue:
      maxStackTop -= 1
    while minStackTop >= 0 and values[minStack[minStackTop]] > currentValue:
      let poppedPos = minStack[minStackTop]
      let poppedKeyOffset = values[poppedPos] - poppedPos + elementCount
      keyTop[poppedKeyOffset] = keyStackLink[poppedPos]
      minStackTop -= 1

    let currentKeyOffset = currentValue - rightPos + elementCount
    let candidateStart = keyTop[currentKeyOffset] - 1
    if candidateStart >= 0:
      let clearOfGreater = maxStackTop < 0 or candidateStart > maxStack[maxStackTop]
      if candidateStart > rightmostStart and clearOfGreater:
        foundStarts[foundCount] = candidateStart
        foundEnds[foundCount] = rightPos
        foundCount += 1
        rightmostStart = candidateStart

    keyStackLink[rightPos] = keyTop[currentKeyOffset]
    keyTop[currentKeyOffset] = rightPos + 1
    minStackTop += 1
    minStack[minStackTop] = rightPos
    maxStackTop += 1
    maxStack[maxStackTop] = rightPos

  appendOutput($foundCount)
  outputBuffer.add '\n'
  for pairIndex in 0 ..< foundCount:
    outputBuffer.add $(foundStarts[pairIndex] + 1)
    outputBuffer.add ' '
    outputBuffer.add $(foundEnds[pairIndex] + 1)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
