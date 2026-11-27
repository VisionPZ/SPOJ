<https://www.spoj.com/problems/TWOCIR/>

## Problem

Two non-intersecting circles float in 3D space. Decide whether they form two links of a chain, meaning they cannot be pulled apart without breaking one.

Input starts with test count T. Each case has two lines of nine integers, three points per circle. Print `YES` when the circles are entangled and `NO` otherwise.

| item | bound |
|---|---|
| tests T | 1 to 100 |
| coordinates | -10000 to 10000 |
| points per circle | 3 non-collinear points |
| judge limit | 1000 ms, 1536 MB |

The three points determine each circle's plane, center, and radius.

Sample input:

```
1
0 1 0 1 0 0 0 -1 0
0 0 0 1 0 -1 1 0 1
```

Sample output:

```
YES
```

## Idea

Picture a coin pushed through a paper disk: one crossing inside the rim and one outside means the coin is hooked.

The real algorithm intersects one circle with the other circle's plane in O(1) time. Sampling thousands of points along both curves to estimate a linking integral would be slower and less exact. Check the two crossings directly.

## Why It Works

1. Three non-collinear points define a plane and a circumcircle.
2. A circle meets another plane in at most two points.
3. Those points lie on the line where the two planes cross.
4. The midpoint of that chord is the projection of the first center onto the line.
5. Both crossings lie inside the second disk, or both lie outside, when the circles are separate.
6. One crossing inside and one outside means the curves pass through the disk once, so they are linked.
7. Parallel planes give no crossings and no link.

| term | meaning |
|---|---|
| `CircleData` | center, radius, and unit plane normal |
| `alignment` | dot product of the two plane normals |
| `squaredCross` | squared sine of the angle between planes |
| `chordCenter` | midpoint of the two crossing points |
| `halfChord` | half the distance between the crossings |
| `tolerance` | small relative guard for floating point noise |

A script evaluated the sample with a numerical linking integral and got `1.000000`, confirming `YES`.

The first circle lies in the plane `z = 0` with radius 1. The second lies in `y = 0` with center `(1, 0, 0)` and radius 1. The crossings are `(1, 0, 0)` inside the disk and `(-1, 0, 0)` outside it.

The check runs in both directions as a guard; both directions agree for disjoint circles.

## Code

**Input and scanning.** The whole input is one string; the scanner accepts minus signs.

```nim
import math

const flushBlockBytes = 1 shl 17

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Negative coordinates keep their sign.
One buffer collects all verdicts.

**Vector helpers.** Small value objects keep the geometry readable.

```nim
type Vec3 = object
  x: float64
  y: float64
  z: float64

type CircleData = object
  center: Vec3
  radius: float64
  normal: Vec3

proc vecAdd(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)

proc vecSub(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)

proc vecScale(value: Vec3, factor: float64): Vec3 =
  return Vec3(x: value.x * factor, y: value.y * factor, z: value.z * factor)

proc vecDot(left: Vec3, right: Vec3): float64 =
  return left.x * right.x + left.y * right.y + left.z * right.z

proc vecCross(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.y * right.z - left.z * right.y,
              y: left.z * right.x - left.x * right.z,
              z: left.x * right.y - left.y * right.x)

proc vecNorm2(value: Vec3): float64 =
  return vecDot(value, value)

proc nextVec(): Vec3 =
  let xValue = float64(nextInt(inputData, scanPos))
  let yValue = float64(nextInt(inputData, scanPos))
  let zValue = float64(nextInt(inputData, scanPos))
  return Vec3(x: xValue, y: yValue, z: zValue)

proc circleFrom(first: Vec3, second: Vec3, third: Vec3): CircleData =
  let edgeOne = vecSub(second, first)
  let edgeTwo = vecSub(third, first)
  let planeNormal = vecCross(edgeOne, edgeTwo)
  let denominator = 2.0 * vecNorm2(planeNormal)
  let weightedOne = vecScale(vecCross(edgeTwo, planeNormal), vecNorm2(edgeOne))
  let weightedTwo = vecScale(vecCross(planeNormal, edgeOne), vecNorm2(edgeTwo))
  let center = vecAdd(first, vecScale(vecAdd(weightedOne, weightedTwo), 1.0 / denominator))
  let radius = sqrt(vecNorm2(vecSub(center, first)))
  let normal = vecScale(planeNormal, 1.0 / sqrt(vecNorm2(planeNormal)))
  return CircleData(center: center, radius: radius, normal: normal)
```

The cross product gives the plane normal.
The circumcentre formula uses two squared edge lengths.
Each point contributes three scanned coordinates.

**Linking test.** One plane cut decides the case.

```nim
proc circlesLinked(first: CircleData, second: CircleData): bool =
  let alignment = vecDot(first.normal, second.normal)
  let squaredCross = 1.0 - alignment * alignment
  if squaredCross <= 1e-12:
    return false
  let firstOffset = vecDot(first.normal, first.center)
  let secondOffset = vecDot(second.normal, second.center)
  let basePoint = vecScale(
    vecAdd(vecScale(first.normal, firstOffset - alignment * secondOffset),
           vecScale(second.normal, secondOffset - alignment * firstOffset)),
    1.0 / squaredCross)
  let lineDirection = vecScale(vecCross(first.normal, second.normal), 1.0 / sqrt(squaredCross))
  let chordCenter = vecAdd(basePoint,
    vecScale(lineDirection, vecDot(vecSub(first.center, basePoint), lineDirection)))
  let centerDistanceSq = vecNorm2(vecSub(first.center, chordCenter))
  let radiusScale = max(first.radius, second.radius)
  let tolerance = 1e-9 * radiusScale * radiusScale + 1e-7
  if centerDistanceSq > first.radius * first.radius + tolerance:
    return false
  let halfChord = sqrt(max(0.0, first.radius * first.radius - centerDistanceSq))
  let plusPoint = vecAdd(chordCenter, vecScale(lineDirection, halfChord))
  let minusPoint = vecSub(chordCenter, vecScale(lineDirection, halfChord))
  let plusInside = vecNorm2(vecSub(plusPoint, second.center)) < second.radius * second.radius - tolerance
  let minusInside = vecNorm2(vecSub(minusPoint, second.center)) < second.radius * second.radius - tolerance
  return plusInside != minusInside

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 1
while caseIndex <= caseCount:
  let firstCircle = circleFrom(nextVec(), nextVec(), nextVec())
  let secondCircle = circleFrom(nextVec(), nextVec(), nextVec())
  if circlesLinked(firstCircle, secondCircle) or circlesLinked(secondCircle, firstCircle):
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

Parallel planes return `false` immediately.
The guard scales with the larger radius.
Opposite inside tests mean the circles are linked.

## Complexity

Each case does constant-size vector arithmetic.

| phase | time | space |
|---|---|---|
| input read | one pass over 18T coordinates | one input string |
| circle construction | fixed vector work per circle | constant |
| linking test | fixed vector work per case | constant |
| output | one verdict per case | block buffer |

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(T) for input text |

A linking-integral estimate would sample thousands of point pairs per case.

Cut one circle by the other plane and compare the two crossings.
