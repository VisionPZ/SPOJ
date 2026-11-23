const infiniteToll = high(int) div 4
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and inputData[scanPos] != '-' and
      (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1
  if scanPos < dataLength and inputData[scanPos] == '-':
    signValue = -1
    scanPos += 1
  var numberValue = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    numberValue = numberValue * 10 + (int(inputData[scanPos]) - 48)
    scanPos += 1
  return signValue * numberValue

var inputData = ""
var inputLine: TaintedString = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""
var scanPos = 0

while true:
  let stateCount = nextInt(inputData, scanPos)
  let timeLimit = nextInt(inputData, scanPos)
  if stateCount == 0 and timeLimit == 0:
    break

  let tableSize = stateCount * stateCount
  var travelTimes = newSeq[int](tableSize)
  var tollAmounts = newSeq[int](tableSize)
  for cellIndex in 0 .. tableSize - 1:
    travelTimes[cellIndex] = nextInt(inputData, scanPos)
  for cellIndex in 0 .. tableSize - 1:
    tollAmounts[cellIndex] = nextInt(inputData, scanPos)

  let timeStride = timeLimit + 1
  let totalStates = stateCount * timeStride
  let queueCapacity = totalStates + 1
  var minTolls = newSeq[int](totalStates)
  var queuePresent = newSeq[bool](totalStates)
  var stateQueue = newSeq[int](queueCapacity)
  for stateIndex in 0 .. totalStates - 1:
    minTolls[stateIndex] = infiniteToll
    queuePresent[stateIndex] = false

  var queueHead = 0
  var queueTail = 0
  stateQueue[queueTail] = 0
  queueTail = (queueTail + 1) mod queueCapacity
  queuePresent[0] = true
  minTolls[0] = 0

  while queueHead != queueTail:
    let currentState = stateQueue[queueHead]
    queueHead = (queueHead + 1) mod queueCapacity
    queuePresent[currentState] = false
    let currentNode = currentState div timeStride
    let currentTime = currentState mod timeStride
    let baseToll = minTolls[currentState]
    let rowOffset = currentNode * stateCount
    for targetNode in 0 .. stateCount - 1:
      let arrivalTime = currentTime + travelTimes[rowOffset + targetNode]
      if arrivalTime > timeLimit:
        continue
      let candidateToll = baseToll + tollAmounts[rowOffset + targetNode]
      let targetState = targetNode * timeStride + arrivalTime
      if candidateToll < minTolls[targetState]:
        minTolls[targetState] = candidateToll
        if not queuePresent[targetState]:
          queuePresent[targetState] = true
          stateQueue[queueTail] = targetState
          queueTail = (queueTail + 1) mod queueCapacity

  let destinationBase = (stateCount - 1) * timeStride
  var bestToll = infiniteToll
  var bestTime = 0
  for elapsedTime in 0 .. timeLimit:
    let reachedToll = minTolls[destinationBase + elapsedTime]
    if reachedToll < bestToll:
      bestToll = reachedToll
      bestTime = elapsedTime

  outputBuffer.add $bestToll
  outputBuffer.add ' '
  outputBuffer.add $bestTime
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
