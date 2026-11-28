import math
import tables

const flushBlockBytes = 1 shl 17

type Edge = object
  neighbor: int
  segment: int
  angle: float64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc pointInside(vertexList: seq[(int, int)], polygon: seq[int],
                 queryX: int, queryY: int): bool =
  var inside = false
  var edgeIndex = 0
  while edgeIndex < polygon.len:
    let firstVertex = vertexList[polygon[edgeIndex]]
    let secondVertex = vertexList[polygon[(edgeIndex + 1) mod polygon.len]]
    let firstX = firstVertex[0]
    let firstY = firstVertex[1]
    let secondX = secondVertex[0]
    let secondY = secondVertex[1]
    if (firstY > queryY) != (secondY > queryY):
      let side = int64(secondX - firstX) * int64(queryY - firstY) -
                 int64(secondY - firstY) * int64(queryX - firstX)
      if (secondY > firstY and side > 0) or (secondY < firstY and side < 0):
        inside = not inside
    edgeIndex += 1
  return inside

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let stateCount = nextInt(inputData, scanPos)
  let segmentCount = nextInt(inputData, scanPos)
  if stateCount == 0 and segmentCount == 0:
    break

  var capitals = newSeq[(int, int)](stateCount)
  for capitalIndex in 0 ..< stateCount:
    let capitalX = nextInt(inputData, scanPos)
    let capitalY = nextInt(inputData, scanPos)
    capitals[capitalIndex] = (capitalX, capitalY)

  var vertexList = newSeq[(int, int)](0)
  var vertexIds = initTable[(int, int), int]()
  var segmentStarts = newSeq[int](segmentCount)
  var segmentEnds = newSeq[int](segmentCount)
  for segmentIndex in 0 ..< segmentCount:
    let firstX = nextInt(inputData, scanPos)
    let firstY = nextInt(inputData, scanPos)
    let secondX = nextInt(inputData, scanPos)
    let secondY = nextInt(inputData, scanPos)
    var firstId = 0
    if not vertexIds.hasKey((firstX, firstY)):
      firstId = vertexList.len
      vertexIds[(firstX, firstY)] = firstId
      vertexList.add (firstX, firstY)
    else:
      firstId = vertexIds[(firstX, firstY)]
    var secondId = 0
    if not vertexIds.hasKey((secondX, secondY)):
      secondId = vertexList.len
      vertexIds[(secondX, secondY)] = secondId
      vertexList.add (secondX, secondY)
    else:
      secondId = vertexIds[(secondX, secondY)]
    segmentStarts[segmentIndex] = firstId
    segmentEnds[segmentIndex] = secondId

  var adjacency = newSeq[seq[Edge]](vertexList.len)
  for vertexIndex in 0 ..< vertexList.len:
    adjacency[vertexIndex] = newSeq[Edge](0)
  for segmentIndex in 0 ..< segmentCount:
    let firstId = segmentStarts[segmentIndex]
    let secondId = segmentEnds[segmentIndex]
    let firstPoint = vertexList[firstId]
    let secondPoint = vertexList[secondId]
    let forwardAngle = arctan2(float64(secondPoint[1] - firstPoint[1]),
                              float64(secondPoint[0] - firstPoint[0]))
    let backwardAngle = arctan2(float64(firstPoint[1] - secondPoint[1]),
                               float64(firstPoint[0] - secondPoint[0]))
    adjacency[firstId].add Edge(neighbor: secondId, segment: segmentIndex,
                                angle: forwardAngle)
    adjacency[secondId].add Edge(neighbor: firstId, segment: segmentIndex,
                                 angle: backwardAngle)

  for vertexIndex in 0 ..< vertexList.len:
    var edges = adjacency[vertexIndex]
    var outerIndex = 1
    while outerIndex < edges.len:
      var innerIndex = outerIndex
      while innerIndex > 0 and edges[innerIndex].angle < edges[innerIndex - 1].angle:
        swap edges[innerIndex], edges[innerIndex - 1]
        innerIndex -= 1
      outerIndex += 1
    adjacency[vertexIndex] = edges

  var nextDirected = newSeq[int](2 * segmentCount)
  for directedEdge in 0 ..< 2 * segmentCount:
    let segmentIndex = directedEdge div 2
    let direction = directedEdge mod 2
    let fromVertex = if direction == 0: segmentStarts[segmentIndex]
                     else: segmentEnds[segmentIndex]
    let toVertex = if direction == 0: segmentEnds[segmentIndex]
                   else: segmentStarts[segmentIndex]
    let edgeList = adjacency[toVertex]
    var previousPosition = 0
    for edgePosition in 0 ..< edgeList.len:
      if edgeList[edgePosition].neighbor == fromVertex:
        previousPosition = edgePosition
    if edgeList.len > 0:
      previousPosition = (previousPosition - 1 + edgeList.len) mod edgeList.len
      let chosenEdge = edgeList[previousPosition]
      let nextDirection = if segmentStarts[chosenEdge.segment] == toVertex: 0 else: 1
      nextDirected[directedEdge] = 2 * chosenEdge.segment + nextDirection

  var faceOf = newSeq[int](2 * segmentCount)
  for directedEdge in 0 ..< 2 * segmentCount:
    faceOf[directedEdge] = -1
  var facePolygons = newSeq[seq[int]](0)
  for directedEdge in 0 ..< 2 * segmentCount:
    if faceOf[directedEdge] != -1:
      continue
    let faceIndex = facePolygons.len
    var polygon = newSeq[int](0)
    var currentEdge = directedEdge
    while faceOf[currentEdge] == -1:
      faceOf[currentEdge] = faceIndex
      let segmentIndex = currentEdge div 2
      let direction = currentEdge mod 2
      let fromVertex = if direction == 0: segmentStarts[segmentIndex]
                       else: segmentEnds[segmentIndex]
      polygon.add fromVertex
      currentEdge = nextDirected[currentEdge]
    facePolygons.add polygon

  var faceAreas = newSeq[float64](facePolygons.len)
  var lowerX = newSeq[int](facePolygons.len)
  var upperX = newSeq[int](facePolygons.len)
  var lowerY = newSeq[int](facePolygons.len)
  var upperY = newSeq[int](facePolygons.len)
  for faceIndex in 0 ..< facePolygons.len:
    let polygon = facePolygons[faceIndex]
    var doubleArea = 0.0
    var firstVertex = vertexList[polygon[0]]
    var minimumX = firstVertex[0]
    var maximumX = firstVertex[0]
    var minimumY = firstVertex[1]
    var maximumY = firstVertex[1]
    for edgeIndex in 0 ..< polygon.len:
      let firstPoint = vertexList[polygon[edgeIndex]]
      let secondPoint = vertexList[polygon[(edgeIndex + 1) mod polygon.len]]
      doubleArea += float64(firstPoint[0]) * float64(secondPoint[1]) -
                    float64(secondPoint[0]) * float64(firstPoint[1])
      if firstPoint[0] < minimumX: minimumX = firstPoint[0]
      if firstPoint[0] > maximumX: maximumX = firstPoint[0]
      if firstPoint[1] < minimumY: minimumY = firstPoint[1]
      if firstPoint[1] > maximumY: maximumY = firstPoint[1]
    faceAreas[faceIndex] = doubleArea
    lowerX[faceIndex] = minimumX
    upperX[faceIndex] = maximumX
    lowerY[faceIndex] = minimumY
    upperY[faceIndex] = maximumY

  var boundedFaces = newSeq[int](0)
  for faceIndex in 0 ..< facePolygons.len:
    if faceAreas[faceIndex] > 0:
      boundedFaces.add faceIndex

  var faceOwners = newSeq[int](facePolygons.len)
  for faceIndex in 0 ..< facePolygons.len:
    faceOwners[faceIndex] = 0
  for capitalIndex in 0 ..< stateCount:
    let capitalPoint = capitals[capitalIndex]
    var chosenFace = -1
    var chosenArea = 0.0
    for faceIndex in boundedFaces:
      if capitalPoint[0] < lowerX[faceIndex] or capitalPoint[0] > upperX[faceIndex]:
        continue
      if capitalPoint[1] < lowerY[faceIndex] or capitalPoint[1] > upperY[faceIndex]:
        continue
      if pointInside(vertexList, facePolygons[faceIndex], capitalPoint[0], capitalPoint[1]):
        if chosenFace == -1 or faceAreas[faceIndex] < chosenArea:
          chosenFace = faceIndex
          chosenArea = faceAreas[faceIndex]
    if chosenFace != -1:
      faceOwners[chosenFace] = capitalIndex + 1

  var parentFaces = newSeq[int](facePolygons.len)
  for faceIndex in 0 ..< facePolygons.len:
    parentFaces[faceIndex] = -1
  for faceIndex in boundedFaces:
    let sampleVertex = vertexList[facePolygons[faceIndex][0]]
    var chosenParent = -1
    var chosenArea = 0.0
    for otherFace in boundedFaces:
      if otherFace == faceIndex or faceAreas[otherFace] <= faceAreas[faceIndex]:
        continue
      if sampleVertex[0] < lowerX[otherFace] or sampleVertex[0] > upperX[otherFace]:
        continue
      if sampleVertex[1] < lowerY[otherFace] or sampleVertex[1] > upperY[otherFace]:
        continue
      if pointInside(vertexList, facePolygons[otherFace], sampleVertex[0], sampleVertex[1]):
        if chosenParent == -1 or faceAreas[otherFace] < chosenArea:
          chosenParent = otherFace
          chosenArea = faceAreas[otherFace]
    parentFaces[faceIndex] = chosenParent

  var enemies = newSeq[seq[bool]](stateCount + 1)
  for stateIndex in 0 .. stateCount:
    enemies[stateIndex] = newSeq[bool](stateCount + 1)
  for segmentIndex in 0 ..< segmentCount:
    let firstFace = faceOf[2 * segmentIndex]
    let secondFace = faceOf[2 * segmentIndex + 1]
    var firstOwner = 0
    var secondOwner = 0
    if faceAreas[firstFace] > 0 and faceAreas[secondFace] > 0:
      firstOwner = faceOwners[firstFace]
      secondOwner = faceOwners[secondFace]
    elif faceAreas[firstFace] > 0:
      firstOwner = faceOwners[firstFace]
      if parentFaces[firstFace] >= 0:
        secondOwner = faceOwners[parentFaces[firstFace]]
    elif faceAreas[secondFace] > 0:
      firstOwner = faceOwners[secondFace]
      if parentFaces[secondFace] >= 0:
        secondOwner = faceOwners[parentFaces[secondFace]]
    if firstOwner > 0 and secondOwner > 0 and firstOwner != secondOwner:
      enemies[firstOwner][secondOwner] = true
      enemies[secondOwner][firstOwner] = true

  for stateIndex in 1 .. stateCount:
    var enemyCount = 0
    for otherState in 1 .. stateCount:
      if enemies[stateIndex][otherState]:
        enemyCount += 1
    appendOutput($enemyCount)
    for otherState in 1 .. stateCount:
      if enemies[stateIndex][otherState]:
        appendOutput(" " & $otherState)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
