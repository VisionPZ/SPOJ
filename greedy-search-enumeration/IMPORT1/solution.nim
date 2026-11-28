import strutils

const flushBlockBytes = 1 shl 17
const unreachableDistance: int64 = 1000000000000

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
for caseIndex in 0 ..< caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var distances = newSeq[int64](nodeCount * nodeCount)
  var pathCounts = newSeq[int64](nodeCount * nodeCount)
  for sourceNode in 0 ..< nodeCount:
    for targetNode in 0 ..< nodeCount:
      let matrixIndex = sourceNode * nodeCount + targetNode
      if sourceNode == targetNode:
        distances[matrixIndex] = 0
        pathCounts[matrixIndex] = 1
      else:
        distances[matrixIndex] = unreachableDistance
  for edgeIndex in 0 ..< edgeCount:
    let firstNode = nextInt(inputData, scanPos) - 1
    let secondNode = nextInt(inputData, scanPos) - 1
    let edgeWeight = int64(nextInt(inputData, scanPos))
    let forwardIndex = firstNode * nodeCount + secondNode
    let backwardIndex = secondNode * nodeCount + firstNode
    distances[forwardIndex] = edgeWeight
    distances[backwardIndex] = edgeWeight
    pathCounts[forwardIndex] = 1
    pathCounts[backwardIndex] = 1
  for viaNode in 0 ..< nodeCount:
    for sourceNode in 0 ..< nodeCount:
      if sourceNode == viaNode:
        continue
      let sourceViaIndex = sourceNode * nodeCount + viaNode
      let sourceViaDistance = distances[sourceViaIndex]
      if sourceViaDistance >= unreachableDistance:
        continue
      let sourceViaCount = pathCounts[sourceViaIndex]
      for targetNode in 0 ..< nodeCount:
        if targetNode == viaNode:
          continue
        let viaTargetIndex = viaNode * nodeCount + targetNode
        let candidateDistance = sourceViaDistance + distances[viaTargetIndex]
        let directIndex = sourceNode * nodeCount + targetNode
        if candidateDistance < distances[directIndex]:
          distances[directIndex] = candidateDistance
          pathCounts[directIndex] = sourceViaCount * pathCounts[viaTargetIndex]
        elif candidateDistance == distances[directIndex]:
          pathCounts[directIndex] = pathCounts[directIndex] +
                                    sourceViaCount * pathCounts[viaTargetIndex]
  for importanceNode in 0 ..< nodeCount:
    var importance: float = 0.0
    for sourceNode in 0 ..< nodeCount:
      if sourceNode == importanceNode:
        continue
      let sourceViaIndex = sourceNode * nodeCount + importanceNode
      let sourceViaDistance = distances[sourceViaIndex]
      if sourceViaDistance >= unreachableDistance:
        continue
      for targetNode in 0 ..< nodeCount:
        if targetNode == importanceNode or targetNode == sourceNode:
          continue
        let viaTargetIndex = importanceNode * nodeCount + targetNode
        let viaTargetDistance = distances[viaTargetIndex]
        if viaTargetDistance >= unreachableDistance:
          continue
        let directIndex = sourceNode * nodeCount + targetNode
        if sourceViaDistance + viaTargetDistance == distances[directIndex]:
          let throughPaths = float(pathCounts[sourceViaIndex]) *
                             float(pathCounts[viaTargetIndex])
          if pathCounts[directIndex] > 0:
            importance = importance + throughPaths / float(pathCounts[directIndex])
    appendOutput(formatFloat(importance, ffDecimal, 3))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
