# WAR — Art of War (SPOJ)

<https://www.spoj.com/problems/WAR/>

## Problem

Given capital points and non-crossing border segments, list which states share a border with each state. Two states are enemies exactly when a border segment separates them.

Each case starts with n states and m segments, followed by n capital coordinates and m segments with four coordinates each. A case with n = m = 0 ends the input. For each state, print the number of enemies followed by their state numbers in ascending order.

| item | bound |
|---|---|
| states n | 1 to 600 |
| border segments m | 1 to 4000 |
| coordinates | integers |
| judge limit | 5000 ms, 1536 MB |

Borders never cross and each region holds one capital, so the geometry determines every answer.

Sample input:

```
4 12
3 2
11 8
12 17
1 19
0 0 10 0
10 0 20 0
20 0 20 10
20 10 20 20
20 20 10 20
10 20 0 20
0 20 0 10
0 10 0 0
10 0 10 10
0 10 10 10
20 10 10 10
10 20 10 10
4 16
170 13
24 88
152 49
110 130
60 60 140 60
140 60 140 140
140 140 60 140
60 140 60 60
0 0 200 0
200 0 200 200
200 200 0 200
0 200 0 0
40 40 160 40
160 40 160 160
160 160 40 160
40 160 40 40
20 20 180 20
180 20 180 180
180 180 20 180
20 180 20 20
0 0
```

Sample output:

```
2 2 4
2 1 3
2 2 4
2 1 3
1 2
2 1 3
2 2 4
1 3
```

## Idea

Treat the map like a jigsaw puzzle: walk along a border with the puzzle piece on your left, and each closed walk traces one region. Planar face traversal turns every directed segment into the next directed segment at its endpoint. Each capital is then assigned to the smallest face polygon that contains it, and shared segments reveal enemy pairs.

Testing every capital against every segment side would need expensive geometric searches per border. One angular sort per vertex and one walk per directed segment settle all regions at once.

## Why It Works

1. Sorting outgoing borders by angle gives a cyclic order around each vertex.
2. Taking the clockwise predecessor of the incoming direction keeps the face on the left of each directed segment.
3. Each directed segment belongs to exactly one face, so the walks partition the map.
4. A positive signed area marks a bounded face; a negative one marks the wasteland side.
5. A capital belongs to the smallest bounded polygon that contains it, which handles nested regions.
6. A segment shared by two bounded faces joins their two owners.
7. A segment with one bounded face joins that owner to the owner of its smallest containing parent face, or to nobody at the outside.

| term | meaning |
|---|---|
| `adjacency` | outgoing border edges sorted by angle at each vertex |
| `faceOf` | face index of each directed segment |
| `faceOwners` | state capital assigned to each face |
| `parentFaces` | smallest bounded face containing a given face |
| `pointInside` | ray-crossing test for a capital against a polygon |

Enemy lists are symmetric, and ascending indices come from a final scan over states.

A script traced the four faces of the first sample case.

```
faces:
  0 area 100 owner 1 parent -1
  1 area -400 owner 0 parent -1
  2 area 100 owner 2 parent -1
  3 area 100 owner 3 parent -1
  4 area 100 owner 4 parent -1
2 2 4
2 1 3
2 2 4
2 1 3
```

The negative-area face is wasteland, so the outer borders create no enemies and the four inner borders create four pairs.

Areas use floating point only for sign and containment ordering, so rounding cannot change a face assignment. The ray test uses exact integer products for a capital strictly inside a region.

## Code

**Reader and point test.** All cases are read as tokens, and ray crossing tests capital positions against face polygons.

```nim
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
```

The scanner accepts minus signs for coordinates.
A hash table will map endpoint pairs to vertex ids.
The ray test multiplies in 64-bit integers to stay exact.

**Vertices and angular order.** Each segment is split into two directed edges, and each vertex keeps its neighbors in angle order.

```nim
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
```

Endpoint hashing keeps vertex lookup fast.
Insertion sort fits the small degree of each vertex.
The clockwise predecessor gives the next edge on the same face.

**Face walks and capital ownership.** Each closed walk becomes one polygon, and capitals choose their smallest containing face.

```nim
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
```

Bounding boxes skip most containment tests.
Positive area means the face lies inside its cycle.
The parent chain resolves nested states and the outside wasteland.

**Enemy pairs and buffered output.** Each segment connects the two owners of its sides, then states are printed in index order.

```nim
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
```

The two directed sides of a segment give its two regions.
A zero owner means wasteland and creates no enemy pair.
The final scan emits each enemy list in ascending order.

## Complexity

Each segment creates two directed edges, and each is visited once in the face walks.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | capital and segment arrays |
| angular sort | O(m log m) across all vertices | adjacency lists |
| face walks | O(m) directed edge visits | face polygons |
| ownership | O(n f) containment tests | owner and parent arrays |
| output | one buffered write per block | block buffer |

Containment tests use bounding boxes first, which keeps them cheap.

| measure | Big O |
|---|---|
| time per case | O(m log m + n f) |
| space per case | O(m + n + f) |

Checking every capital against every segment side would take far more geometric work, while the face walks label each side once. The planar traversal settles all enemy pairs with one consistent sweep.
