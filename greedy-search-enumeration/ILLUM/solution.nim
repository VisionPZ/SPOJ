const flushBlockBytes = 1 shl 17
const shadowEpsilon = 1e-9

type Vec3 = object
  x: float64
  y: float64
  z: float64

type Point2 = object
  u: float64
  v: float64

type Cube = object
  vertices: seq[Vec3]
  edges: seq[(int, int)]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextFloat(data: string, pos: var int): float64 =
  while pos < data.len and data[pos] != '-' and
        (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1.0
  if pos < data.len and data[pos] == '-':
    signValue = -1.0
    pos += 1
  var wholePart = 0.0
  var fraction = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var place = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fraction += float64(int(data[pos]) - 48) * place
      place *= 0.1
      pos += 1
  return signValue * (wholePart + fraction)

proc vecSub(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)

proc vecAdd(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)

proc vecScale(value: Vec3, factor: float64): Vec3 =
  return Vec3(x: value.x * factor, y: value.y * factor, z: value.z * factor)

proc vecDot(left: Vec3, right: Vec3): float64 =
  return left.x * right.x + left.y * right.y + left.z * right.z

proc vecCross(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.y * right.z - left.z * right.y,
              y: left.z * right.x - left.x * right.z,
              z: left.x * right.y - left.y * right.x)

proc makeCube(base: Vec3, edgeOne: Vec3, edgeTwo: Vec3, edgeThree: Vec3): Cube =
  result.vertices = newSeq[Vec3](8)
  for firstBit in 0 .. 1:
    for secondBit in 0 .. 1:
      for thirdBit in 0 .. 1:
        let vertexIndex = firstBit * 4 + secondBit * 2 + thirdBit
        var location = base
        if firstBit == 1:
          location = vecAdd(location, edgeOne)
        if secondBit == 1:
          location = vecAdd(location, edgeTwo)
        if thirdBit == 1:
          location = vecAdd(location, edgeThree)
        result.vertices[vertexIndex] = location
  result.edges = newSeq[(int, int)](0)
  for vertexIndex in 0 .. 7:
    for axis in 0 .. 2:
      let otherIndex = vertexIndex xor (1 shl axis)
      if vertexIndex < otherIndex:
        result.edges.add (vertexIndex, otherIndex)

proc faceIndices(axis: int, side: int): seq[int] =
  var otherAxes: seq[int] = @[]
  for candidate in 0 .. 2:
    if candidate != axis:
      otherAxes.add candidate
  result = newSeq[int](4)
  let cornerBits = [(0, 0), (1, 0), (1, 1), (0, 1)]
  for cornerIndex in 0 .. 3:
    var coordinates = [0, 0, 0]
    coordinates[axis] = side
    coordinates[otherAxes[0]] = cornerBits[cornerIndex][0]
    coordinates[otherAxes[1]] = cornerBits[cornerIndex][1]
    result[cornerIndex] = coordinates[0] * 4 + coordinates[1] * 2 + coordinates[2]

proc polygonArea(points: seq[Point2]): float64 =
  var doubled = 0.0
  for index in 0 ..< points.len:
    let nextIndex = (index + 1) mod points.len
    doubled += points[index].u * points[nextIndex].v -
               points[nextIndex].u * points[index].v
  return doubled * 0.5

proc cross2(origin: Point2, first: Point2, second: Point2): float64 =
  return (first.u - origin.u) * (second.v - origin.v) -
         (first.v - origin.v) * (second.u - origin.u)

proc convexHull(points: seq[Point2]): seq[Point2] =
  var sortedPoints = points
  var orderIndex = 1
  while orderIndex < sortedPoints.len:
    var innerIndex = orderIndex
    while innerIndex > 0 and
          (sortedPoints[innerIndex].u < sortedPoints[innerIndex - 1].u or
           (sortedPoints[innerIndex].u == sortedPoints[innerIndex - 1].u and
            sortedPoints[innerIndex].v < sortedPoints[innerIndex - 1].v)):
      swap sortedPoints[innerIndex], sortedPoints[innerIndex - 1]
      innerIndex -= 1
    orderIndex += 1
  var uniquePoints = newSeq[Point2](0)
  for point in sortedPoints:
    if uniquePoints.len > 0 and point.u == uniquePoints[uniquePoints.len - 1].u and
       point.v == uniquePoints[uniquePoints.len - 1].v:
      continue
    uniquePoints.add point
  if uniquePoints.len <= 2:
    return uniquePoints
  var lower = newSeq[Point2](0)
  for point in uniquePoints:
    while lower.len >= 2 and cross2(lower[lower.len - 2], lower[lower.len - 1], point) <= 0:
      lower.setLen(lower.len - 1)
    lower.add point
  var upper = newSeq[Point2](0)
  var reverseIndex = uniquePoints.len - 1
  while reverseIndex >= 0:
    let point = uniquePoints[reverseIndex]
    while upper.len >= 2 and cross2(upper[upper.len - 2], upper[upper.len - 1], point) <= 0:
      upper.setLen(upper.len - 1)
    upper.add point
    reverseIndex -= 1
  lower.setLen(lower.len - 1)
  upper.setLen(upper.len - 1)
  return lower & upper

proc insideEdge(point: Point2, first: Point2, second: Point2): bool =
  return cross2(first, second, point) >= -1e-12

proc edgeIntersection(startPoint: Point2, endPoint: Point2,
                      first: Point2, second: Point2): Point2 =
  let firstSide = cross2(first, second, startPoint)
  let secondSide = cross2(first, second, endPoint)
  let blend = firstSide / (firstSide - secondSide)
  return Point2(u: startPoint.u + blend * (endPoint.u - startPoint.u),
                v: startPoint.v + blend * (endPoint.v - startPoint.v))

proc clipPolygon(subject: seq[Point2], clipper: seq[Point2]): seq[Point2] =
  var current = subject
  for edgeIndex in 0 ..< clipper.len:
    let first = clipper[edgeIndex]
    let second = clipper[(edgeIndex + 1) mod clipper.len]
    var nextPass = newSeq[Point2](0)
    if current.len == 0:
      break
    var previous = current[current.len - 1]
    for point in current:
      if insideEdge(point, first, second):
        if not insideEdge(previous, first, second):
          nextPass.add edgeIntersection(previous, point, first, second)
        nextPass.add point
      elif insideEdge(previous, first, second):
        nextPass.add edgeIntersection(previous, point, first, second)
      previous = point
    current = nextPass
  return current

proc shadowOnTarget(source: Cube, target: Cube, bulb: Vec3): float64 =
  var totalArea = 0.0
  var center = Vec3(x: 0, y: 0, z: 0)
  for vertex in target.vertices:
    center = vecAdd(center, vertex)
  center = vecScale(center, 0.125)

  for axis in 0 .. 2:
    for side in 0 .. 1:
      let indices = faceIndices(axis, side)
      let facePoint = target.vertices[indices[0]]
      let edgeU = vecSub(target.vertices[indices[1]], facePoint)
      let edgeV = vecSub(target.vertices[indices[3]], facePoint)
      var normal = vecCross(edgeU, edgeV)
      if vecDot(normal, vecSub(facePoint, center)) < 0:
        normal = vecScale(normal, -1)
      if vecDot(normal, vecSub(bulb, facePoint)) <= 0:
        continue
      let lengthSquared = vecDot(edgeU, edgeU)
      let planeDistance = vecDot(normal, vecSub(bulb, facePoint))
      var facePolygon = newSeq[Point2](4)
      for cornerIndex in 0 .. 3:
        let offset = vecSub(target.vertices[indices[cornerIndex]], facePoint)
        facePolygon[cornerIndex] = Point2(u: vecDot(offset, edgeU) / lengthSquared,
                                          v: vecDot(offset, edgeV) / lengthSquared)
      if polygonArea(facePolygon) < 0:
        var reversedPolygon = newSeq[Point2](4)
        for cornerIndex in 0 .. 3:
          reversedPolygon[cornerIndex] = facePolygon[3 - cornerIndex]
        facePolygon = reversedPolygon

      var weights = newSeq[float64](8)
      for vertexIndex in 0 .. 7:
        weights[vertexIndex] = vecDot(normal, vecSub(source.vertices[vertexIndex],
                                                     facePoint)) / planeDistance
      var candidates = newSeq[Vec3](0)
      for vertexIndex in 0 .. 7:
        if weights[vertexIndex] >= 0 and weights[vertexIndex] < 1 - shadowEpsilon:
          candidates.add source.vertices[vertexIndex]
      let upperWeight = 1 - shadowEpsilon
      for edge in source.edges:
        let firstWeight = weights[edge[0]]
        let secondWeight = weights[edge[1]]
        for level in [0.0, upperWeight]:
          if (firstWeight < level and secondWeight >= level) or
             (secondWeight < level and firstWeight >= level):
            let blend = (level - firstWeight) / (secondWeight - firstWeight)
            candidates.add vecAdd(source.vertices[edge[0]],
                                  vecScale(vecSub(source.vertices[edge[1]],
                                                  source.vertices[edge[0]]), blend))
      if candidates.len < 3:
        continue
      var projections = newSeq[Point2](candidates.len)
      for candidateIndex in 0 ..< candidates.len:
        let candidate = candidates[candidateIndex]
        let weight = vecDot(normal, vecSub(candidate, facePoint)) / planeDistance
        let scale = 1.0 / (1.0 - weight)
        let projected = vecAdd(bulb, vecScale(vecSub(candidate, bulb), scale))
        let offset = vecSub(projected, facePoint)
        projections[candidateIndex] = Point2(u: vecDot(offset, edgeU) / lengthSquared,
                                             v: vecDot(offset, edgeV) / lengthSquared)
      let hullPoints = convexHull(projections)
      if hullPoints.len < 3:
        continue
      let clipped = clipPolygon(hullPoints, facePolygon)
      if clipped.len >= 3:
        totalArea += abs(polygonArea(clipped)) * lengthSquared
  return totalArea

proc formatArea(area: float64): string =
  let scaled = int64(area * 1000.0 + 0.5)
  let wholePart = scaled div 1000
  let fractionPart = scaled mod 1000
  var fractionText = $fractionPart
  while fractionText.len < 3:
    fractionText = "0" & fractionText
  return $wholePart & "." & fractionText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let bulb = Vec3(x: nextFloat(inputData, scanPos), y: nextFloat(inputData, scanPos),
                  z: nextFloat(inputData, scanPos))
  var firstVertices = newSeq[Vec3](4)
  for vertexIndex in 0 .. 3:
    firstVertices[vertexIndex] = Vec3(x: nextFloat(inputData, scanPos),
                                      y: nextFloat(inputData, scanPos),
                                      z: nextFloat(inputData, scanPos))
  var secondVertices = newSeq[Vec3](4)
  for vertexIndex in 0 .. 3:
    secondVertices[vertexIndex] = Vec3(x: nextFloat(inputData, scanPos),
                                       y: nextFloat(inputData, scanPos),
                                       z: nextFloat(inputData, scanPos))
  let firstCube = makeCube(firstVertices[0], vecSub(firstVertices[1], firstVertices[0]),
                           vecSub(firstVertices[2], firstVertices[0]),
                           vecSub(firstVertices[3], firstVertices[0]))
  let secondCube = makeCube(secondVertices[0], vecSub(secondVertices[1], secondVertices[0]),
                            vecSub(secondVertices[2], secondVertices[0]),
                            vecSub(secondVertices[3], secondVertices[0]))
  let shadowOnFirst = shadowOnTarget(secondCube, firstCube, bulb)
  let shadowOnSecond = shadowOnTarget(firstCube, secondCube, bulb)
  if shadowOnFirst < 1e-3 and shadowOnSecond < 1e-3:
    appendOutput("-1")
  elif shadowOnSecond >= shadowOnFirst:
    appendOutput("2 " & formatArea(shadowOnSecond))
  else:
    appendOutput("1 " & formatArea(shadowOnFirst))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
