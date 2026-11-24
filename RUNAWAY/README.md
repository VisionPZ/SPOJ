## Problem

Read T test cases. Each case gives a rectangle [0,X] by [0,Y] and M holes with integer coordinates. A hole may repeat. Print the point inside the rectangle that has the largest distance to its nearest hole. Print x and y with one decimal digit; a value of 0.05 rounds up.

| Quantity | Bound |
| --- | --- |
| X, Y | 1 to 10000 |
| M | 1 to 1000 |
| Time limit | 13000 ms |
| Memory limit | 1536 MB |

The coordinate range makes a fine full grid far too large.

## Idea

The best point is a corner, an edge tie between two holes, or a circumcenter of three holes. A Delaunay triangulation lists the circumcenters, and a lower envelope of lines lists the edge ties. Each of the O(M) candidates costs O(M) to score, while a full coordinate grid would hold 100 million cells.

## Why It Works

Inside one Voronoi cell, distance from its hole grows as the point moves away. The clipped cell maximum therefore sits at a corner, at an edge tie, or at a triangle circumcenter. A Delaunay triangulation gives one circumcenter per triangle. Its triangles cover exactly the Voronoi vertices that can win.

On the edge x = e, squared distance to hole (u,v) is y² + (-2v)y + (v² + (e-u)²). The `lineSlope` term is -2v. The `lineIntercept` term is v² + (e-u)². The lower envelope of these lines changes only at their crossings. A crossing, or either end of the edge, is the only place the edge maximum can sit.

For three holes, `denominator` equals 2 times the cross product of the two edge vectors. The two power terms are squared distances from the first hole. Dividing gives the circumcenter, which ties the three holes.

In the third sample case the holes are (1200,85), (63,2500), and (2700,2650). The denominator is -13077810. The center is (416452017/290618, 485287415/290618), about (1432.9877, 1669.8464). Rounding gives (1433.0, 1669.8). Its nearest-hole distance is about 1601.88, above every corner.

## Code

The scanner reads the whole input once. It skips whitespace and builds each integer from digits.

```nim
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
```

The scan ends when `i` passes the last digit. Every input number is nonnegative, so no sign branch is needed. One pass over the buffer costs O(total input bytes).

Scoring clamps a candidate into the rectangle, finds the nearest hole, and applies a fixed tie break.

```nim
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
```

Clamping keeps a rounded circumcenter legal. Comparing squared distances avoids a square root per hole. The tie break picks the smaller `bestX`, then the smaller `bestY`, so repeated distances give one answer. The loop visits all M holes, so scoring costs O(M).

The circumcenter comes from two perpendicular bisector equations.

```nim
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
```

A near-zero `denominator` means the three holes are almost collinear, so the point cannot help. Returning a far sentinel skips it without a separate flag. Solving two equations costs constant time.

The edge envelope keeps only the lines that can be nearest.

```nim
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
```

Equal slopes keep the smallest intercept, which removes holes that never win on that edge. Sorting makes slopes descend; the stack pops any line whose crossing falls before its own start. Only crossings inside the edge limits survive. One edge costs O(M log M) from the sort.

The main loop deduplicates holes, tests every candidate, and writes buffered output.

```nim
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
```

Sorting before the duplicate check makes repeats adjacent. A triangle center outside the rectangle is skipped before scoring. Rounding happens once, on the chosen point, and `flushBlockBytes` bounds the output buffer. The case loop runs once per `j`.

## Complexity

Sorting and deduplication cost O(M log M) per case. Incremental triangulation costs O(M²) in the worst case. The O(M) candidates each cost O(M) to score, so scoring costs O(M²). The total is O(M²) time per case and O(T·M²) for T cases. Space is O(M) for holes, triangles, edges, and envelope lines. A grid checked at 0.01 spacing over a 10000 by 10000 rectangle would visit 10¹⁰ points.
