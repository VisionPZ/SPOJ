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
  let roomCount = nextInt(inputData, scanPos)
  var roomTags = newSeq[int](roomCount)
  for roomIndex in 0 .. roomCount - 1:
    roomTags[roomIndex] = nextInt(inputData, scanPos)
  let stateSize = roomCount + 1
  let emptyTail = roomCount
  var currentStates = newSeq[int](stateSize * stateSize)
  for stateSlot in 0 .. currentStates.len - 1:
    currentStates[stateSlot] = -1
  currentStates[emptyTail * stateSize + emptyTail] = 0
  for roomIndex in 0 .. roomCount - 1:
    var nextStates = newSeq[int](currentStates.len)
    for stateSlot in 0 .. currentStates.len - 1:
      nextStates[stateSlot] = currentStates[stateSlot]
    for forwardTail in 0 .. roomCount:
      for backwardTail in 0 .. roomCount:
        let searchedCount = currentStates[forwardTail * stateSize + backwardTail]
        if searchedCount < 0:
          continue
        if forwardTail == emptyTail or roomTags[forwardTail] < roomTags[roomIndex]:
          let targetSlot = roomIndex * stateSize + backwardTail
          if searchedCount + 1 > nextStates[targetSlot]:
            nextStates[targetSlot] = searchedCount + 1
        if backwardTail == emptyTail or roomTags[backwardTail] > roomTags[roomIndex]:
          let targetSlot = forwardTail * stateSize + roomIndex
          if searchedCount + 1 > nextStates[targetSlot]:
            nextStates[targetSlot] = searchedCount + 1
    currentStates = nextStates
  var bestSearched = 0
  for stateSlot in 0 .. currentStates.len - 1:
    if currentStates[stateSlot] > bestSearched:
      bestSearched = currentStates[stateSlot]
  appendOutput($bestSearched)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
