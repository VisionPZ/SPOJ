const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] < '0': inc scanPos
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0':
    value = value * 10 + (int(inputData[scanPos]) - 48)
    inc scanPos
  return value

var inputData = ""
var currentLine = ""
while readLine(stdin, currentLine):
  inputData.add currentLine
  inputData.add '\n'

var scanPos = 0
let dataSets = nextInt(inputData, scanPos)
var outputBuffer = ""

for dataSetIndex in 0 ..< dataSets:
  let registerCount = nextInt(inputData, scanPos)
  let instructionCount = nextInt(inputData, scanPos)

  var leftOperand = newSeq[int](instructionCount)
  var rightOperand = newSeq[int](instructionCount)
  var tokenBefore = newSeq[bool](instructionCount)
  var tokenCount = newSeq[int](registerCount + 1)
  for registerIndex in 1 .. registerCount: tokenCount[registerIndex] = 1

  for instrIndex in 0 ..< instructionCount:
    let lowerIndex = nextInt(inputData, scanPos)
    let upperIndex = nextInt(inputData, scanPos)
    leftOperand[instrIndex] = lowerIndex
    rightOperand[instrIndex] = upperIndex
    tokenBefore[instrIndex] = tokenCount[upperIndex] > 0
    tokenCount[lowerIndex] += tokenCount[upperIndex]
    tokenCount[upperIndex] = 0

  var finalStranded = 0
  for registerIndex in 2 .. registerCount:
    if tokenCount[registerIndex] > 0: inc finalStranded

  var finalSlot = newSeq[int](registerCount + 1)
  for registerIndex in 0 .. registerCount: finalSlot[registerIndex] = registerIndex
  var needsCleanup = newSeq[bool](registerCount + 1)
  for registerIndex in 2 .. registerCount:
    if tokenCount[registerIndex] > 0: needsCleanup[registerIndex] = true

  var extraCleanup = 0
  var instrIndex = instructionCount - 1
  while instrIndex >= 0:
    let lowerIndex = leftOperand[instrIndex]
    let upperIndex = rightOperand[instrIndex]
    let landingSlot = finalSlot[upperIndex]
    if tokenBefore[instrIndex] and landingSlot > 1 and not needsCleanup[landingSlot]:
      needsCleanup[landingSlot] = true
      inc extraCleanup
    finalSlot[upperIndex] = finalSlot[lowerIndex]
    dec instrIndex

  let answer = 2 * finalStranded + extraCleanup
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
