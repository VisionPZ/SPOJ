# BICYCLE — Bicycle (SPOJ)
<https://www.spoj.com/problems/BICYCLE/>

## Problem

Each case gives two circular lanes and a start point and target point lying on them. Find the shortest distance along the lanes between the points, or -1 if no route exists.

Input begins with a case count t. Each case gives two circles as center x, center y, radius, then the home point and the school point as floating pairs. Output one distance per case with ten decimals, or -1.

The limits fix the geometry size:

| Quantity | Bound |
| --- | --- |
| Test cases t | at most 100 |
| Center coordinates | -200 to 200 |
| Radii | 0 to 200 |
| Point error | within 10^-8 of a lane |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The graph holds at most four nodes, so each case stays tiny.

The sample input and output:

```
3

0 0 5
4 0 3
3.0 4.0
1.878679656440357 -2.121320343559643

0 0 5
4 0 3
4.0 3.0
4.0 -3.0

0 0 4
10 0 4
4.0 0.0
6.0 0.0
```

```
8.4875540166
6.4350110879
-1
```

The third case has no crossing, so it prints -1.

## Idea

Treat the two circles as a tiny graph: start, target, and circle crossings are the nodes, and circle arcs are the edges. The shortest ride is then a shortest path on at most four nodes. The program builds this graph and runs Floyd-Warshall (an all-pairs shortest path method). Crossings are the only places to switch lanes, so no other point can improve the route.

Each case costs constant time: at most four nodes, six edges, and one 4 by 4 relaxation. Sampling many angles on each circle would only approximate the distance and still miss an exact crossing. The graph gives the exact answer in fixed work.

Takeaway: turn a geometry question into a four-node graph.

## Why It Works

1. A crossing lies on both circles, so a rider can switch lanes there.
2. Any route leaves a circle only at a crossing and returns at a crossing.
3. The graph keeps home, school, and every crossing, so it holds an optimal route.
4. Coincident circles share all points, so one direct arc gives the answer.
5. Floyd-Warshall relaxes every triple, so it finds the shortest path for all node pairs.

The arc formula uses the two radius vectors from a circle center.

| Term | Meaning |
| --- | --- |
| cross | deltaFirstX times deltaSecondY minus deltaFirstY times deltaSecondX |
| dot | deltaFirstX times deltaSecondX plus deltaFirstY times deltaSecondY |
| arc | radius times atan2 of the absolute cross and the dot |
| along | (d squared + r1 squared - r2 squared) divided by 2d |
| height | square root of (r1 squared - along squared) |

The first three rows build an arc; the last two locate the crossings.

A script traced the first sample case:

| Quantity | Value |
| --- | --- |
| Crossings | (4, 3) and (4, -3) |
| Arc from home (3, 4) to (4, 3) | 1.4189705460 |
| Arc from (4, 3) to school | 7.0685834706 |
| Total shortest ride | 8.4875540166 |

The two arcs add to the printed answer.

## Code

**Constants and input scanner.**
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
```
The buffer collects every line, and the scanner skips non-digits before each integer. The sign branch keeps negative centers correct. Parsing costs one pass over the input bytes.

**Float reader and output helper.**
```nim
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
```
`nextFloat` reads one whitespace-delimited token and converts it with `parseFloat`. `appendOutput` flushes after flushBlockBytes bytes, so writes stay in large blocks.

**Arc length.**
```nim
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
The helper takes one circle and two points on it. `arctan2` of the absolute cross product and the dot product returns the smaller central angle. Radius times that angle is the arc length.

**Circle geometry per case.**
```nim
let caseCount = nextInt(inputData, scanPos)

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
The program reads both circles and both points. Errors to each circle decide which lane holds home and school. The intersection formula gives zero, one, or two crossings, with a separate branch for coincident circles.

**Graph and shortest path.**
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
Each node records which circles contain it. Arcs fill a 4 by 4 grid, and three nested loops relax every path. The final value becomes -1 when it stays above half of unreachableDistance.

## Complexity

Each phase does fixed work per case.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Circle geometry | O(1) | O(1) |
| Arc grid | at most six arcs | O(1) |
| Floyd-Warshall | 4 cubed relaxations | O(1) |
| Output | one buffered write per block | flushBlockBytes |

Every phase is constant in the problem size.

| Measure | Big O |
| --- | --- |
| Time per case | O(1) |
| Total time | O(input bytes + t) |
| Space | O(input bytes) |

An angle-sampling search would test many points per circle and still return an approximation, while this graph returns the exact route in fixed time.
