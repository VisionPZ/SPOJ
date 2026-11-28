const flushBlockBytes = 1 shl 17
const sentinelValue = 9000000000000000000

type
  PlanePoint = object
    x: int64
    y: int64

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

proc crossProduct(first: PlanePoint, second: PlanePoint, third: PlanePoint): int64 =
  return (second.x - first.x) * (third.y - first.y) - (second.y - first.y) * (third.x - first.x)

proc crossPair(first: PlanePoint, second: PlanePoint): int64 =
  return first.x * second.y - second.x * first.y

let pointCount = nextInt(inputData, scanPos)
let vertexCount = nextInt(inputData, scanPos)
var points = newSeq[PlanePoint](pointCount)
for pointIndex in 0 .. pointCount - 1:
  points[pointIndex].x = int64(nextInt(inputData, scanPos))
  points[pointIndex].y = int64(nextInt(inputData, scanPos))
for pointIndex in 1 .. pointCount - 1:
  let currentPoint = points[pointIndex]
  var insertAt = pointIndex
  while insertAt > 0 and (points[insertAt - 1].x > currentPoint.x or
        (points[insertAt - 1].x == currentPoint.x and points[insertAt - 1].y > currentPoint.y)):
    points[insertAt] = points[insertAt - 1]
    insertAt -= 1
  points[insertAt] = currentPoint

var bestDoubledArea = sentinelValue
if vertexCount >= 3 and pointCount >= vertexCount:
  var dynamicTable = newSeq[int64]((pointCount + 1) * pointCount * (vertexCount + 1))
  for pivotIndex in 0 .. pointCount - 1:
    let pivotPoint = points[pivotIndex]
    var candidates = newSeq[PlanePoint]()
    for pointIndex in 0 .. pointCount - 1:
      let candidatePoint = points[pointIndex]
      if candidatePoint.y > pivotPoint.y or
         (candidatePoint.y == pivotPoint.y and candidatePoint.x > pivotPoint.x):
        candidates.add candidatePoint
    let candidateCount = candidates.len
    if candidateCount < vertexCount - 1:
      continue
    for candidateIndex in 1 .. candidateCount - 1:
      let currentCandidate = candidates[candidateIndex]
      var insertAt = candidateIndex
      while insertAt > 0 and crossProduct(pivotPoint, candidates[insertAt - 1], currentCandidate) < 0:
        candidates[insertAt] = candidates[insertAt - 1]
        insertAt -= 1
      candidates[insertAt] = currentCandidate
    for tableIndex in 0 .. dynamicTable.len - 1:
      dynamicTable[tableIndex] = sentinelValue
    for candidateIndex in 0 .. candidateCount - 1:
      let tableIndex = ((candidateCount + 1 + candidateCount) * candidateCount + candidateIndex)
      dynamicTable[tableIndex] = crossPair(pivotPoint, candidates[candidateIndex])
    for chosenCount in 1 .. vertexCount - 2:
      for previousIndex in 0 .. candidateCount:
        let previousPoint = if previousIndex == candidateCount: pivotPoint else: candidates[previousIndex]
        for currentIndex in 0 .. candidateCount - 1:
          let sourceIndex = ((chosenCount * (candidateCount + 1) + previousIndex) * candidateCount + currentIndex)
          let sourceValue = dynamicTable[sourceIndex]
          if sourceValue == sentinelValue:
            continue
          let currentPoint = candidates[currentIndex]
          for nextIndex in currentIndex + 1 .. candidateCount - 1:
            let nextPoint = candidates[nextIndex]
            if crossProduct(previousPoint, currentPoint, nextPoint) <= 0:
              continue
            let targetIndex = (((chosenCount + 1) * (candidateCount + 1) + currentIndex) * candidateCount + nextIndex)
            let candidateValue = sourceValue + crossPair(currentPoint, nextPoint)
            if candidateValue < dynamicTable[targetIndex]:
              dynamicTable[targetIndex] = candidateValue
    for previousIndex in 0 .. candidateCount - 1:
      for currentIndex in previousIndex + 1 .. candidateCount - 1:
        let sourceIndex = (((vertexCount - 1) * (candidateCount + 1) + previousIndex) * candidateCount + currentIndex)
        let sourceValue = dynamicTable[sourceIndex]
        if sourceValue == sentinelValue:
          continue
        if crossProduct(candidates[previousIndex], candidates[currentIndex], pivotPoint) <= 0:
          continue
        let candidateValue = sourceValue + crossPair(candidates[currentIndex], pivotPoint)
        if candidateValue > 0 and candidateValue < bestDoubledArea:
          bestDoubledArea = candidateValue

var answer: int64 = 0
if bestDoubledArea < sentinelValue:
  answer = bestDoubledArea div 2
appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
