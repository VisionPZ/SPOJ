# BULK — The Bulk! (SPOJ)
<https://www.spoj.com/problems/BULK/>

## Problem

Each test case lists the face polygons of a connected solid made of unit cubes, including cavity walls. Compute the solid's volume in cubes.

Input starts with a bulk count T. Each bulk begins with a face count F, then F lines. Each face line gives a point count P followed by 3P coordinates; the points are separated by two spaces. Print `The bulk is composed of N units.` for each bulk.

The statement and judge table give these bounds:

| Item | Bound |
| --- | --- |
| Bulks T | about 1000 |
| Faces per bulk F | 6 to 250 |
| Vertices per face P | 4 to 200 |
| Coordinate value | 0 to 1000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The surface can split into many faces, and faces can meet at T-junctions.

The sample input and output:

```
2
12
4  10 10 10  10 10 20  10 20 20  10 20 10
4  20 10 10  20 10 20  20 20 20  20 20 10
4  10 10 10  10 10 20  20 10 20  20 10 10
4  10 20 10  10 20 20  20 20 20  20 20 10
4  10 10 10  10 20 10  20 20 10  20 10 10
5  10 10 20  10 20 20  20 20 20  20 15 20  20 10 20
4  14 14 14  14 14 16  14 16 16  14 16 14
4  16 14 14  16 14 16  16 16 16  16 16 14
4  14 14 14  14 14 16  16 14 16  16 14 14
4  14 16 14  14 16 16  16 16 16  16 16 14
4  14 14 14  14 16 14  16 16 14  16 14 14
4  14 14 16  14 16 16  16 16 16  16 14 16
12
4  20 20 30  20 30 30  30 30 30  30 20 30
4  10 10 10  10 40 10  40 40 10  40 10 10
6  10 10 20  20 10 20  20 30 20  30 30 20  30 40 20  10 40 20
6  20 10 20  20 20 20  30 20 20  30 40 20  40 40 20  40 10 20
4  10 10 10  40 10 10  40 10 20  10 10 20
4  10 40 10  40 40 10  40 40 20  10 40 20
4  20 20 20  30 20 20  30 20 30  20 20 30
4  20 30 20  30 30 20  30 30 30  20 30 30
4  10 10 10  10 40 10  10 40 20  10 10 20
4  40 10 10  40 40 10  40 40 20  40 10 20
4  20 20 20  20 30 20  20 30 30  20 20 30
4  30 20 20  30 30 20  30 30 30  30 20 30
```

```
The bulk is composed of 992 units.
The bulk is composed of 10000 units.
```

The first bulk has a cavity, which the program subtracts.

## Idea

Use the divergence theorem (a rule linking a closed surface to the volume inside). The volume is one sixth of the signed sum of face areas times their plane coordinates. The vertex order does not mark the outward side, so the program links neighboring faces and propagates orientation signs. Think of coloring one face outward, then walking the surface so each shared edge keeps opposite sides consistent.

Edges are split at T-junctions before linking, and ray casts find nested surfaces so cavities subtract. Each face costs O(P log P) to sort its edges and vertices. Filling a voxel grid would need over a billion cells and cannot work.

Takeaway: orient the faces, then integrate volume over them.

## Why It Works

1. The shoelace sum in a face's plane gives a signed double area.
2. The right-handed plane pairs are (y, z), (z, x), and (x, y).
3. Two faces sharing an edge must point to opposite sides, so their signs differ by `relation = -firstDirection * secondDirection`.
4. At a non-manifold edge, four faces meet; sorting them by interior angle and linking neighbors in a cycle keeps the orientation consistent.
5. For one closed surface, the signed contributions sum to six times its volume. Three factors come from the divergence theorem, and two come from the double area.
6. A ray cast counts crossings of other surfaces; odd parity means a surface is nested, so its volume flips sign.

The volume chain uses these terms.

| Term | Meaning |
| --- | --- |
| `doubledArea` | signed shoelace area times two |
| `orientations[k]` | +1 or -1, the outward side choice for a face |
| `componentVolume` | sum of orientation times doubled area times plane |
| `depthParity` | nesting depth from ray casts, which flips cavity signs |
| `totalVolume div 6` | final cube count |

The factor six converts the surface sum to cubes.

A script traced a single unit cube from the sample style:

| Face plane | Doubled area | Orientation | Contribution |
| --- | --- | --- | --- |
| x = 0 | 2 | -1 | 0 |
| x = 1 | 2 | +1 | 2 |
| y = 0 | 2 | -1 | 0 |
| y = 1 | 2 | +1 | 2 |
| z = 0 | 2 | -1 | 0 |
| z = 1 | 2 | +1 | 2 |

The contributions sum to 6, and 6 divided by 6 gives one cube.

## Code

**Record types and constants.**
```nim
import std/algorithm

type
  FaceRecord = object
    axis: int
    plane: int
    doubledArea: int
    vertexStart: int
    vertexCount: int
  EdgeRecord = object
    lineKey: int
    low: int
    high: int
    direction: int
    faceIndex: int
    angleIndex: int
  PointRecord = object
    lineKey: int
    position: int
  SubEdgeRecord = object
    low: int
    high: int
    faceIndex: int
    direction: int
    angleIndex: int
  LinkRecord = object
    otherFace: int
    relation: int

const
  flushBlockBytes = 1 shl 18
  firstDigitValue = 48
  coordinateBase = 1001
  quarterScale = 4

```
Faces, edges, points, and links each use a plain object. `coordinateBase` packs two coordinates into one line key. `quarterScale` scales samples away from face planes.

**Scanner and geometry helpers.**
```nim
proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    inc(i)
  result = 0
  while i < inputData.len and inputData[i] > ' ':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc(i)

proc cmpEdge(leftEdge, rightEdge: EdgeRecord): int =
  if leftEdge.lineKey != rightEdge.lineKey:
    return leftEdge.lineKey - rightEdge.lineKey
  if leftEdge.low != rightEdge.low:
    return leftEdge.low - rightEdge.low
  leftEdge.high - rightEdge.high

proc cmpPoint(leftPoint, rightPoint: PointRecord): int =
  if leftPoint.lineKey != rightPoint.lineKey:
    return leftPoint.lineKey - rightPoint.lineKey
  leftPoint.position - rightPoint.position

proc cmpSubEdge(leftEdge, rightEdge: SubEdgeRecord): int =
  if leftEdge.low != rightEdge.low:
    return leftEdge.low - rightEdge.low
  leftEdge.high - rightEdge.high

proc cmpAngle(leftEdge, rightEdge: SubEdgeRecord): int =
  leftEdge.angleIndex - rightEdge.angleIndex

proc encodeLine(axisIndex, firstCoord, secondCoord: int): int =
  (axisIndex * coordinateBase + firstCoord) * coordinateBase + secondCoord

proc insideOrthoPolygon(allCoords: seq[int], vertexStart, vertexCount,
                        queryU4, queryV4: int): bool =
  var inside = false
  for i in 0 ..< vertexCount:
    let j = vertexStart + i * 3
    let k = vertexStart + ((i + 1) mod vertexCount) * 3
    let firstU = allCoords[j + 1]
    let firstV = allCoords[j + 2]
    let secondU = allCoords[k + 1]
    let secondV = allCoords[k + 2]
    if (firstV * quarterScale > queryV4) != (secondV * quarterScale > queryV4):
      let vDifference = secondV - firstV
      let crossing = (int64(firstU) * quarterScale - int64(queryU4)) * int64(vDifference) +
                     (int64(queryV4) - int64(firstV) * quarterScale) * int64(secondU - firstU)
      if (vDifference > 0 and crossing > 0) or (vDifference < 0 and crossing < 0):
        inside = not inside
  return inside

proc pointInsideComponent(sampleX4, sampleY4, sampleZ4: int,
                          componentFaces: seq[int], faces: seq[FaceRecord],
                          allCoords: seq[int]): bool =
  var crossings = 0
  for i in componentFaces:
    let face = faces[i]
    if face.axis != 0:
      continue
    if face.plane * quarterScale <= sampleX4:
      continue
    if insideOrthoPolygon(allCoords, face.vertexStart, face.vertexCount,
                          sampleY4, sampleZ4):
      inc(crossings)
  return (crossings and 1) == 1

```
The scanner walks the buffer and skips the double spaces. Comparators sort edges, points, sub-edges, and angles. `insideOrthoPolygon` casts a ray across an orthogonal face.

**Edge splitting and face links.**
```nim
proc solveBulk(allCoords: var seq[int], faces: var seq[FaceRecord],
               edges: var seq[EdgeRecord], points: var seq[PointRecord],
               subEdges: var seq[SubEdgeRecord],
               links: var seq[seq[LinkRecord]], orientations: var seq[int]): int64 =
  var angleGroup: seq[SubEdgeRecord] = @[]
  sort(edges, cmpEdge)
  sort(points, cmpPoint)

  var i = 0
  var j = 0
  while j < edges.len:
    let startKey = edges[j].lineKey
    var pointBegin = i
    while pointBegin < points.len and points[pointBegin].lineKey < startKey:
      inc(pointBegin)
    var pointEnd = pointBegin
    while pointEnd < points.len and points[pointEnd].lineKey == startKey:
      inc(pointEnd)
    i = pointEnd

    subEdges.setLen(0)
    var currentEdge = j
    while currentEdge < edges.len and edges[currentEdge].lineKey == startKey:
      let edgeLow = edges[currentEdge].low
      let edgeHigh = edges[currentEdge].high
      var k = pointBegin
      while k < pointEnd and points[k].position < edgeLow:
        inc(k)
      var previousPosition = edgeLow
      while k < pointEnd and points[k].position < edgeHigh:
        let splitPosition = points[k].position
        if splitPosition > previousPosition:
          subEdges.add(SubEdgeRecord(low: previousPosition, high: splitPosition,
                                     faceIndex: edges[currentEdge].faceIndex,
                                     direction: edges[currentEdge].direction,
                                     angleIndex: edges[currentEdge].angleIndex))
          previousPosition = splitPosition
        inc(k)
      if previousPosition < edgeHigh:
        subEdges.add(SubEdgeRecord(low: previousPosition, high: edgeHigh,
                                   faceIndex: edges[currentEdge].faceIndex,
                                   direction: edges[currentEdge].direction,
                                   angleIndex: edges[currentEdge].angleIndex))
      inc(currentEdge)

    sort(subEdges, cmpSubEdge)
    var groupStart = 0
    while groupStart < subEdges.len:
      var groupEnd = groupStart + 1
      while groupEnd < subEdges.len and
            subEdges[groupEnd].low == subEdges[groupStart].low and
            subEdges[groupEnd].high == subEdges[groupStart].high:
        inc(groupEnd)
      if groupEnd - groupStart >= 2:
        angleGroup.setLen(0)
        for l in groupStart ..< groupEnd:
          angleGroup.add(subEdges[l])
        sort(angleGroup, cmpAngle)
        for l in 0 ..< angleGroup.len:
          let firstFace = angleGroup[l].faceIndex
          let firstDirection = angleGroup[l].direction
          let k = (l + 1) mod angleGroup.len
          let secondFace = angleGroup[k].faceIndex
          let secondDirection = angleGroup[k].direction
          let relation = -firstDirection * secondDirection
          links[firstFace].add(LinkRecord(otherFace: secondFace, relation: relation))
          links[secondFace].add(LinkRecord(otherFace: firstFace, relation: relation))
      groupStart = groupEnd

    j = currentEdge
```
Edges are grouped by 3D line, then split at every vertex position. Sub-edges that overlap get linked in angular order, which records the orientation relation between their faces.

**Orientation and volume.**
```nim
  orientations.setLen(faces.len)
  for l in 0 ..< faces.len:
    orientations[l] = 0
  var queue: seq[int] = @[]
  var components: seq[seq[int]] = @[]
  for l in 0 ..< faces.len:
    if orientations[l] != 0:
      continue
    orientations[l] = 1
    queue.setLen(0)
    queue.add(l)
    var currentComponent: seq[int] = @[]
    var k = 0
    while k < queue.len:
      let currentFace = queue[k]
      inc(k)
      currentComponent.add(currentFace)
      for l in 0 ..< links[currentFace].len:
        let nextFace = links[currentFace][l].otherFace
        let wanted = orientations[currentFace] * links[currentFace][l].relation
        if orientations[nextFace] == 0:
          orientations[nextFace] = wanted
          queue.add(nextFace)
    components.add(currentComponent)

  var componentVolumes: seq[int64] = @[]
  var sampleX4: seq[int] = @[]
  var sampleY4: seq[int] = @[]
  var sampleZ4: seq[int] = @[]
  for l in 0 ..< components.len:
    let component = components[l]
    var componentVolume: int64 = 0
    for k in component:
      let face = faces[k]
      componentVolume += int64(orientations[k]) * int64(face.doubledArea) * int64(face.plane)
    componentVolumes.add(componentVolume)
    let firstFace = faces[component[0]]
    sampleX4.add(quarterScale * allCoords[firstFace.vertexStart] + 1)
    sampleY4.add(quarterScale * allCoords[firstFace.vertexStart + 1] + 1)
    sampleZ4.add(quarterScale * allCoords[firstFace.vertexStart + 2] + 1)

  var totalVolume: int64 = 0
  for l in 0 ..< components.len:
    var depthParity = 0
    for k in 0 ..< components.len:
      if k == l:
        continue
      if pointInsideComponent(sampleX4[l], sampleY4[l],
                              sampleZ4[l], components[k],
                              faces, allCoords):
        depthParity = 1 - depthParity
    let componentVolume = componentVolumes[l]
    let volumeSign = if componentVolume > 0: 1 else: -1
    let depthSign = if depthParity == 0: 1 else: -1
    totalVolume += int64(volumeSign * depthSign) * componentVolume
  if totalVolume < 0:
    totalVolume = -totalVolume
  return totalVolume div 6
```
A breadth-first walk assigns +1 or -1 to each face. Each connected component contributes a signed volume, and ray casts set the nesting parity. The absolute total divided by six is returned.

**Driver.**
```nim
when isMainModule:
  var inputData = ""
  var inputLine = ""
  while readLine(stdin, inputLine):
    inputData.add(inputLine)
    inputData.add('\n')

  var outputBuffer = ""
  var i = 0
  let testCount = nextInt(inputData, i)

  var allCoords: seq[int] = @[]
  var faces: seq[FaceRecord] = @[]
  var edges: seq[EdgeRecord] = @[]
  var points: seq[PointRecord] = @[]
  var subEdges: seq[SubEdgeRecord] = @[]
  var links: seq[seq[LinkRecord]] = @[]
  var orientations: seq[int] = @[]

  for j in 0 ..< testCount:
    let faceCount = nextInt(inputData, i)
    allCoords.setLen(0)
    faces.setLen(0)
    edges.setLen(0)
    points.setLen(0)
    links.setLen(faceCount)
    for k in 0 ..< faceCount:
      links[k] = @[]

    for k in 0 ..< faceCount:
      let pointCount = nextInt(inputData, i)
      let vertexStart = allCoords.len
      for l in 0 ..< pointCount:
        allCoords.add(nextInt(inputData, i))
        allCoords.add(nextInt(inputData, i))
        allCoords.add(nextInt(inputData, i))

      var constantAxis = 0
      let firstX = allCoords[vertexStart]
      let firstY = allCoords[vertexStart + 1]
      var allSameX = true
      var allSameY = true
      for l in 0 ..< pointCount:
        let baseIndex = vertexStart + l * 3
        if allCoords[baseIndex] != firstX: allSameX = false
        if allCoords[baseIndex + 1] != firstY: allSameY = false
      if allSameX:
        constantAxis = 0
      elif allSameY:
        constantAxis = 1
      else:
        constantAxis = 2

      var doubledArea = 0
      for l in 0 ..< pointCount:
        let currentIndex = vertexStart + l * 3
        let nextIndex = vertexStart + ((l + 1) mod pointCount) * 3
        var currentU = 0
        var currentV = 0
        var nextU = 0
        var nextV = 0
        case constantAxis
        of 0:
          currentU = allCoords[currentIndex + 1]
          currentV = allCoords[currentIndex + 2]
          nextU = allCoords[nextIndex + 1]
          nextV = allCoords[nextIndex + 2]
        of 1:
          currentU = allCoords[currentIndex + 2]
          currentV = allCoords[currentIndex]
          nextU = allCoords[nextIndex + 2]
          nextV = allCoords[nextIndex]
        else:
          currentU = allCoords[currentIndex]
          currentV = allCoords[currentIndex + 1]
          nextU = allCoords[nextIndex]
          nextV = allCoords[nextIndex + 1]
        doubledArea += currentU * nextV - nextU * currentV

      faces.add(FaceRecord(axis: constantAxis, plane: allCoords[vertexStart + constantAxis],
                           doubledArea: doubledArea, vertexStart: vertexStart,
                           vertexCount: pointCount))

      for l in 0 ..< pointCount:
        let baseIndex = vertexStart + l * 3
        let coordX = allCoords[baseIndex]
        let coordY = allCoords[baseIndex + 1]
        let coordZ = allCoords[baseIndex + 2]
        points.add(PointRecord(lineKey: encodeLine(0, coordY, coordZ), position: coordX))
        points.add(PointRecord(lineKey: encodeLine(1, coordZ, coordX), position: coordY))
        points.add(PointRecord(lineKey: encodeLine(2, coordX, coordY), position: coordZ))

      for l in 0 ..< pointCount:
        let currentIndex = vertexStart + l * 3
        let nextIndex = vertexStart + ((l + 1) mod pointCount) * 3
        var edgeAxis = 0
        if allCoords[currentIndex] != allCoords[nextIndex]:
          edgeAxis = 0
        elif allCoords[currentIndex + 1] != allCoords[nextIndex + 1]:
          edgeAxis = 1
        else:
          edgeAxis = 2
        let currentValue = allCoords[currentIndex + edgeAxis]
        let nextValue = allCoords[nextIndex + edgeAxis]
        let edgeLow = if currentValue < nextValue: currentValue else: nextValue
        let edgeHigh = if currentValue < nextValue: nextValue else: currentValue
        let direction = if currentValue < nextValue: 1 else: -1
        var firstCoord = 0
        var secondCoord = 0
        case edgeAxis
        of 0:
          firstCoord = allCoords[currentIndex + 1]
          secondCoord = allCoords[currentIndex + 2]
        of 1:
          firstCoord = allCoords[currentIndex + 2]
          secondCoord = allCoords[currentIndex]
        else:
          firstCoord = allCoords[currentIndex]
          secondCoord = allCoords[currentIndex + 1]
        let areaSign = if doubledArea > 0: 1 else: -1
        let crossSign = if edgeAxis == (constantAxis + 1) mod 3: 1 else: -1
        let interiorSign = areaSign * direction * crossSign
        let interiorAxis = 3 - constantAxis - edgeAxis
        let firstPerpAxis = (edgeAxis + 1) mod 3
        var angleIndex = 0
        if interiorAxis == firstPerpAxis:
          angleIndex = if interiorSign > 0: 0 else: 2
        else:
          angleIndex = if interiorSign > 0: 1 else: 3
        edges.add(EdgeRecord(lineKey: encodeLine(edgeAxis, firstCoord, secondCoord),
                             low: edgeLow, high: edgeHigh,
                             direction: direction, faceIndex: k,
                             angleIndex: angleIndex))

    let volume = solveBulk(allCoords, faces, edges, points, subEdges, links, orientations)
    outputBuffer.add("The bulk is composed of ")
    outputBuffer.add($volume)
    outputBuffer.add(" units.\n")
    if outputBuffer.len >= flushBlockBytes:
      stdout.write(outputBuffer)
      outputBuffer.setLen(0)

  stdout.write(outputBuffer)
```
The main block reads each face, finds its constant axis and doubled area, and emits point and edge records. The volume routine is called once per bulk, and the sentence answer is buffered.

## Complexity

Sorting edges and sub-edges dominates each bulk.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Face area | O(P) per face | O(P) per face |
| Edge grouping | O(E log E) | O(E) |
| Orientation walk | O(F + links) | O(F) |
| Volume and ray casts | O(F squared) worst case | O(F) |
| Output | one write per block | flushBlockBytes |

Face count and vertex count stay modest, so the nested ray checks remain small.

| Measure | Big O |
| --- | --- |
| Time per bulk | O(E log E + F squared) |
| Space per bulk | O(P + E + F) |

Voxelizing a 1001 cubed grid would need over a billion cells, while surface integration uses only the given faces.
