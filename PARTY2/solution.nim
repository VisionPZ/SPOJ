const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const minimumGroupCount = 3

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc gcdValues(leftValue, rightValue: int): int =
  var firstValue = leftValue
  var secondValue = rightValue
  while secondValue != 0:
    let remainder = firstValue mod secondValue
    firstValue = secondValue
    secondValue = remainder
  return firstValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let killerCount = nextInt(inputData, scanPos)
  let sightingCount = nextInt(inputData, scanPos)
  if killerCount <= 0 or sightingCount <= 0:
    break
  var outgoingHead = newSeq[int](killerCount)
  var incomingHead = newSeq[int](killerCount)
  var edgeSource = newSeq[int](sightingCount)
  var edgeTarget = newSeq[int](sightingCount)
  var nextOutgoing = newSeq[int](sightingCount)
  var nextIncoming = newSeq[int](sightingCount)
  for headIndex in 0 .. killerCount - 1:
    outgoingHead[headIndex] = -1
    incomingHead[headIndex] = -1
  for edgeIndex in 0 .. sightingCount - 1:
    let sourceKiller = nextInt(inputData, scanPos) - 1
    let targetKiller = nextInt(inputData, scanPos) - 1
    edgeSource[edgeIndex] = sourceKiller
    edgeTarget[edgeIndex] = targetKiller
    nextOutgoing[edgeIndex] = outgoingHead[sourceKiller]
    outgoingHead[sourceKiller] = edgeIndex
    nextIncoming[edgeIndex] = incomingHead[targetKiller]
    incomingHead[targetKiller] = edgeIndex
  var levels = newSeq[int](killerCount)
  var visited = newSeq[bool](killerCount)
  var traversalStack = newSeq[int](killerCount)
  for startKiller in 0 .. killerCount - 1:
    if visited[startKiller]:
      continue
    levels[startKiller] = 0
    visited[startKiller] = true
    var stackTop = 0
    traversalStack[stackTop] = startKiller
    stackTop += 1
    while stackTop > 0:
      stackTop -= 1
      let currentKiller = traversalStack[stackTop]
      var edgeIndex = outgoingHead[currentKiller]
      while edgeIndex != -1:
        let neighborKiller = edgeTarget[edgeIndex]
        if not visited[neighborKiller]:
          levels[neighborKiller] = levels[currentKiller] + 1
          visited[neighborKiller] = true
          traversalStack[stackTop] = neighborKiller
          stackTop += 1
        edgeIndex = nextOutgoing[edgeIndex]
      edgeIndex = incomingHead[currentKiller]
      while edgeIndex != -1:
        let neighborKiller = edgeSource[edgeIndex]
        if not visited[neighborKiller]:
          levels[neighborKiller] = levels[currentKiller] - 1
          visited[neighborKiller] = true
          traversalStack[stackTop] = neighborKiller
          stackTop += 1
        edgeIndex = nextIncoming[edgeIndex]
  var cycleGcd = 0
  for edgeIndex in 0 .. sightingCount - 1:
    let shift = levels[edgeTarget[edgeIndex]] - levels[edgeSource[edgeIndex]] - 1
    if shift < 0:
      cycleGcd = gcdValues(cycleGcd, -shift)
    else:
      cycleGcd = gcdValues(cycleGcd, shift)
  if cycleGcd == 0:
    appendOutput($killerCount & " " & $minimumGroupCount)
  elif cycleGcd < minimumGroupCount:
    appendOutput("-1 -1")
  else:
    var smallestGroups = cycleGcd
    for candidate in minimumGroupCount .. cycleGcd:
      if cycleGcd mod candidate == 0:
        smallestGroups = candidate
        break
    appendOutput($cycleGcd & " " & $smallestGroups)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
