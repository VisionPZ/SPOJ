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
  let personCount = nextInt(inputData, scanPos)
  var heights = newSeq[int](personCount)
  for personIndex in 0 .. personCount - 1:
    heights[personIndex] = nextInt(inputData, scanPos)

  let doubledLength = 2 * personCount
  var doubledHeights = newSeq[int](doubledLength)
  for placeIndex in 0 .. doubledLength - 1:
    doubledHeights[placeIndex] = heights[placeIndex mod personCount]

  var rightTaller = newSeq[int](personCount)
  var monotonicStack = newSeq[int](doubledLength)
  var stackSize = 0
  for placeIndex in countdown(doubledLength - 1, 0):
    while stackSize > 0 and doubledHeights[monotonicStack[stackSize - 1]] <= doubledHeights[placeIndex]:
      stackSize -= 1
    if placeIndex < personCount:
      if stackSize > 0:
        rightTaller[placeIndex] = monotonicStack[stackSize - 1] mod personCount
      else:
        rightTaller[placeIndex] = -1
    monotonicStack[stackSize] = placeIndex
    stackSize += 1

  var leftTaller = newSeq[int](personCount)
  stackSize = 0
  for placeIndex in 0 .. doubledLength - 1:
    while stackSize > 0 and doubledHeights[monotonicStack[stackSize - 1]] <= doubledHeights[placeIndex]:
      stackSize -= 1
    if placeIndex >= personCount:
      let personIndex = placeIndex - personCount
      if stackSize > 0:
        leftTaller[personIndex] = monotonicStack[stackSize - 1] mod personCount
      else:
        leftTaller[personIndex] = -1
    monotonicStack[stackSize] = placeIndex
    stackSize += 1

  for personIndex in 0 .. personCount - 1:
    if leftTaller[personIndex] < 0:
      appendOutput("-1 ")
    else:
      appendOutput($(leftTaller[personIndex] + 1))
      appendOutput(" ")
    if rightTaller[personIndex] < 0:
      appendOutput("-1\n")
    else:
      appendOutput($(rightTaller[personIndex] + 1))
      appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
