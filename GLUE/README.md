## Problem

Read the number of test cases, then the number of glue dabs and their coordinates for each case. Count the rectangles that cover every dab and hold at least two dabs on each of the four edges. The box may be rotated, so any rectangle orientation counts. Print one count per case.

| Quantity | Bound |
| --- | --- |
| Dabs per case | 1 to 10000 |
| Coordinate range | -15000 to 15000 |
| Test cases | Not bounded in the statement |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The cap on the dab count drives the hull sort. The number of qualifying rectangles stays finite on judge inputs.

## Idea

Treat each box as the bounding rectangle of the dabs in some orientation. Every side of that rectangle is a supporting line of the convex hull. A side holds two dabs when its line carries a hull edge, or when two dabs share the single hull corner it touches.

One side must lie on a hull edge when the answer is finite. That pins the orientation to a quarter turn of one hull edge normal. The program tests those orientations and divides the pass count by four.

Cost per orientation: four binary searches over the sorted hull normals.

## Why It Works

A side with two dabs lies on a supporting line of the point set. The dabs on that line form a face of the hull, either an edge or one corner holding two dabs.

If all four faces are single corners, the box turns through a small angle and still qualifies. That produces infinitely many rectangles, so judge inputs keep at least one face on an edge.

The hull normals sorted by angle identify each face. An exact match gives an edge face. A direction between two neighbor normals touches the vertex where those edges meet.

Each rectangle appears under four orientations, one for each quarter turn. Dividing by four removes that repetition.

The generator prints the sample walk below.

```
sample hull vertices: 8
normal (-1, -1) passes True
normal (-1, 0) passes True
normal (-1, 1) passes True
normal (0, -1) passes True
normal (0, 1) passes True
normal (1, -1) passes True
normal (1, 0) passes True
normal (1, 1) passes True
valid orientations 8
answer 2
```

All eight normals pass, so the answer is two, which matches the sample output.

## Code

The scanner reads the whole input buffer once. The sign branch keeps negative coordinates accurate. Its cost is one pass over each token.

```nim
proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value * sign
```

The half-plane test orders directions across the full circle. The cross product breaks ties inside one half-plane. Each comparison costs constant time.

```nim
proc crossDirections(left, right: Direction): int64 =
  return int64(left.x) * int64(right.y) - int64(left.y) * int64(right.x)

proc upperHalf(direction: Direction): bool =
  return direction.y > 0 or (direction.y == 0 and direction.x >= 0)

proc compareAngles(left, right: Direction): int =
  let leftUpper = upperHalf(left)
  let rightUpper = upperHalf(right)
  if leftUpper != rightUpper:
    if leftUpper: return -1
    return 1
  let turn = crossDirections(left, right)
  if turn > 0: return -1
  if turn < 0: return 1
  return 0
```

Both chains walk the sorted points once. The left-turn test drops collinear points from the hull. The walk costs linear time after the sort in the main loop.

```nim
proc buildHull(uniquePoints: seq[Point]): seq[Point] =
  if uniquePoints.len <= 2:
    return uniquePoints
  var lower: seq[Point] = @[]
  for point in uniquePoints:
    while lower.len >= 2 and crossAround(lower[lower.len - 2], lower[lower.len - 1], point) <= 0:
      lower.setLen(lower.len - 1)
    lower.add point
  var upper: seq[Point] = @[]
  for i in countdown(uniquePoints.len - 1, 0):
    let point = uniquePoints[i]
    while upper.len >= 2 and crossAround(upper[upper.len - 2], upper[upper.len - 1], point) <= 0:
      upper.setLen(upper.len - 1)
    upper.add point
  result = lower
  result.setLen(lower.len - 1)
  for i in 0 ..< upper.len - 1:
    result.add upper[i]
  return result
```

Binary search narrows the sorted normals to one slot. An exact match gives an edge face, and the previous edge ends at the touched vertex otherwise. The paired count reveals two dabs on that corner. Cost is O(log h) for a hull with h vertices.

```nim
proc faceIsGood(target: Direction, normals: seq[Direction], endCounts: seq[int]): bool =
  var i = 0
  var j = normals.len
  while i < j:
    let k = (i + j) div 2
    if compareAngles(normals[k], target) < 0:
      i = k + 1
    else:
      j = k
  if i < normals.len and compareAngles(normals[i], target) == 0:
    return true
  var l = i - 1
  if l < 0:
    l = normals.len - 1
  return endCounts[l] >= 2
```

Each hull edge gives one outward normal, stored as a reduced integer direction. The paired count records the dabs at the edge end vertex. This loop costs linear time in the hull size.

```nim
  let hullSize = hull.len
  var normals: seq[Direction] = @[]
  var endCounts: seq[int] = @[]
  for k in 0 ..< hullSize:
    let l = (k + 1) mod hullSize
    let deltaX = hull[l].x - hull[k].x
    let deltaY = hull[l].y - hull[k].y
    let divisor = greatestCommonDivisor(abs(deltaX), abs(deltaY))
    normals.add (deltaY div divisor, -(deltaX div divisor))
    endCounts.add pointCounts[findPoint(uniquePoints, hull[l])]

```

Four quarter turns of every normal form the candidate list, and sorting removes repeats. A valid orientation passes all four face checks. Each rectangle is counted once per quarter turn, so the program divides by four. Cost is O(h log h).

```nim
  var candidates: seq[Direction] = @[]
  for normal in sortedNormals:
    var current = normal
    for l in 0 ..< 4:
      candidates.add current
      current = rotateQuarter(current)
  candidates.sort(compareAngles)

  var orientations: seq[Direction] = @[]
  for candidate in candidates:
    if orientations.len == 0 or compareAngles(orientations[orientations.len - 1], candidate) != 0:
      orientations.add candidate

  var validCount = 0
  for orientation in orientations:
    var current = orientation
    var allGood = true
    for l in 0 ..< 4:
      if not faceIsGood(current, sortedNormals, sortedEndCounts):
        allGood = false
        break
      current = rotateQuarter(current)
    if allGood:
      validCount += 1

  appendOutput($(validCount div 4))
  outputBuffer.add '\n'
```

## Complexity

Reading and sorting the dabs costs O(n log n) per case. The hull walk costs O(n). Building the normals and candidates costs O(h log h), and the face checks cost O(h log h), where h is the hull size.

Total time is O(n log n + h log h) per case, and total space is O(n). Enumerating every rectangle from dab pairs would cost O(n^3) per case.
