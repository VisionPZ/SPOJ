const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] < '0': inc i
  var value = 0
  while i < inputData.len and inputData[i] >= '0':
    value = value * 10 + (int(inputData[i]) - 48)
    inc i
  return value

var inputData = ""
var currentLine = ""
while readLine(stdin, currentLine):
  inputData.add currentLine
  inputData.add '\n'

var i = 0
let dataSets = nextInt(inputData, i)
var outputBuffer = ""

for j in 0 ..< dataSets:
  let registerCount = nextInt(inputData, i)
  let instructionCount = nextInt(inputData, i)

  var leftOperand = newSeq[int](instructionCount)
  var rightOperand = newSeq[int](instructionCount)
  var tokenBefore = newSeq[bool](instructionCount)
  var tokenCount = newSeq[int](registerCount + 1)
  for k in 1 .. registerCount: tokenCount[k] = 1

  for l in 0 ..< instructionCount:
    let lowerIndex = nextInt(inputData, i)
    let upperIndex = nextInt(inputData, i)
    leftOperand[l] = lowerIndex
    rightOperand[l] = upperIndex
    tokenBefore[l] = tokenCount[upperIndex] > 0
    tokenCount[lowerIndex] += tokenCount[upperIndex]
    tokenCount[upperIndex] = 0

  var finalStranded = 0
  for k in 2 .. registerCount:
    if tokenCount[k] > 0: inc finalStranded

  var finalSlot = newSeq[int](registerCount + 1)
  for k in 0 .. registerCount: finalSlot[k] = k
  var needsCleanup = newSeq[bool](registerCount + 1)
  for k in 2 .. registerCount:
    if tokenCount[k] > 0: needsCleanup[k] = true

  var extraCleanup = 0
  var l = instructionCount - 1
  while l >= 0:
    let lowerIndex = leftOperand[l]
    let upperIndex = rightOperand[l]
    let landingSlot = finalSlot[upperIndex]
    if tokenBefore[l] and landingSlot > 1 and not needsCleanup[landingSlot]:
      needsCleanup[landingSlot] = true
      inc extraCleanup
    finalSlot[upperIndex] = finalSlot[lowerIndex]
    dec l

  let answer = 2 * finalStranded + extraCleanup
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
