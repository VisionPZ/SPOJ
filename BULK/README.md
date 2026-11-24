## Problem

The input gives T bulks. A bulk is a connected solid made of unit cubes. The input lists every exposed face, including the walls of hollow spaces. Each face is an orthogonal polygon in one plane. Its vertices appear in order, but the outward side is not marked. Print the cube count for each bulk.

| Item | Bound |
| --- | --- |
| Bulks T | about 1000 |
| Faces per bulk F | 6 to 250 |
| Vertices per face P | 4 to 200 |
| Coordinate value | 0 to 1000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The surface can be split into many faces, and faces can meet at T-junctions.

## Idea

Use the divergence theorem on the closed surface. The volume is one third of the flux of the position vector through that surface. An axis-aligned face contributes its plane coordinate times its area times the sign of its outward normal. The vertex order alone does not give that sign. The program links faces that share an edge, then propagates orientation signs across the links. Edges are split at T-junctions before linking. Ray casts find nested surfaces, so cavities subtract from the outer volume.

Each face costs O(P log P) time for sorting its edges and vertices.

## Why It Works

The shoelace sum in each plane gives a signed double area. The right-handed plane pairs are (y,z), (z,x) and (x,y). A positive sum means the vertex order points along the positive axis.

For two faces that share an edge, let dir be the traversal direction of that edge from the input order. The outward sign of the second face is the first sign times `relation`, where `relation = -firstDirection * secondDirection`. This holds for convex, concave and flat edges. At a non-manifold edge, four faces meet. The program sorts them by interior direction angle and links neighbors in a cycle.

For one closed surface, the signed contributions sum to six times its volume. Six comes from two factors of three. The factor of three is the divergence theorem in three axes. The other factor of two comes from the double area.

A ray to the right counts crossings of each other surface. Odd parity means the first surface lies inside the other. A cavity then flips the sign of its volume.

The generator produced this worked example for a single cube. The six faces have doubled areas 2, -2, 2, -2, 2 and -2. The propagated signs are 1, 1, 1, 1, -1 and -1. The contributions are 0, -2, 0, -2, -2 and 0. Their absolute sum is 6, and the program divides by 6 to get one cube.

## Code

The scanner walks one input buffer by index. It skips the double spaces without allocating tokens.

```
proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    inc(i)
  result = 0
  while i < inputData.len and inputData[i] > ' ':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc(i)
```

The loop runs once per digit. The sign branch is absent because the input has no negative values.

This block finds the constant coordinate and the signed double area of each face.

```
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
```

The wrap at `pointCount` closes the polygon. The case picks a right-handed plane pair. The cost is O(P) per face.

This block gives every edge an angle index around its line.

```
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
```

The cross sign converts the plane normal into the interior direction. Four angle slots cover the four quarters around an edge. The cost is O(P) per face.

This block splits edges at every vertex, then links faces around each shared segment.

```
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
```

Splitting first removes T-junctions. Sorting by angle pairs neighbours at non-manifold edges. The cost is O(E log E) for E edges.

This block propagates signs and collects one closed surface per component.

```
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
```

Zero marks an unvisited face. A visited face keeps its first sign. The cost is O(F + E) per bulk.

This block sums the volumes and applies the nesting signs.

```
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

The quarter coordinates keep the ray cast in integers. The final division turns the double area sum into a count.

This block buffers the answer lines and flushes them in large blocks.

```
    outputBuffer.add("The bulk is composed of ")
    outputBuffer.add($volume)
    outputBuffer.add(" units.\n")
    if outputBuffer.len >= flushBlockBytes:
      stdout.write(outputBuffer)
      outputBuffer.setLen(0)

  stdout.write(outputBuffer)
```

The buffer is reused after each flush. One final write covers any remainder. No per-line write appears in the loop.

## Complexity

Reading the input costs O(N) for N bytes. Face parsing costs O(F P) per bulk. Edge and vertex sorting costs O(F P log(F P)). Linking and propagation cost O(F P). The nesting test costs O(C squared times F P) for C closed surfaces, and C stays small.

Total time is O(T F P log(F P)) for T bulks. Total space is O(F P) for the coordinates, edges and links. A flood fill over the solid would cost O(volume), which reaches one billion cells for the largest box.
