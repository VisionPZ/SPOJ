# WINDOW1 — Window (SPOJ)

<https://www.spoj.com/problems/WINDOW1/>

## Problem

The input gives an axis-aligned polygon and an axis-aligned rectangular window. Count how many separate pieces of the polygon's interior lie inside the window.

Input starts with `t`, then cases separated by a blank line. Each case gives four integers `x1 y1 x2 y2` for opposite window corners. The next line gives the vertex count `n`, from 4 to 5000. Then `n` lines give vertices in anticlockwise order, with coordinates from 0 to 10000. Output one integer per case, the fragment count.

All coordinates fit in a modest range, but enumerating unit squares is too slow.

| Quantity | Bound |
| --- | --- |
| Coordinates | 0 to 10000 |
| Polygon vertices | 4 to 5000 |
| Window corners | 0 to 10000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The vertex count drives the work, since the grid alone holds 100 million cells.

The sample input and output follow verbatim.

```
1
0 5 8 1
24
0 0
4 0
4 2
5 2
5 0
7 0
7 3
3 3
3 2
2 2
2 4
1 4
1 5
2 5
2 6
3 6
3 5
4 5
4 6
5 6
5 4
7 4
7 7
0 7
```

```
2
```

## Idea

Sweep thin horizontal bands from the window bottom to its top. Think of slicing a cake into layers and counting how many separate pieces appear in each layer.

In each band the program finds the polygon's vertical edges, pairs their x coordinates into inside intervals, and clips them to the window. Intervals that overlap the band below belong to the same piece. Union-find tracks those joins, and the count rises when a new interval starts.

Testing every unit square would touch up to 100 million cells. The sweep visits only the 5000 vertex heights and the edges.

A band sweep with union-find counts pieces without touching the grid.

## Why It Works

Four facts justify the sweep.

1. A vertical edge crosses a band when its lower end sits at or below the band bottom. Its upper end must reach the band top. A horizontal line crosses a simple polygon an even number of times.
2. Pairing consecutive crossings gives the inside intervals. Several crossings at one x cancel in pairs, so only an odd count leaves a crossing at that x.
3. Two bands join where their intervals overlap with positive length. Sharing one point does not join open interiors.
4. The count update is `componentCount + newStarts - (referencedCount - usedRoots)`. `newStarts` counts intervals with no interval below. The other difference counts how many old pieces merge.

The table names the sweep data.

| Term | Meaning |
| --- | --- |
| `yList` | sorted band boundaries from polygon and window |
| `edgeX`, `edgeLo`, `edgeHi` | vertical edges sorted by x |
| `crossings` | x values with an odd crossing count |
| `curLo`, `curHi` | clipped intervals in the current band |
| `dsuParent` | union-find parent for current pieces |

The generator verified this trace for a U-shaped polygon and window `(0,3,4,1)`.

| Band | Crossings | Intervals | Pieces |
| --- | --- | --- | --- |
| (1,2) | 0 1 3 4 | (0,1), (3,4) | 2 |
| (2,3) | 0 1 3 4 | (0,1), (3,4) | 2 |

Both pieces continue upward, so the answer is 2.

## Code

**Input setup.** Directives, constants, bulk input, and the writer set up parsing.

```nim
{.checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCoord = 10000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips the blank lines between cases. A non-negative input keeps it free of sign handling. The output buffer flushes once per block.

**Union-find.** Union-find keeps the pieces alive across bands.

```nim
proc findRoot(value: int): int =
  var root = value
  while dsuParent[root] != root:
    root = dsuParent[root]
  var node = value
  while dsuParent[node] != node:
    let parentNode = dsuParent[node]
    dsuParent[node] = root
    node = parentNode
  return root

proc unionRoots(leftRoot, rightRoot: int): int =
  let leftFind = findRoot(leftRoot)
  let rightFind = findRoot(rightRoot)
  if leftFind == rightFind:
    return leftFind
  if leftFind < rightFind:
    dsuParent[rightFind] = leftFind
    return leftFind
  dsuParent[leftFind] = rightFind
  return rightFind
```

Path compression keeps lookups fast. The smaller root wins, so labels stay stable. Each operation costs nearly constant time.

**Case setup.** The driver reads one case and builds its band boundaries.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let winX1 = nextInt(inputData, scanPos)
  let winY1 = nextInt(inputData, scanPos)
  let winX2 = nextInt(inputData, scanPos)
  let winY2 = nextInt(inputData, scanPos)
  let vertexCount = nextInt(inputData, scanPos)
  vertX.setLen(vertexCount)
  vertY.setLen(vertexCount)
  for i in 0..<vertexCount:
    vertX[i] = nextInt(inputData, scanPos)
    vertY[i] = nextInt(inputData, scanPos)
  let winLeft = if winX1 < winX2: winX1 else: winX2
  let winRight = if winX1 < winX2: winX2 else: winX1
  let winBottom = if winY1 < winY2: winY1 else: winY2
  let winTop = if winY1 < winY2: winY2 else: winY1
  if winLeft >= winRight or winBottom >= winTop:
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  yVersion += 1
  yList.setLen(0)
  for i in 0..<vertexCount:
    let vertexY = vertY[i]
    if vertexY >= winBottom and vertexY <= winTop:
      if yMark[vertexY] != yVersion:
        yMark[vertexY] = yVersion
        yList.add vertexY
  if yMark[winBottom] != yVersion:
    yMark[winBottom] = yVersion
    yList.add winBottom
  if yMark[winTop] != yVersion:
    yMark[winTop] = yVersion
    yList.add winTop
```

A version stamp clears the mark array in constant time per case. There are at most 5002 band boundaries. An empty window returns zero at once.

**Vertical edges.** Vertical edges are collected once and sorted by x.

```nim
  for i in 1..<yList.len:
    let keyY = yList[i]
    var j = i - 1
    while j >= 0 and yList[j] > keyY:
      yList[j + 1] = yList[j]
      j -= 1
    yList[j + 1] = keyY
  edgeX.setLen(0)
  edgeLo.setLen(0)
  edgeHi.setLen(0)
  for i in 0..<vertexCount:
    let j = (i + 1) mod vertexCount
    if vertX[i] == vertX[j] and vertY[i] != vertY[j]:
      edgeX.add vertX[i]
      edgeLo.add (if vertY[i] < vertY[j]: vertY[i] else: vertY[j])
      edgeHi.add (if vertY[i] < vertY[j]: vertY[j] else: vertY[i])
  for i in 1..<edgeX.len:
    let keyX = edgeX[i]
    let keyLo = edgeLo[i]
    let keyHi = edgeHi[i]
    var j = i - 1
    while j >= 0 and edgeX[j] > keyX:
      edgeX[j + 1] = edgeX[j]
      edgeLo[j + 1] = edgeLo[j]
      edgeHi[j + 1] = edgeHi[j]
      j -= 1
    edgeX[j + 1] = keyX
    edgeLo[j + 1] = keyLo
    edgeHi[j + 1] = keyHi
```

The vertex loop runs `vertexCount` times and collects at most half as many edges. Sorting once lets every band read edges in x order. The wrap index closes the polygon.

**Band crossings.** Each band pairs crossings before reconciling pieces.

```nim
    crossings.setLen(0)
    var groupX = -1
    var groupCount = 0
    for l in 0..<edgeX.len:
      if edgeLo[l] <= bandLow and edgeHi[l] >= bandHigh:
        if edgeX[l] != groupX:
          if groupX >= 0 and groupCount mod 2 == 1:
            crossings.add groupX
          groupX = edgeX[l]
          groupCount = 0
        groupCount += 1
    if groupX >= 0 and groupCount mod 2 == 1:
      crossings.add groupX
    curLo.setLen(0)
    curHi.setLen(0)
    var crossPos = 0
    while crossPos + 1 < crossings.len:
      let leftCross = crossings[crossPos]
      let rightCross = crossings[crossPos + 1]
      let clippedLo = if leftCross > winLeft: leftCross else: winLeft
      let clippedHi = if rightCross < winRight: rightCross else: winRight
      if clippedLo < clippedHi:
        curLo.add clippedLo
        curHi.add clippedHi
      crossPos += 2
```

The loop visits every edge once per band. An even group count leaves no crossing, which avoids zero-width intervals. Pairing consecutive crossings gives one interval per pair.

**Piece count.** The reconciliation updates the running piece count.

```nim
    var referencedCount = 0
    for i in 0..<prevCompCount:
      if rootMark[i] == 1:
        referencedCount += 1
    for i in 0..<prevCompCount:
      rootMark[i] = 0
    var usedRoots = 0
    var newStarts = 0
    for i in 0..<curCount:
      if curFirst[i] == -1:
        newStarts += 1
      else:
        let rootFound = findRoot(curFirst[i])
        if rootMark[rootFound] == 0:
          rootMark[rootFound] = 1
          usedRoots += 1
    componentCount = componentCount + newStarts - (referencedCount - usedRoots)
```

Both loops are bounded by the pieces alive in one band. Ending pieces stay in the total, so an empty band never erases an answer. The union-find arrays hold only current labels.

## Complexity

The sweep visits each band and each edge once.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(total tokens) | one input string |
| Band and edge sort | O(n log n) | O(n) arrays |
| Band sweep | O(n^2) worst case | O(n) per band |
| Output | one flush per 256 KiB | one flush block |

A band holds at most 5000 edges, and the polygon has at most 5000 distinct vertex heights.

The totals use the vertex count.

| Measure | Big O |
| --- | --- |
| Time | O(n^2) worst case per case |
| Space | O(n) per case |

A unit-square flood fill would cost up to 100 million cells per case.
