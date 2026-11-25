import strutils
import math

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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

proc isRealCharacter(character: char): bool =
  return (character >= '0' and character <= '9') or character == '-' or
    character == '+' or character == '.' or character == 'e' or character == 'E'

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and not isRealCharacter(data[pos]):
    pos += 1
  var token = ""
  while pos < data.len and isRealCharacter(data[pos]):
    token.add data[pos]
    pos += 1
  return parseFloat(token)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc distanceBetween(x1: float64, y1: float64, x2: float64, y2: float64): float64 =
  let deltaX = x1 - x2
  let deltaY = y1 - y2
  return sqrt(deltaX * deltaX + deltaY * deltaY)

var caseNumber = 0
while true:
  let segmentCount = nextInt(inputData, scanPos)
  if segmentCount == 0:
    break
  caseNumber += 1
  let endpointCount = segmentCount * 2
  var endpointX = newSeq[float64](endpointCount)
  var endpointY = newSeq[float64](endpointCount)
  for segmentIndex in 0 .. segmentCount - 1:
    endpointX[segmentIndex * 2] = nextReal(inputData, scanPos)
    endpointY[segmentIndex * 2] = nextReal(inputData, scanPos)
    endpointX[segmentIndex * 2 + 1] = nextReal(inputData, scanPos)
    endpointY[segmentIndex * 2 + 1] = nextReal(inputData, scanPos)
  var endpointDistance = newSeq[seq[float64]](endpointCount)
  for endpointIndex in 0 .. endpointCount - 1:
    endpointDistance[endpointIndex] = newSeq[float64](endpointCount)
    for otherIndex in 0 .. endpointCount - 1:
      endpointDistance[endpointIndex][otherIndex] = distanceBetween(
        endpointX[endpointIndex], endpointY[endpointIndex],
        endpointX[otherIndex], endpointY[otherIndex])
  var originalLength = 0'f64
  for segmentIndex in 0 .. segmentCount - 1:
    originalLength += endpointDistance[segmentIndex * 2][segmentIndex * 2 + 1]
  let stateCount = (1 shl segmentCount) * endpointCount * 2
  var bestCost = newSeq[float64](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    bestCost[stateIndex] = 1e30
  for segmentIndex in 0 .. segmentCount - 1:
    let startMask = 1 shl segmentIndex
    for freeEnd in 0 .. 1:
      bestCost[(startMask * endpointCount + segmentIndex) * 2 + freeEnd] = 0'f64
  let fullMask = (1 shl segmentCount) - 1
  for usedMask in 1 .. fullMask:
    for lastSegment in 0 .. segmentCount - 1:
      if (usedMask and (1 shl lastSegment)) == 0:
        continue
      for freeEnd in 0 .. 1:
        let currentCost = bestCost[(usedMask * endpointCount + lastSegment) * 2 + freeEnd]
        if currentCost > 1e29:
          continue
        for nextSegment in 0 .. segmentCount - 1:
          if (usedMask and (1 shl nextSegment)) != 0:
            continue
          for connectingEnd in 0 .. 1:
            let followingEnd = 1 - connectingEnd
            let updatedMask = usedMask or (1 shl nextSegment)
            let updatedIndex = (updatedMask * endpointCount + nextSegment) * 2 + followingEnd
            let trialCost = currentCost + endpointDistance[
              lastSegment * 2 + freeEnd][nextSegment * 2 + connectingEnd]
            if trialCost < bestCost[updatedIndex]:
              bestCost[updatedIndex] = trialCost
  var shortestConnection = 1e30
  for lastSegment in 0 .. segmentCount - 1:
    for freeEnd in 0 .. 1:
      let finishedCost = bestCost[(fullMask * endpointCount + lastSegment) * 2 + freeEnd]
      if finishedCost < shortestConnection:
        shortestConnection = finishedCost
  let answer = originalLength + shortestConnection
  appendOutput("Case " & $caseNumber & ": " & formatFloat(answer, ffDecimal, 5))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
