import math, algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const invalidCoordinate = 1e30
const degenerateEpsilon = 1e-12
const circleEpsilon = 1e-10
const tieEpsilon = 1e-7
const roundingEpsilon = 1e-7

type
  HolePoint = object
    x: float
    y: float
  Triangle = object
    first: int
    second: int
    third: int
  MeshEdge = object
    first: int
    second: int
  EnvelopeLine = object
    slope: float
    intercept: float
    startAt: float

var roomWidth = 0.0
var roomHeight = 0.0
var bestDistanceSquared = -1.0
var bestX = 0.0
var bestY = 0.0

proc nextInt(inputData: string, i: var int): int =
  let inputLength = inputData.len
  while i < inputLength:
    let currentChar = inputData[i]
    if currentChar >= '0' and currentChar <= '9':
      break
    inc i
  var parsedValue = 0
  while i < inputLength:
    let currentChar = inputData[i]
    if currentChar < '0' or currentChar > '9':
      break
    parsedValue = parsedValue * 10 + (ord(currentChar) - firstDigitValue)
    inc i
  return parsedValue

proc compareHoles(left, right: HolePoint): int =
  if left.x < right.x: return -1
  if left.x > right.x: return 1
  if left.y < right.y: return -1
  if left.y > right.y: return 1
  return 0

proc considerCandidate(candidateX, candidateY: float, holes: seq[HolePoint]) =
  var clampedX = candidateX
  var clampedY = candidateY
  if clampedX < 0.0: clampedX = 0.0
  if clampedX > roomWidth: clampedX = roomWidth
  if clampedY < 0.0: clampedY = 0.0
  if clampedY > roomHeight: clampedY = roomHeight
  var nearestSquared = invalidCoordinate
  for hole in holes:
    let deltaX = clampedX - hole.x
    let deltaY = clampedY - hole.y
    let distanceSquared = deltaX * deltaX + deltaY * deltaY
    if distanceSquared < nearestSquared:
      nearestSquared = distanceSquared
  let clearlyBetter = nearestSquared > bestDistanceSquared + tieEpsilon
  let nearlyTied = abs(nearestSquared - bestDistanceSquared) <= tieEpsilon
  let smallerX = clampedX < bestX - tieEpsilon
  let smallerY = clampedY < bestY - tieEpsilon
  let sameX = abs(clampedX - bestX) <= tieEpsilon
  let tieBroken = nearlyTied and (smallerX or (sameX and smallerY))
  if clearlyBetter or tieBroken:
    bestDistanceSquared = nearestSquared
    bestX = clampedX
    bestY = clampedY

proc circumCenter(first, second, third: HolePoint): (float, float) =
  let deltaX21 = second.x - first.x
  let deltaY21 = second.y - first.y
  let deltaX31 = third.x - first.x
  let deltaY31 = third.y - first.y
  let denominator = 2.0 * (deltaX21 * deltaY31 - deltaX31 * deltaY21)
  if abs(denominator) < degenerateEpsilon:
    return (invalidCoordinate, invalidCoordinate)
  let firstPower = second.x * second.x + second.y * second.y - first.x * first.x - first.y * first.y
  let secondPower = third.x * third.x + third.y * third.y - first.x * first.x - first.y * first.y
  let centerX = (firstPower * deltaY31 - secondPower * deltaY21) / denominator
  let centerY = (deltaX21 * secondPower - deltaX31 * firstPower) / denominator
  return (centerX, centerY)

proc insideCircumcircle(first, second, third, probe: HolePoint): bool =
  var orientedSecond = second
  var orientedThird = third
  let orientation = (orientedSecond.x - first.x) * (orientedThird.y - first.y) -
                    (orientedSecond.y - first.y) * (orientedThird.x - first.x)
  if orientation < 0.0:
    let swapX = orientedSecond.x
    orientedSecond.x = orientedThird.x
    orientedThird.x = swapX
    let swapY = orientedSecond.y
    orientedSecond.y = orientedThird.y
    orientedThird.y = swapY
  if abs(orientation) < degenerateEpsilon:
    return false
  let firstX = first.x - probe.x
  let firstY = first.y - probe.y
  let secondX = orientedSecond.x - probe.x
  let secondY = orientedSecond.y - probe.y
  let thirdX = orientedThird.x - probe.x
  let thirdY = orientedThird.y - probe.y
  let firstNorm = firstX * firstX + firstY * firstY
  let secondNorm = secondX * secondX + secondY * secondY
  let thirdNorm = thirdX * thirdX + thirdY * thirdY
  let determinant = firstNorm * (secondX * thirdY - secondY * thirdX) -
                    secondNorm * (firstX * thirdY - firstY * thirdX) +
                    thirdNorm * (firstX * secondY - firstY * secondX)
  return determinant > circleEpsilon

proc addMeshEdge(meshEdges: var seq[MeshEdge], endpointA, endpointB: int) =
  let edgeStart = min(endpointA, endpointB)
  let edgeEnd = max(endpointA, endpointB)
  for i in 0 ..< meshEdges.len:
    if meshEdges[i].first == edgeStart and meshEdges[i].second == edgeEnd:
      meshEdges.delete(i)
      return
  meshEdges.add(MeshEdge(first: edgeStart, second: edgeEnd))

proc buildTriangulation(holes: seq[HolePoint]): (seq[Triangle], seq[HolePoint]) =
  let pointCount = holes.len
  let minimumX = holes[0].x
  let maximumX = holes[pointCount - 1].x
  var minimumY = holes[0].y
  var maximumY = holes[0].y
  for hole in holes:
    if hole.y < minimumY: minimumY = hole.y
    if hole.y > maximumY: maximumY = hole.y
  let span = max(max(maximumX - minimumX, maximumY - minimumY), 1.0)
  let middleX = (minimumX + maximumX) / 2.0
  let middleY = (minimumY + maximumY) / 2.0
  var allPoints = holes
  allPoints.add(HolePoint(x: middleX - 20.0 * span, y: middleY - span))
  allPoints.add(HolePoint(x: middleX + 20.0 * span, y: middleY - span))
  allPoints.add(HolePoint(x: middleX, y: middleY + 20.0 * span))
  var triangles: seq[Triangle] = @[]
  triangles.add(Triangle(first: pointCount, second: pointCount + 1, third: pointCount + 2))
  for i in 0 ..< pointCount:
    let probe = allPoints[i]
    var meshEdges: seq[MeshEdge] = @[]
    var retained: seq[Triangle] = @[]
    for triangle in triangles:
      if insideCircumcircle(allPoints[triangle.first], allPoints[triangle.second], allPoints[triangle.third], probe):
        addMeshEdge(meshEdges, triangle.first, triangle.second)
        addMeshEdge(meshEdges, triangle.second, triangle.third)
        addMeshEdge(meshEdges, triangle.third, triangle.first)
      else:
        retained.add(triangle)
    triangles = retained
    for meshEdge in meshEdges:
      triangles.add(Triangle(first: meshEdge.first, second: meshEdge.second, third: i))
  var realTriangles: seq[Triangle] = @[]
  for triangle in triangles:
    if triangle.first < pointCount and triangle.second < pointCount and triangle.third < pointCount:
      realTriangles.add(triangle)
  return (realTriangles, allPoints)

proc compareLinesDescending(left, right: EnvelopeLine): int =
  if left.slope > right.slope: return -1
  if left.slope < right.slope: return 1
  return 0

proc envelopeBreakpoints(lines: seq[EnvelopeLine], lowBound, highBound: float): seq[float] =
  var reduced: seq[EnvelopeLine] = @[]
  for line in lines:
    var matching = false
    for i in 0 ..< reduced.len:
      if abs(reduced[i].slope - line.slope) < degenerateEpsilon:
        if line.intercept < reduced[i].intercept:
          reduced[i].intercept = line.intercept
        matching = true
        break
    if not matching:
      reduced.add(EnvelopeLine(slope: line.slope, intercept: line.intercept, startAt: -invalidCoordinate))
  reduced.sort(compareLinesDescending)
  var crossings: seq[float] = @[]
  if reduced.len == 0:
    return crossings
  var stack: seq[EnvelopeLine] = @[]
  for line in reduced:
    while stack.len > 0:
      let lastLine = stack[stack.len - 1]
      let slopeGap = line.slope - lastLine.slope
      if abs(slopeGap) < degenerateEpsilon:
        break
      let crossing = (lastLine.intercept - line.intercept) / slopeGap
      if crossing <= lastLine.startAt + degenerateEpsilon:
        stack.setLen(stack.len - 1)
      else:
        break
    if stack.len == 0:
      stack.add(EnvelopeLine(slope: line.slope, intercept: line.intercept, startAt: -invalidCoordinate))
    else:
      let lastLine = stack[stack.len - 1]
      let slopeGap = line.slope - lastLine.slope
      if abs(slopeGap) < degenerateEpsilon:
        if line.intercept < lastLine.intercept:
          stack[stack.len - 1].intercept = line.intercept
      else:
        let crossing = (lastLine.intercept - line.intercept) / slopeGap
        stack.add(EnvelopeLine(slope: line.slope, intercept: line.intercept, startAt: crossing))
  for i in 1 ..< stack.len:
    let crossing = stack[i].startAt
    if crossing > lowBound and crossing < highBound:
      crossings.add(crossing)
  return crossings

proc considerEdgeCandidates(edgeValue: float, verticalEdge: bool, holes: seq[HolePoint]) =
  var lines: seq[EnvelopeLine] = @[]
  for hole in holes:
    var lineSlope: float
    var lineIntercept: float
    if verticalEdge:
      let offset = edgeValue - hole.x
      lineSlope = -2.0 * hole.y
      lineIntercept = hole.y * hole.y + offset * offset
    else:
      let offset = edgeValue - hole.y
      lineSlope = -2.0 * hole.x
      lineIntercept = hole.x * hole.x + offset * offset
    lines.add(EnvelopeLine(slope: lineSlope, intercept: lineIntercept, startAt: -invalidCoordinate))
  let highBound = if verticalEdge: roomHeight else: roomWidth
  let crossings = envelopeBreakpoints(lines, 0.0, highBound)
  for crossing in crossings:
    if verticalEdge:
      considerCandidate(edgeValue, crossing, holes)
    else:
      considerCandidate(crossing, edgeValue, holes)

proc roundedTenths(value: float): int =
  let scaled = value * 10.0 + 0.5 + roundingEpsilon
  let rounded = int(floor(scaled))
  if rounded < 0: return 0
  return rounded

var inputData = ""
var inputLine: string = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let testCount = nextInt(inputData, i)
var outputBuffer = ""

for j in 0 ..< testCount:
  roomWidth = float(nextInt(inputData, i))
  roomHeight = float(nextInt(inputData, i))
  let holeCount = nextInt(inputData, i)
  var inputHoles: seq[HolePoint] = @[]
  for k in 0 ..< holeCount:
    let holeX = float(nextInt(inputData, i))
    let holeY = float(nextInt(inputData, i))
    inputHoles.add(HolePoint(x: holeX, y: holeY))
  inputHoles.sort(compareHoles)
  var holes: seq[HolePoint] = @[]
  for hole in inputHoles:
    if holes.len == 0 or compareHoles(holes[holes.len - 1], hole) != 0:
      holes.add(hole)

  bestDistanceSquared = -1.0
  considerCandidate(0.0, 0.0, holes)
  considerCandidate(roomWidth, 0.0, holes)
  considerCandidate(0.0, roomHeight, holes)
  considerCandidate(roomWidth, roomHeight, holes)

  let triangulation = buildTriangulation(holes)
  let triangles = triangulation[0]
  let allPoints = triangulation[1]
  for triangle in triangles:
    let center = circumCenter(allPoints[triangle.first], allPoints[triangle.second], allPoints[triangle.third])
    if center[0] >= 0.0 and center[0] <= roomWidth and center[1] >= 0.0 and center[1] <= roomHeight:
      considerCandidate(center[0], center[1], holes)

  considerEdgeCandidates(0.0, true, holes)
  considerEdgeCandidates(roomWidth, true, holes)
  considerEdgeCandidates(0.0, false, holes)
  considerEdgeCandidates(roomHeight, false, holes)

  let outputX = roundedTenths(bestX)
  let outputY = roundedTenths(bestY)
  let wholeX = $(outputX div 10)
  let fractionX = $(outputX mod 10)
  let wholeY = $(outputY div 10)
  let fractionY = $(outputY mod 10)
  outputBuffer.add "The safest point is ("
  outputBuffer.add wholeX
  outputBuffer.add '.'
  outputBuffer.add fractionX
  outputBuffer.add ", "
  outputBuffer.add wholeY
  outputBuffer.add '.'
  outputBuffer.add fractionY
  outputBuffer.add ").\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
