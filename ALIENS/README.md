## Problem

Read a count of test cases. Each case gives n points with real x and y coordinates. Print the radius of the smallest circle that contains every point, then print the circle center. Each number uses two decimal places.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 20 |
| Points per case | 2 to 100000 |
| Coordinate value | -10000.0 to 10000.0 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The point count sets the design, and reading the points costs most of the run.

## Idea

Build the smallest enclosing circle one point at a time in random order. When a point lies outside the current circle, start a new circle at that point and recheck the earlier points. A second outside point fixes a diameter, and a third fixes a circumcircle.

Cost per point: expected O(1) work, so O(n) per case.

## Why It Works

A smallest enclosing circle has at most three points on its boundary. Two boundary points give the circle whose diameter joins them. Three boundary points give the circumcircle of their triangle. Random order keeps the number of rebuilds small, so the three nested loops do expected linear work.

The circle stores a squared radius. A distance test compares squared distance against that value, so no square root appears inside the loops.

| Term | Meaning |
| --- | --- |
| `radiusSquared` | squared radius, used by every containment test |
| `determinant` | twice the signed triangle area, zero for collinear points |
| `containmentEpsilon` | slack that absorbs rounding in the distance test |

The worked example below comes from `gen.py` with the sample points. The center is (5, 5) and the radius is 5.00.

| Point | Distance from center |
| --- | --- |
| (8, 9) | 5.0000 |
| (4, 7.5) | 2.6926 |
| (1, 2) | 5.0000 |
| (5.1, 8.7) | 3.7014 |
| (9, 2) | 5.0000 |
| (4.5, 1) | 4.0311 |

Three points reach distance 5.0000, so no smaller circle can hold them.

## Code

The whole input stream lands in one string before any parsing starts.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

One pass yields each integer and each coordinate, with the sign handled before the digits.

```nim
proc nextDouble(data: string, position: var int): float =
  while position < data.len and (data[position] == ' ' or data[position] == '\n' or
      data[position] == '\t' or data[position] == '\r'):
    position += 1
  var sign = 1.0
  if position < data.len and data[position] == '-':
    sign = -1.0
    position += 1
  elif position < data.len and data[position] == '+':
    position += 1
  var whole = 0.0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    whole = whole * 10.0 + float(int(data[position]) - firstDigitValue)
    position += 1
  var fraction = 0.0
  var scale = 1.0
  if position < data.len and data[position] == '.':
    position += 1
    while position < data.len and data[position] >= '0' and data[position] <= '9':
      scale *= 10.0
      fraction = fraction * 10.0 + float(int(data[position]) - firstDigitValue)
      position += 1
```

The circle keeps its center and squared radius. The diameter circle divides the squared endpoint distance by four.

```nim
type Circle = object
  centerX: float
  centerY: float
  radiusSquared: float

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

Three points give a circumcenter, unless they are nearly collinear. That case uses the farthest pair as a diameter.

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

The shuffle runs once per case. The three loops grow the circle and append the formatted answer to the output buffer.

```nim
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
```

## Complexity

Reading the input takes time linear in the input size and holds the whole stream in memory. Each case uses O(n) expected time and O(n) space for the two coordinate arrays. The full run is O(total points) expected time and O(maximum n) working space. Enumerating every pair and triple instead would take O(n^3) time per case.
