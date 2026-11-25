# ECLIPSE — Eclipse (SPOJ)

<https://www.spoj.com/problems/ECLIPSE/>

## Problem

Given a star and two spheres in space, decide what kind of solar eclipse the first body casts on the second. The answer ranges from no eclipse through partial and total, with an extra flag telling whether the whole target is covered.

Input consists of consecutive groups of three lines, each line holding `x y z r` for one body. The first line is the star, the second is the occluding body, and the third is the target. A line containing `-1` ends the input. Output one classification per test case.

| item | bound |
|---|---|
| radius r | 1 to 1000000 |
| centre coordinates | 0 to 1000000000 |
| test cases | until the `-1` sentinel |
| judge limit | 30000 ms, 1536 MB |

The radii and coordinates drive the geometry; a two-body separation guarantee keeps boundaries stable.

Sample input:

```
0 0 0 700
49900 1000 149700 2
50000 1000 150000 7
0 0 0 10
50 0 100 40
60 0 200 1
-1
```

Sample output:

```
Part total solar eclipse
Entire total solar eclipse
```

## Idea

Picture a flashlight shining past a ball onto a second ball, like a hand making a shadow puppet. The dark core is a cone that narrows to a point, and the fuzzy outer cone widens forever. We compare the target sphere with each cone by measuring the perpendicular distance from its centre to the cone surface.

The algorithm builds the two shadow cones from the homothety centres of the star and occluder. It then uses point-to-line distance in the meridian plane to test whether the target sphere lies entirely inside a cone or only touches it.

A dense ray trace over many surface points would be slow and approximate; the distance test is exact and constant time.

## Why It Works

1. The star-to-occluder axis gives an axial coordinate `t` and a sideways distance `r` for the target centre.
2. The penumbra boundary uses the internal homothety centre and has radius `moonRadius + t * (rs + ra) / d`.
3. The umbra boundary uses the external homothety centre; it narrows when `rs > ra` and widens otherwise.
4. In the meridian plane the cone surface is a line, so the signed distance from a point to that line is easy to compute.
5. A sphere lies entirely inside a cone when that distance is at least its radius; it touches when the distance exceeds minus its radius.

| term | meaning |
|---|---|
| `axialPosition` | target centre distance behind the occluder along the axis |
| `sidewaysDistance` | target centre distance from the shadow axis |
| `penumbraDistance` | signed distance to the penumbra surface |
| `umbraDistance` | signed distance to the umbra surface |
| `umbraApex` | point where the umbra narrows to zero, when it exists |

For the first sample case, the umbra radius near Earth is about 0.6, smaller than the target radius 7. The sphere crosses the umbra surface, so the answer is a part total eclipse.

## Code

**Input and vector tools.** The scanner reads signed integers, and simple helpers build the shadow axis.

```nim
import math

const flushBlockBytes = 1 shl 17
const geometryEpsilon = 1e-9
const farDistanceValue = 1e30

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

type Point3 = tuple[xPos: float, yPos: float, zPos: float]

proc subtractPoints(firstPoint, secondPoint: Point3): Point3 =
  return (xPos: firstPoint.xPos - secondPoint.xPos,
          yPos: firstPoint.yPos - secondPoint.yPos,
          zPos: firstPoint.zPos - secondPoint.zPos)

proc dotProduct(firstPoint, secondPoint: Point3): float =
  return firstPoint.xPos * secondPoint.xPos +
         firstPoint.yPos * secondPoint.yPos +
         firstPoint.zPos * secondPoint.zPos

proc vectorLength(vectorValue: Point3): float =
  return sqrt(dotProduct(vectorValue, vectorValue))

proc scaleVector(vectorValue: Point3, factor: float): Point3 =
  return (xPos: vectorValue.xPos * factor,
          yPos: vectorValue.yPos * factor,
          zPos: vectorValue.zPos * factor)
```

The minus branch recognizes the `-1` sentinel.
Coordinates fit in double precision exactly.
Vector helpers keep the cone formulas short.

**Cone classification.** The two cone distances decide all five verdicts.

```nim
proc classifyEclipse(starCenter: Point3, starRadius: float,
                     moonCenter: Point3, moonRadius: float,
                     planetCenter: Point3, planetRadius: float): string =
  let axisVector = subtractPoints(moonCenter, starCenter)
  let centerDistance = vectorLength(axisVector)
  let axisUnit = scaleVector(axisVector, 1.0 / centerDistance)
  let moonToPlanet = subtractPoints(planetCenter, moonCenter)
  let axialPosition = dotProduct(moonToPlanet, axisUnit)
  let sidewaysVector = subtractPoints(moonToPlanet, scaleVector(axisUnit, axialPosition))
  let sidewaysDistance = vectorLength(sidewaysVector)

  let penumbraSlope = (starRadius + moonRadius) / centerDistance
  let penumbraRadius = moonRadius + axialPosition * penumbraSlope
  let penumbraInner = penumbraRadius - sidewaysDistance
  let penumbraDistance = penumbraInner / sqrt(1.0 + penumbraSlope * penumbraSlope)

  var umbraSlope: float = 0.0
  var umbraRadius: float = 0.0
  var umbraApex = farDistanceValue
  if starRadius > moonRadius:
    umbraSlope = -(starRadius - moonRadius) / centerDistance
    umbraApex = moonRadius * centerDistance / (starRadius - moonRadius)
    umbraRadius = moonRadius + umbraSlope * axialPosition
  else:
    umbraSlope = (moonRadius - starRadius) / centerDistance
    umbraRadius = moonRadius + umbraSlope * axialPosition
  let umbraInner = umbraRadius - sidewaysDistance
  let umbraDistance = umbraInner / sqrt(1.0 + umbraSlope * umbraSlope)

  let behindMoon = axialPosition + planetRadius > geometryEpsilon
  let clearOfMoon = axialPosition - planetRadius > -geometryEpsilon
  var beforeApexForEntire = true
  var beforeApexForIntersection = true
  if umbraApex < 1e29:
    if axialPosition + planetRadius > umbraApex + geometryEpsilon:
      beforeApexForEntire = false
    if axialPosition - planetRadius >= umbraApex + geometryEpsilon:
      beforeApexForIntersection = false

  if behindMoon and clearOfMoon and beforeApexForEntire and umbraDistance >= planetRadius - geometryEpsilon:
    return "Entire total solar eclipse"
  if behindMoon and beforeApexForIntersection and umbraDistance > -planetRadius - geometryEpsilon:
    return "Part total solar eclipse"
  if behindMoon and clearOfMoon and penumbraDistance >= planetRadius - geometryEpsilon:
    return "Entire partial solar eclipse"
  if behindMoon and penumbraDistance > -planetRadius - geometryEpsilon:
    return "Part partial solar eclipse"
  return "No solar eclipse"
```

The penumbra radius includes the occluder radius at its mouth.
The umbra apex check is stricter for an entire eclipse.
A total verdict wins over a partial verdict when both are possible.

**Driver.** Each group of three lines produces one line of output.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let firstValue = nextInt(inputData, scanPos)
  if firstValue == -1:
    break
  let secondValue = nextInt(inputData, scanPos)
  let thirdValue = nextInt(inputData, scanPos)
  let fourthValue = nextInt(inputData, scanPos)
  let fifthValue = nextInt(inputData, scanPos)
  let sixthValue = nextInt(inputData, scanPos)
  let seventhValue = nextInt(inputData, scanPos)
  let eighthValue = nextInt(inputData, scanPos)
  let ninthValue = nextInt(inputData, scanPos)
  let tenthValue = nextInt(inputData, scanPos)
  let eleventhValue = nextInt(inputData, scanPos)
  let twelfthValue = nextInt(inputData, scanPos)
  let starCenter: Point3 = (xPos: float(firstValue), yPos: float(secondValue), zPos: float(thirdValue))
  let moonCenter: Point3 = (xPos: float(fifthValue), yPos: float(sixthValue), zPos: float(seventhValue))
  let planetCenter: Point3 = (xPos: float(ninthValue), yPos: float(tenthValue), zPos: float(eleventhValue))
  let verdict = classifyEclipse(starCenter, float(fourthValue),
                                moonCenter, float(eighthValue),
                                planetCenter, float(twelfthValue))
  appendOutput(verdict)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops at the sentinel.
Twelve integers describe each case.
Verdicts collect in one output buffer.

## Complexity

Each test case uses a constant amount of arithmetic.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| cone construction | a few vector operations | fixed-size vectors |
| classification | two distance tests | block buffer |

The number of test cases is the only scaling factor.

| measure | Big O |
|---|---|
| time | O(1) per test case |
| space | O(1) beyond the input buffer |

A sampled ray trace would spend many steps per case and still approximate the boundary.
