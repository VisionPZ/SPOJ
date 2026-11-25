# BRDGS — Bridges (SPOJ)
<https://www.spoj.com/problems/BRDGS/>

## Problem

Rivers cut a planet into land pieces, and a bridge across a river segment costs that river's width. Connect all land pieces with the least total bridge cost.

The first line gives the case count. Each case starts with `riverCount`, then that many lines of five integers: two latitude and longitude pairs for the river ends, and the width.

Print `Case #X: C` per case with the least total cost.

The table lists the input and judge limits.

| item | bound |
|---|---|
| cases | fewer than 200 |
| rivers N | at most 500 |
| latitude D | -90 to 90 degrees |
| longitude F | 0 to 359 degrees |
| river width W | at most 1000000 |
| judge limit | 11270 ms, 1536 MB |

Each river follows the shorter great-circle arc between its ends.

The sample below is reconstructed from the statement's collapsed example.

```
3
2
90 0 -90 0 4
90 90 -90 90 1
3
90 0 -90 0 2
90 90 -90 90 4
90 180 -90 180 6
2
0 0 0 90 3
90 0 -90 0 5
```

```
Case #1: 1
Case #2: 6
Case #3: 0
```

Two meridian rivers form one loop and need one bridge.

## Idea

Bridge sites are edges of the dual map, like stitches joining pieces of a quilt.

The algorithm finds every arc intersection, sorts points along each river, and runs Kruskal in falling width on the river segments. It subtracts the kept forest weight from the total segment weight.

Each pair of rivers costs one vector cross product, and the segment sort costs O(E log E). Walking all face boundaries explicitly would be far harder and slower.

The complement identity turns that walk into one sort.

## Why It Works

1. Two great-circle arcs meet where their plane normals cross.
2. Endpoints and crossings split each river into consecutive segments.
3. The river graph has faces equal to E minus V plus components plus one.
4. In a planar graph, complementing a spanning forest gives a spanning tree of the dual.
5. Therefore the dual minimum cost is total segment weight minus the maximum forest weight.

The table names the geometry values.

| term | meaning |
|---|---|
| `Point3D` | unit vector for a sphere point |
| `normal` | unit normal of a river's great circle |
| `RiverSegment` | one arc piece with its width |
| `keptWeight` | weight of the maximum forest |

For two meridians of widths 4 and 1, there are two segments and one forest edge of weight 4. The answer is 5 minus 4, which is 1.

Rounding point coordinates to nine decimals unifies crossings computed from different pairs. The tolerance in `liesOnArc` absorbs floating error near an endpoint.

Widths and totals stay in `int64`.

## Code

**Geometry helpers.** Vectors, normals, and identity keys describe the sphere.

```nim
const flushBlockBytes = 1 shl 17
const coordinateScale = 1000000000.0
const angleTolerance = 1e-9
const tinyCrossProduct = 1e-12

type Point3D = tuple[x: float64, y: float64, z: float64]
type RiverSegment = tuple[weight: int64, firstPoint: int, secondPoint: int]
type AngledPoint = tuple[angle: float64, pointId: int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

proc sphericalVector(latitudeDegrees: int, longitudeDegrees: int): Point3D =
  let latitude = float64(latitudeDegrees) * PI / 180.0
  let longitude = float64(longitudeDegrees) * PI / 180.0
  let horizontalRadius = cos(latitude)
  return (horizontalRadius * cos(longitude), horizontalRadius * sin(longitude), sin(latitude))

proc dotProduct(first: Point3D, second: Point3D): float64 =
  return first.x * second.x + first.y * second.y + first.z * second.z

proc crossProduct(first: Point3D, second: Point3D): Point3D =
  return (first.y * second.z - first.z * second.y,
          first.z * second.x - first.x * second.z,
          first.x * second.y - first.y * second.x)

proc normalized(vector: Point3D): Point3D =
  let magnitude = sqrt(dotProduct(vector, vector))
  return (vector.x / magnitude, vector.y / magnitude, vector.z / magnitude)

proc liesOnArc(point: Point3D, startPoint: Point3D, endPoint: Point3D, normal: Point3D): bool =
  let beforeTurn = dotProduct(crossProduct(startPoint, point), normal)
  let afterTurn = dotProduct(crossProduct(point, endPoint), normal)
  return beforeTurn >= -angleTolerance and afterTurn >= -angleTolerance

proc pointIdentity(point: Point3D): string =
  return $int64(round(point.x * coordinateScale)) & "," &
         $int64(round(point.y * coordinateScale)) & "," &
         $int64(round(point.z * coordinateScale))
```

Each point maps to a unit vector. Cross products give great-circle normals.

Rounded keys unify shared crossings.

**Arrangement.** Crossings are found, ordered, and split into segments.

```nim

proc compareAngle(left: AngledPoint, right: AngledPoint): int =
  if left.angle < right.angle:
    return -1
  if left.angle > right.angle:
    return 1
  return 0

proc compareWeight(left: RiverSegment, right: RiverSegment): int =
  if left.weight > right.weight:
    return -1
  if left.weight < right.weight:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let riverCount = nextInt(inputData, scanPos)
  var startPoints = newSeq[Point3D](riverCount)
  var endPoints = newSeq[Point3D](riverCount)
  var normals = newSeq[Point3D](riverCount)
  var widths = newSeq[int64](riverCount)
  var allPoints = newSeq[Point3D]()
  var pointIds = initTable[string, int]()

  proc pointIndex(point: Point3D): int =
    let identity = pointIdentity(point)
    if pointIds.hasKey(identity):
      return pointIds[identity]
    let assignedIndex = allPoints.len
    allPoints.add point
    pointIds[identity] = assignedIndex
    return assignedIndex

  for riverIndex in 0 .. riverCount - 1:
    let firstLatitude = nextInt(inputData, scanPos)
    let firstLongitude = nextInt(inputData, scanPos)
    let secondLatitude = nextInt(inputData, scanPos)
    let secondLongitude = nextInt(inputData, scanPos)
    widths[riverIndex] = int64(nextInt(inputData, scanPos))
    startPoints[riverIndex] = sphericalVector(firstLatitude, firstLongitude)
    endPoints[riverIndex] = sphericalVector(secondLatitude, secondLongitude)
    normals[riverIndex] = normalized(crossProduct(startPoints[riverIndex], endPoints[riverIndex]))
    discard pointIndex(startPoints[riverIndex])
    discard pointIndex(endPoints[riverIndex])

  var orderedPoints = newSeq[seq[int]]()
```

Both directions of each crossing are tested. Angles sort the points along each river.

Duplicate ids are dropped before segments are built.

**Kruskal.** Segments are sorted by falling width and merged with a union-find.

```nim
  for riverIndex in 0 .. riverCount - 1:
    let startPoint = startPoints[riverIndex]
    let endPoint = endPoints[riverIndex]
    let normal = normals[riverIndex]
    var hits = newSeq[int]()
    hits.add pointIndex(startPoint)
    for otherIndex in 0 .. riverCount - 1:
      if otherIndex == riverIndex:
        continue
      let crossingNormals = crossProduct(normal, normals[otherIndex])
      if sqrt(dotProduct(crossingNormals, crossingNormals)) < tinyCrossProduct:
        continue
      for signValue in [1.0, -1.0]:
        let candidate = normalized((crossingNormals.x * signValue,
                                    crossingNormals.y * signValue,
                                    crossingNormals.z * signValue))
        if liesOnArc(candidate, startPoint, endPoint, normal) and
           liesOnArc(candidate, startPoints[otherIndex], endPoints[otherIndex], normals[otherIndex]):
          hits.add pointIndex(candidate)
    hits.add pointIndex(endPoint)
    let directionBase = dotProduct(startPoint, endPoint)
    let directionVector = normalized((endPoint.x - directionBase * startPoint.x,
                                      endPoint.y - directionBase * startPoint.y,
                                      endPoint.z - directionBase * startPoint.z))
    var angledHits = newSeq[AngledPoint]()
    for hitId in hits:
      let hitPoint = allPoints[hitId]
      let hitAngle = arctan2(dotProduct(hitPoint, directionVector), dotProduct(hitPoint, startPoint))
      angledHits.add (angle: hitAngle, pointId: hitId)
    angledHits.sort(compareAngle)
    var uniqueHits = newSeq[int]()
    for angledHit in angledHits:
      if uniqueHits.len == 0 or uniqueHits[uniqueHits.len - 1] != angledHit.pointId:
        uniqueHits.add angledHit.pointId
    orderedPoints.add uniqueHits

  var segments = newSeq[RiverSegment]()
  var totalWeight: int64 = 0
  for riverIndex in 0 .. riverCount - 1:
    let pointIdsOnRiver = orderedPoints[riverIndex]
    for segmentIndex in 0 .. pointIdsOnRiver.len - 2:
      segments.add (weight: widths[riverIndex],
                    firstPoint: pointIdsOnRiver[segmentIndex],
                    secondPoint: pointIdsOnRiver[segmentIndex + 1])
      totalWeight = totalWeight + widths[riverIndex]
  segments.sort(compareWeight)

  var parent = newSeq[int](allPoints.len)
  for pointNumber in 0 .. parent.len - 1:
    parent[pointNumber] = pointNumber

  proc findRoot(node: int): int =
    var current = node
    while parent[current] != current:
      parent[current] = parent[parent[current]]
      current = parent[current]
    return current

  var keptWeight: int64 = 0
  for segment in segments:
    let firstRoot = findRoot(segment.firstPoint)
    let secondRoot = findRoot(segment.secondPoint)
    if firstRoot != secondRoot:
      parent[firstRoot] = secondRoot
      keptWeight = keptWeight + segment.weight
  let answerValue = totalWeight - keptWeight
  appendOutput("Case #" & $caseIndex & ": " & $answerValue & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Equal vertices share one root. A merge adds the segment width to `keptWeight`.

The difference with `totalWeight` is the bridge cost.

## Complexity

The table shows the work in each phase.

| phase | time | space |
|---|---|---|
| input read | 5N numbers per case | one input string |
| intersections | one cross product per river pair | one point per crossing |
| sort | E segment comparisons | E segments |
| Kruskal | one union-find find per segment | V parent entries |

E is the number of arc segments and V is the number of distinct endpoints and crossings.

| measure | Big O |
|---|---|
| time | O(N squared + E log E) per case |
| space | O(N squared) per case |

Tracing every face by hand would need a full planar traversal. The planar complement identity needs only a descending Kruskal pass.
