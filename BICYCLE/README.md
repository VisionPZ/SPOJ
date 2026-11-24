## Problem

Read two circular bicycle lanes and a home point plus a school point on the lanes. Print the shortest travel distance along the lanes, or -1 when no route exists. Both points lie on one of the circles to high accuracy.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 100 |
| Center coordinates | -200 to 200 |
| Radii | 0 to 200 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The small case count keeps exact geometry cheap.

## Idea

Build a graph of at most four points: home, school, and the one or two lane crossings. Join two points on the same circle by the shorter arc between them, then find the shortest route with Floyd-Warshall. Crossings are the only places to change lanes, so every useful route stays inside this graph. A dense angle sweep would sample many points per circle and still give an approximate answer.

Cost per case is constant: at most four nodes, six edges, and one 4 by 4 relaxation.

## Why It Works

A crossing belongs to both circles, so it can hand a traveler from one lane to the other. Any route that leaves a circle does so at a crossing and returns at a crossing. The graph keeps home, school, and every crossing, so it contains an optimal route.

The distance along one circle comes from the two radius vectors. For points first and second on the circle:

cross = deltaFirstX * deltaSecondY minus deltaFirstY * deltaSecondX
dot = deltaFirstX * deltaSecondX plus deltaFirstY * deltaSecondY
arc = radius times atan2 of the absolute cross product and the dot product

The crossing points come from the center distance d and the radii:

along = (d squared + r1 squared minus r2 squared) divided by 2d
height = square root of (r1 squared minus along squared)

Coincident circles need no crossing, and the arc between the two points is the answer there.

Worked example, generated from the first sample case:

crossings: (4,3) and (4,-3)
arc home to (4,3): 1.4189705460
arc (4,3) to school: 7.0685834706
route via (4,3): 8.4875540166
route via (4,-3): 10.2101761242
answer: 8.4875540166

The crossing near both points gives the smaller route.

## Code

The program reads all input into one buffer, scans tokens by position, and flushes one output buffer in blocks.

```nim
import strutils, math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const geometryEpsilon = 1e-7
const unreachableDistance = 1e100

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  let dataLength = data.len
  while pos < dataLength and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < dataLength and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < dataLength and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

proc nextFloat(data: string, pos: var int): float =
  let dataLength = data.len
  while pos < dataLength and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < dataLength and data[pos] > ' ':
    pos += 1
  return parseFloat(data[startPos .. pos - 1])

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc arcLength(centerX: float, centerY: float, radius: float,
               firstX: float, firstY: float,
               secondX: float, secondY: float): float =
  let deltaFirstX = firstX - centerX
  let deltaFirstY = firstY - centerY
  let deltaSecondX = secondX - centerX
  let deltaSecondY = secondY - centerY
  let crossProduct = deltaFirstX * deltaSecondY - deltaFirstY * deltaSecondX
  let dotProduct = deltaFirstX * deltaSecondX + deltaFirstY * deltaSecondY
  let crossMagnitude = if crossProduct == 0.0: 0.0 else: abs(crossProduct)
  return radius * arctan2(crossMagnitude, dotProduct)
```

The sign branch in `nextInt` keeps negative center coordinates. The `crossMagnitude` line turns negative zero into positive zero, which avoids a negative angle. Each arc computation costs a handful of floating point operations.

Each case reads its six lane integers and four point coordinates. The smaller circle error decides which lane holds a point.

```nim
for i in 0..<caseCount:
  let centerOneX = nextInt(inputData, scanPos)
  let centerOneY = nextInt(inputData, scanPos)
  let radiusOne = nextInt(inputData, scanPos)
  let centerTwoX = nextInt(inputData, scanPos)
  let centerTwoY = nextInt(inputData, scanPos)
  let radiusTwo = nextInt(inputData, scanPos)
  let homeX = nextFloat(inputData, scanPos)
  let homeY = nextFloat(inputData, scanPos)
  let schoolX = nextFloat(inputData, scanPos)
  let schoolY = nextFloat(inputData, scanPos)

  let firstCenterX = float(centerOneX)
  let firstCenterY = float(centerOneY)
  let secondCenterX = float(centerTwoX)
  let secondCenterY = float(centerTwoY)
  let firstRadius = float(radiusOne)
  let secondRadius = float(radiusTwo)

  let firstHomeError = abs(sqrt((homeX - firstCenterX) * (homeX - firstCenterX) +
                                (homeY - firstCenterY) * (homeY - firstCenterY)) - firstRadius)
  let secondHomeError = abs(sqrt((homeX - secondCenterX) * (homeX - secondCenterX) +
                                 (homeY - secondCenterY) * (homeY - secondCenterY)) - secondRadius)
  let homeCircle = if firstHomeError <= secondHomeError: 1 else: 2
  let firstSchoolError = abs(sqrt((schoolX - firstCenterX) * (schoolX - firstCenterX) +
                                  (schoolY - firstCenterY) * (schoolY - firstCenterY)) - firstRadius)
  let secondSchoolError = abs(sqrt((schoolX - secondCenterX) * (schoolX - secondCenterX) +
                                   (schoolY - secondCenterY) * (schoolY - secondCenterY)) - secondRadius)
  let schoolCircle = if firstSchoolError <= secondSchoolError: 1 else: 2

  let centerDeltaX = secondCenterX - firstCenterX
  let centerDeltaY = secondCenterY - firstCenterY
  let centerDistance = sqrt(centerDeltaX * centerDeltaX + centerDeltaY * centerDeltaY)
  let radiusSum = firstRadius + secondRadius
  let radiusDifference = abs(firstRadius - secondRadius)

  var coincident = false
  var intersectionCount = 0
  var intersectionX: array[2, float]
  var intersectionY: array[2, float]

  if centerDistance < geometryEpsilon and abs(firstRadius - secondRadius) < geometryEpsilon:
    coincident = true
  elif centerDistance > radiusSum + geometryEpsilon or
       centerDistance < radiusDifference - geometryEpsilon:
    intersectionCount = 0
  elif centerDistance >= geometryEpsilon:
    let unitX = centerDeltaX / centerDistance
    let unitY = centerDeltaY / centerDistance
    let alongDistance = (centerDistance * centerDistance + firstRadius * firstRadius -
                         secondRadius * secondRadius) / (2.0 * centerDistance)
    let heightSquared = firstRadius * firstRadius - alongDistance * alongDistance
    if heightSquared >= -geometryEpsilon:
      let crossHeight = sqrt(max(0.0, heightSquared))
      let baseX = firstCenterX + alongDistance * unitX
      let baseY = firstCenterY + alongDistance * unitY
      intersectionX[0] = baseX - crossHeight * unitY
      intersectionY[0] = baseY + crossHeight * unitX
      if crossHeight < geometryEpsilon:
        intersectionCount = 1
      else:
        intersectionX[1] = baseX + crossHeight * unitY
        intersectionY[1] = baseY - crossHeight * unitX
        intersectionCount = 2
```

The loop runs once per test case. The `geometryEpsilon` test avoids division by zero for equal centers. Tangent circles produce one crossing, and separate circles produce none.

The graph uses `distanceGrid` over `nodeCount` nodes, then relaxes every triple.

```nim
  var answer: float
  if coincident:
    answer = arcLength(firstCenterX, firstCenterY, firstRadius,
                       homeX, homeY, schoolX, schoolY)
  else:
    let nodeCount = 2 + intersectionCount
    var nodeX: array[4, float]
    var nodeY: array[4, float]
    var onFirst: array[4, bool]
    var onSecond: array[4, bool]
    nodeX[0] = homeX
    nodeY[0] = homeY
    nodeX[1] = schoolX
    nodeY[1] = schoolY
    onFirst[0] = homeCircle == 1
    onSecond[0] = homeCircle == 2
    onFirst[1] = schoolCircle == 1
    onSecond[1] = schoolCircle == 2
    for j in 0..<intersectionCount:
      nodeX[j + 2] = intersectionX[j]
      nodeY[j + 2] = intersectionY[j]
      onFirst[j + 2] = true
      onSecond[j + 2] = true

    var distanceGrid: array[4, array[4, float]]
    for j in 0..<nodeCount:
      for l in 0..<nodeCount:
        distanceGrid[j][l] = if j == l: 0.0 else: unreachableDistance

    for circleNumber in 1..2:
      let circleCenterX = if circleNumber == 1: firstCenterX else: secondCenterX
      let circleCenterY = if circleNumber == 1: firstCenterY else: secondCenterY
      let circleRadius = if circleNumber == 1: firstRadius else: secondRadius
      for j in 0..<nodeCount:
        let belongsFirst = circleNumber == 1 and onFirst[j]
        let belongsSecond = circleNumber == 2 and onSecond[j]
        if not belongsFirst and not belongsSecond:
          continue
        for l in j + 1..<nodeCount:
          let otherFirst = circleNumber == 1 and onFirst[l]
          let otherSecond = circleNumber == 2 and onSecond[l]
          if not otherFirst and not otherSecond:
            continue
          let segment = arcLength(circleCenterX, circleCenterY, circleRadius,
                                  nodeX[j], nodeY[j], nodeX[l], nodeY[l])
          if segment < distanceGrid[j][l]:
            distanceGrid[j][l] = segment
            distanceGrid[l][j] = segment

    for k in 0..<nodeCount:
      for j in 0..<nodeCount:
        for l in 0..<nodeCount:
          let throughDistance = distanceGrid[j][k] + distanceGrid[k][l]
          if throughDistance < distanceGrid[j][l]:
            distanceGrid[j][l] = throughDistance

    answer = distanceGrid[0][1]

  if answer >= unreachableDistance * 0.5:
    appendOutput("-1")
  else:
    appendOutput(formatFloat(answer, ffDecimal, 10))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loops cover both circles and every pair of nodes on each circle. The `unreachableDistance` marker keeps missing edges from changing a route. The final flush writes the buffered answers once.

## Complexity

Input scanning costs one pass over the input bytes. Each case takes constant work: one intersection computation and Floyd-Warshall on at most four nodes. Output costs one pass over the answer bytes.

Total time is O(t) for t cases, and total space is O(t) for the two buffers. Per-case space is O(1). A dense angle sweep would spend O(S) per case for S samples per circle and would still return an approximate answer.
