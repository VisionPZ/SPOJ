import algorithm
import math
import tables

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
