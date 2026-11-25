# ALIENS — Aliens (SPOJ)
<https://www.spoj.com/problems/ALIENS/>

## Problem

Aliens want to abduct a whole crowd with one circular tractor beam and need the smallest possible beam.
The center of that beam is the spacecraft position above the ground.

The first line gives the case count. Each case gives n, then n lines with real x and y coordinates. Print the radius on one line, then the center coordinates on the next line. Round every number to two decimal places.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Cases c | up to 20 |
| Points n | 2 to 100000 |
| Coordinate range | -10000.0 to 10000.0 |
| Judge time | 1 s |
| Judge memory | 1536 MB |

The large point count rules out checking every triple of points.

The sample input and its expected output follow byte for byte.

```
1
6
8.000000 9.000000
4.000000 7.500000
1.000000 2.000000
5.100000 8.700000
9.000000 2.000000
4.500000 1.000000
```

```
5.00
5.00 5.00
```


## Idea

Grow a circle from random starting points, like stretching a rubber band around pegs until it encloses them all.
The program shuffles the points, then adds them one at a time. A point outside the current circle starts a new boundary, and nested passes repair the circle using two or three boundary points.
Expected work is linear because shuffling makes boundary updates rare. A direct search over all point triples costs O(n to the fourth) and cannot meet the limit.
Random order plus a three-point circle gives the answer in expected linear time.

## Why It Works

1. The smallest enclosing circle (smallest circle holding every point) is fixed by two diameter points or by three boundary points.
2. Shuffling the input gives each point a small chance of joining the final boundary, so total repair work is linear on average.
3. `circleFromThree` computes the circle through three points, or falls back to the widest diameter when they are collinear.
4. `contains` uses a tolerance, so a boundary point is never dropped by rounding.
5. `formatNumber` rewrites negative zero as `0.00`, which matches the judge text.

Four terms carry the proof.

| Term | Meaning |
| --- | --- |
| enclosing circle | smallest circle holding every point |
| diameter circle | circle whose diameter joins two points |
| boundary point | point at exactly the radius distance |
| tolerance | small slack used in containment tests |

They explain why three points are enough to fix the answer.

A script check of the sample uses six points and finds center (5,5) with radius squared 25.
The points (1,2), (9,2), and (8,9) each sit at distance 5 from that center.
The printed radius is 5.00 and the printed center is 5.00 5.00.

## Code

**Circle constructors.**
```nim
proc makeCircle(centerX, centerY, radiusSquared: float): Circle =
  result.centerX = centerX
  result.centerY = centerY
  result.radiusSquared = radiusSquared

proc contains(circle: Circle, pointX, pointY: float): bool =
  let dx = pointX - circle.centerX
  let dy = pointY - circle.centerY
  (dx * dx + dy * dy) <= circle.radiusSquared * (1.0 + 1e-12) + containmentEpsilon

proc circleFromDiameter(pointX1, pointY1, pointX2, pointY2: float): Circle =
  let centerX = (pointX1 + pointX2) / 2.0
  let centerY = (pointY1 + pointY2) / 2.0
  let dx = pointX1 - pointX2
  let dy = pointY1 - pointY2
  return makeCircle(centerX, centerY, (dx * dx + dy * dy) / 4.0)
```

`makeCircle` stores the center and squared radius. `contains` compares squared distance with the stored radius. `circleFromDiameter` centers on the midpoint of two points.

**Three-point circle.**
```nim
proc circleFromThree(pointX1, pointY1, pointX2, pointY2, pointX3, pointY3: float): Circle =
  let determinant = 2.0 * (pointX1 * (pointY2 - pointY3) +
                           pointX2 * (pointY3 - pointY1) +
                           pointX3 * (pointY1 - pointY2))
  if abs(determinant) > 1e-12:
    let square1 = pointX1 * pointX1 + pointY1 * pointY1
    let square2 = pointX2 * pointX2 + pointY2 * pointY2
    let square3 = pointX3 * pointX3 + pointY3 * pointY3
    let centerX = (square1 * (pointY2 - pointY3) +
                   square2 * (pointY3 - pointY1) +
                   square3 * (pointY1 - pointY2)) / determinant
    let centerY = (square1 * (pointX3 - pointX2) +
                   square2 * (pointX1 - pointX3) +
                   square3 * (pointX2 - pointX1)) / determinant
    let dx = pointX1 - centerX
    let dy = pointY1 - centerY
    return makeCircle(centerX, centerY, dx * dx + dy * dy)
  let distance12 = (pointX1 - pointX2) * (pointX1 - pointX2) +
                   (pointY1 - pointY2) * (pointY1 - pointY2)
  let distance13 = (pointX1 - pointX3) * (pointX1 - pointX3) +
                   (pointY1 - pointY3) * (pointY1 - pointY3)
  let distance23 = (pointX2 - pointX3) * (pointX2 - pointX3) +
                   (pointY2 - pointY3) * (pointY2 - pointY3)
  if distance12 >= distance13 and distance12 >= distance23:
    return circleFromDiameter(pointX1, pointY1, pointX2, pointY2)
  elif distance13 >= distance23:
    return circleFromDiameter(pointX1, pointY1, pointX3, pointY3)
  return circleFromDiameter(pointX2, pointY2, pointX3, pointY3)
```

The determinant checks whether the three points are collinear. A nonzero determinant gives the circumcenter directly. Collinear points fall back to the longest diameter.

**Seeded shuffle generator.**
```nim
var randomState: uint64 = 88172645463325252'u64

proc randomIndex(bound: int): int =
  randomState = randomState xor (randomState shl 13'u64)
  randomState = randomState xor (randomState shr 7'u64)
  randomState = randomState xor (randomState shl 17'u64)
  return int(randomState mod uint64(bound))
```

A fixed xorshift state makes runs reproducible. The index stays inside the remaining range. No random library call is needed.

**Incremental case loop.**
```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pointCount = nextInt(inputData, scanPos)
  var pointXs = newSeq[float](pointCount)
  var pointYs = newSeq[float](pointCount)
  for i in 0..<pointCount:
    pointXs[i] = nextDouble(inputData, scanPos)
    pointYs[i] = nextDouble(inputData, scanPos)
  var i = pointCount - 1
  while i > 0:
    let j = randomIndex(i + 1)
    swap pointXs[i], pointXs[j]
    swap pointYs[i], pointYs[j]
    i -= 1
  var enclosing = makeCircle(0.0, 0.0, -1.0)
  for i in 0..<pointCount:
    if not enclosing.contains(pointXs[i], pointYs[i]):
      enclosing = makeCircle(pointXs[i], pointYs[i], 0.0)
      for j in 0..<i:
        if not enclosing.contains(pointXs[j], pointYs[j]):
          enclosing = circleFromDiameter(pointXs[i], pointYs[i], pointXs[j], pointYs[j])
          for k in 0..<j:
            if not enclosing.contains(pointXs[k], pointYs[k]):
              enclosing = circleFromThree(pointXs[i], pointYs[i],
                                          pointXs[j], pointYs[j],
                                          pointXs[k], pointYs[k])
  appendOutput(formatNumber(sqrt(enclosing.radiusSquared)))
  outputBuffer.add '\n'
  appendOutput(formatNumber(enclosing.centerX))
  outputBuffer.add ' '
  appendOutput(formatNumber(enclosing.centerY))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop adds one point at a time. The nested loops repair the circle only for outside points. Two formatted lines are appended per case.


## Complexity

The shuffle keeps expected work linear even though the nested loops look cubic.

| Phase | Time | Space |
| --- | --- | --- |
| shuffle points | O(n) | two coordinate arrays |
| incremental repair | O(n) expected | constant |
| formatting | O(1) per case | one output block |

The three-point repair touches at most three points on each outer step.

Big O uses point count n.

| Measure | Big O |
| --- | --- |
| time | O(n) expected per case |
| space | O(n) |

A triple search over all point sets would cost O(n to the fourth).
