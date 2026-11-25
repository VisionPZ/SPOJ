# OFBEAT — Officers on the Beat (SPOJ)
<https://www.spoj.com/problems/OFBEAT/>

## Problem

A medieval city patrols a minimum set of streets from which every street stays visible. The chosen streets must also cross one another.

The input starts with the case count. Each case gives the wall section count and signed section lengths. Print the number of patrolled streets.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Wall sections `n` | 4 to 2000 |
| Section length | 1 to 100000 |
| Wall shape | simple polygon, alternating directions |
| Judge time | 2125 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

The answer counts streets, not wall sections.

Sample input and output:

Input:

```
1
14
+2 +2 +2 +2 -4 +2 +1 +2 -3 +2 -2 -8 +4 -2
```

Output:

```
4
```

## Idea

Treat the two street directions as two sides of a crossing graph. Think of choosing the fewest hallways so every hallway meets a chosen one.

The program builds horizontal and vertical street segments, then a bipartite graph (two groups joined only across groups) of crossings. That graph is chordal bipartite (no long holes), so a greedy cover is optimal. The captain needs coverage both ways, so the program runs the greedy twice with roles swapped and adds the sizes.

Takeaway: two optimal covers add up to the patrol size.

## Why It Works

The wall shape makes the crossing graph easy to cover.

1. Consecutive wall sections alternate direction, so each section lies on one street.
2. Overlapping sections merge into one full street segment.
3. A horizontal and a vertical street cross at one grid point.
4. In a chordal bipartite graph, a street covering a whole uncovered group belongs to some minimum cover.
5. The greedy picks that street, removes the rows it covers, and repeats.

The terms are:

| Term | Meaning |
| --- | --- |
| `StreetSegment` | One maximal street inside the wall |
| `colMask` | Bit set of rows one street crosses |
| `colDegree` | Number of active rows still crossed |
| `coverCount` | Streets chosen so far |

Bitsets make domination tests fast.

A script reduced a rectangular wall to its streets:

| Wall sections | Vertical streets | Horizontal streets | Chosen vertical | Chosen horizontal | Answer |
| --- | --- | --- | --- | --- | --- |
| `+2 +2 -2 -2` | x=0, x=2 | y=0, y=2 | 1 | 1 | 2 |

Each chosen street crosses the other, so both rules hold.

## Code

**Imports and constants.**

```nim
import algorithm, bitops

{.passC: "-O3".}
{.passL: "-s".}
{.push checks: off, assertions: off, stacktrace: off, lineDir: off.}

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  maxRows = 4096
  maxWords = 64

var inputData = ""
```

Optimization pragmas and checks-off guards speed up the bit work. The word count caps row bitsets at 64 streets.

**Bulk input and output.**

```nim
proc readAllInput() =
  var chunk = newString(flushBlockBytes)
  var totalBytes = 0
  while true:
    let bytesRead = stdin.readBuffer(addr chunk[0], flushBlockBytes)
    if bytesRead <= 0:
      break
    let previousLen = totalBytes
    totalBytes += bytesRead
    if inputData.len < totalBytes:
      let nextCapacity = max(totalBytes, inputData.len * 2)
      inputData.setLen(nextCapacity)
    copyMem(addr inputData[previousLen], addr chunk[0], bytesRead)
  inputData.setLen(totalBytes)

var scanPos = 0

proc nextSigned(): int {.inline.} =
  let dataLen = inputData.len
  while scanPos < dataLen and inputData[scanPos] != '-' and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  var signValue = 1
  if scanPos < dataLen and inputData[scanPos] == '-':
    signValue = -1
    inc scanPos
  var value = 0
  while scanPos < dataLen and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    inc scanPos
  return signValue * value

var outputBuffer = ""

proc appendInt(value: int) {.inline.} =
  outputBuffer.add($value)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)
```

A chunked reader fills the input buffer. `nextSigned` reads both signs and digits. Answers flush in blocks.

**Record types and comparators.**

```nim
type
  Point = object
    x, y: int
  WallEdge = object
    axisCoord, lowCoord, highCoord: int
  ActiveSpan = object
    lowCoord, highCoord, birthCoord: int
  StreetSegment = object
    axisCoord, lowCoord, highCoord: int

proc compareInt(left, right: int): int =
  if left < right: return -1
  if left > right: return 1
  return 0

proc compareWallEdge(left, right: WallEdge): int =
  if left.axisCoord != right.axisCoord:
    return compareInt(left.axisCoord, right.axisCoord)
  return compareInt(left.lowCoord, right.lowCoord)
```

Points, wall edges, and spans each get a named type. Comparators sort by axis and then by low coordinate.

**Street extraction.**

```nim
proc extractAxisSegments(vertices: seq[Point], swapAxes: bool): seq[StreetSegment] =
  let edgeCount = vertices.len - 1
  var wallEdges = newSeqOfCap[WallEdge](edgeCount div 2)
  for i in 0..<edgeCount:
    let firstX = if swapAxes: vertices[i].y else: vertices[i].x
    let firstY = if swapAxes: vertices[i].x else: vertices[i].y
    let secondX = if swapAxes: vertices[i + 1].y else: vertices[i + 1].x
    let secondY = if swapAxes: vertices[i + 1].x else: vertices[i + 1].y
    if firstX == secondX:
      if firstY < secondY:
        wallEdges.add(WallEdge(axisCoord: firstX, lowCoord: firstY, highCoord: secondY))
      else:
        wallEdges.add(WallEdge(axisCoord: firstX, lowCoord: secondY, highCoord: firstY))
  wallEdges.sort(compareWallEdge)

  var activeSpans: seq[ActiveSpan] = @[]
  var nextSpans: seq[ActiveSpan] = @[]
  var updatedRanges: seq[tuple[lowCoord, highCoord: int]] = @[]
  var cutCoords: seq[int] = @[]
  var mergedRanges: seq[tuple[lowCoord, highCoord: int]] = @[]
  result = newSeqOfCap[StreetSegment](edgeCount)

  var edgeStart = 0
  let wallCount = wallEdges.len
  while edgeStart < wallCount:
    let currentAxis = wallEdges[edgeStart].axisCoord
    var edgeStop = edgeStart
    while edgeStop < wallCount and wallEdges[edgeStop].axisCoord == currentAxis:
      inc edgeStop

    cutCoords.setLen(0)
    for span in activeSpans:
      cutCoords.add(span.lowCoord)
      cutCoords.add(span.highCoord)
    for k in edgeStart..<edgeStop:
      cutCoords.add(wallEdges[k].lowCoord)
      cutCoords.add(wallEdges[k].highCoord)
    cutCoords.sort(compareInt)
    var uniqueLen = 0
    for k in 0..<cutCoords.len:
      if uniqueLen == 0 or cutCoords[k] != cutCoords[uniqueLen - 1]:
        cutCoords[uniqueLen] = cutCoords[k]
        inc uniqueLen
    cutCoords.setLen(uniqueLen)

    updatedRanges.setLen(0)
    var activeIdx = 0
    var edgeIdx = edgeStart
    for k in 0..<(uniqueLen - 1):
      let segLow = cutCoords[k]
      let segHigh = cutCoords[k + 1]
      while activeIdx < activeSpans.len and activeSpans[activeIdx].highCoord <= segLow:
        inc activeIdx
      while edgeIdx < edgeStop and wallEdges[edgeIdx].highCoord <= segLow:
        inc edgeIdx
      let inActive = (activeIdx < activeSpans.len) and
                     (activeSpans[activeIdx].lowCoord <= segLow) and
                     (segHigh <= activeSpans[activeIdx].highCoord)
      let inWall = (edgeIdx < edgeStop) and
                   (wallEdges[edgeIdx].lowCoord <= segLow) and
                   (segHigh <= wallEdges[edgeIdx].highCoord)
      if inActive xor inWall:
        if updatedRanges.len > 0 and updatedRanges[updatedRanges.len - 1].highCoord == segLow:
          updatedRanges[updatedRanges.len - 1].highCoord = segHigh
        else:
          updatedRanges.add((segLow, segHigh))

    var untouched = newSeq[bool](activeSpans.len)
    var touchIdx = edgeStart
    for spanIdx in 0..<activeSpans.len:
      let span = activeSpans[spanIdx]
      while touchIdx < edgeStop and wallEdges[touchIdx].highCoord < span.lowCoord:
        inc touchIdx
      let isTouched = (touchIdx < edgeStop) and (wallEdges[touchIdx].lowCoord <= span.highCoord)
      if not isTouched:
        untouched[spanIdx] = true
      else:
        if currentAxis - span.birthCoord >= 2:
          result.add(StreetSegment(axisCoord: span.birthCoord + 1,
                                   lowCoord: span.lowCoord,
                                   highCoord: span.highCoord))

    mergedRanges.setLen(0)
    var leftCursor = 0
    var rightCursor = 0
    while leftCursor < activeSpans.len or rightCursor < updatedRanges.len:
      var rangeLow, rangeHigh: int
      if rightCursor == updatedRanges.len or
         (leftCursor < activeSpans.len and activeSpans[leftCursor].lowCoord <= updatedRanges[rightCursor].lowCoord):
        rangeLow = activeSpans[leftCursor].lowCoord
        rangeHigh = activeSpans[leftCursor].highCoord
        inc leftCursor
      else:
        rangeLow = updatedRanges[rightCursor].lowCoord
        rangeHigh = updatedRanges[rightCursor].highCoord
        inc rightCursor
      if mergedRanges.len > 0 and rangeLow <= mergedRanges[mergedRanges.len - 1].highCoord:
        if rangeHigh > mergedRanges[mergedRanges.len - 1].highCoord:
          mergedRanges[mergedRanges.len - 1].highCoord = rangeHigh
      else:
        mergedRanges.add((rangeLow, rangeHigh))

    var matchCursor = 0
    for merged in mergedRanges:
      while matchCursor < activeSpans.len and activeSpans[matchCursor].lowCoord < merged.lowCoord:
        inc matchCursor
      let skipUnchanged = (matchCursor < activeSpans.len) and untouched[matchCursor] and
                          (activeSpans[matchCursor].lowCoord == merged.lowCoord) and
                          (activeSpans[matchCursor].highCoord == merged.highCoord)
      if not skipUnchanged:
        result.add(StreetSegment(axisCoord: currentAxis,
                                 lowCoord: merged.lowCoord,
                                 highCoord: merged.highCoord))

    nextSpans.setLen(0)
    var oldCursor = 0
    for updated in updatedRanges:
      while oldCursor < activeSpans.len and activeSpans[oldCursor].lowCoord < updated.lowCoord:
        inc oldCursor
      if oldCursor < activeSpans.len and untouched[oldCursor] and
         activeSpans[oldCursor].lowCoord == updated.lowCoord and
         activeSpans[oldCursor].highCoord == updated.highCoord:
        nextSpans.add(activeSpans[oldCursor])
      else:
        nextSpans.add(ActiveSpan(lowCoord: updated.lowCoord,
                                 highCoord: updated.highCoord,
                                 birthCoord: currentAxis))
    swap(activeSpans, nextSpans)
    edgeStart = edgeStop
```

The code groups wall edges by axis and sweeps cut coordinates. Symmetric differences update the active spans. Each group costs one sort and one sweep.

**Greedy cover.**

```nim
type Bitset = array[maxWords, uint64]

var colMask: array[maxRows, Bitset]
var colDegree: array[maxRows, int32]
var activeRows: Bitset
var rowColsFlat: seq[int32] = @[]
var rowStart: array[maxRows + 1, int32]
var rowOrder: array[maxRows, int32]
var witnessCol: array[maxRows, int32]
var witnessRow: array[maxRows, int32]
var witnessDegree: array[maxRows, int32]

proc solveChordalSetCover(rowCount, colCount: int, rowAdj: seq[seq[int32]]): int =
  if rowCount == 0: return 0
  let wordCount = (rowCount + 63) div 64
  for wordIdx in 0..<wordCount: activeRows[wordIdx] = 0'u64
  for rowIdx in 0..<rowCount:
    activeRows[rowIdx shr 6] = activeRows[rowIdx shr 6] or (1'u64 shl uint(rowIdx and 63))
    witnessRow[rowIdx] = -1'i32
    rowOrder[rowIdx] = int32(rowIdx)

  for colIdx in 0..<colCount:
    colDegree[colIdx] = 0'i32
    for wordIdx in 0..<wordCount: colMask[colIdx][wordIdx] = 0'u64

  rowColsFlat.setLen(0)
  for rowIdx in 0..<rowCount:
    rowStart[rowIdx] = int32(rowColsFlat.len)
    let rowWord = rowIdx shr 6
    let rowBit = 1'u64 shl uint(rowIdx and 63)
    for colIdx in rowAdj[rowIdx]:
      rowColsFlat.add(colIdx)
      colMask[colIdx][rowWord] = colMask[colIdx][rowWord] or rowBit
      inc colDegree[colIdx]
  rowStart[rowCount] = int32(rowColsFlat.len)

  var maxDegree = 0
  for rowIdx in 0..<rowCount:
    let deg = int(rowStart[rowIdx + 1] - rowStart[rowIdx])
    if deg > maxDegree: maxDegree = deg
  var bucketOffset = newSeq[int32](maxDegree + 2)
  for rowIdx in 0..<rowCount:
    inc bucketOffset[int(rowStart[rowIdx + 1] - rowStart[rowIdx]) + 1]
  for deg in 1..maxDegree:
    bucketOffset[deg] += bucketOffset[deg - 1]
  for rowIdx in 0..<rowCount:
    let deg = int(rowStart[rowIdx + 1] - rowStart[rowIdx])
    rowOrder[bucketOffset[deg]] = int32(rowIdx)
    inc bucketOffset[deg]

  var remainingRows = rowCount
  var coverCount = 0
  var removedRows: array[maxRows, int32]

  while remainingRows > 0:
    var chosenCol = -1'i32
    for orderIdx in 0..<rowCount:
      let rowIdx = int(rowOrder[orderIdx])
      if (activeRows[rowIdx shr 6] and (1'u64 shl uint(rowIdx and 63))) == 0'u64:
        continue
      let savedWitness = witnessRow[rowIdx]
      if savedWitness >= 0:
        if (activeRows[int(savedWitness) shr 6] and (1'u64 shl uint(int(savedWitness) and 63))) != 0'u64 and
           colDegree[witnessCol[rowIdx]] == witnessDegree[rowIdx]:
          continue

      let sliceStart = int(rowStart[rowIdx])
      let sliceStop = int(rowStart[rowIdx + 1])
      if sliceStop - sliceStart == 1:
        chosenCol = rowColsFlat[sliceStart]
        break

      var dominantCol = rowColsFlat[sliceStart]
      var bestDegree = colDegree[dominantCol]
      for k in (sliceStart + 1)..<sliceStop:
        let colIdx = rowColsFlat[k]
        let deg = colDegree[colIdx]
        if deg > bestDegree:
          bestDegree = deg
          dominantCol = colIdx

      var dominatesAll = true
      var blockingRow = -1'i32
      for k in sliceStart..<sliceStop:
        let colIdx = rowColsFlat[k]
        if colIdx == dominantCol or colDegree[colIdx] == 0: continue
        for wordIdx in 0..<wordCount:
          let uncovered = colMask[colIdx][wordIdx] and not colMask[dominantCol][wordIdx]
          if uncovered != 0'u64:
            dominatesAll = false
            blockingRow = int32((wordIdx shl 6) + countTrailingZeroBits(uncovered))
            break
        if not dominatesAll: break

      if dominatesAll:
        chosenCol = dominantCol
        break
      else:
        witnessCol[rowIdx] = dominantCol
        witnessRow[rowIdx] = blockingRow
        witnessDegree[rowIdx] = bestDegree

    if chosenCol < 0:
      var fallbackCol = 0'i32
      for colIdx in 1..<colCount:
        if colDegree[colIdx] > colDegree[fallbackCol]:
          fallbackCol = int32(colIdx)
      chosenCol = fallbackCol

    inc coverCount
    var removedCount = 0
    for wordIdx in 0..<wordCount:
      var wordBits = colMask[chosenCol][wordIdx]
      if wordBits != 0'u64:
        activeRows[wordIdx] = activeRows[wordIdx] and not wordBits
        while wordBits != 0'u64:
          let bitPos = countTrailingZeroBits(wordBits)
          wordBits = wordBits and (wordBits - 1'u64)
          removedRows[removedCount] = int32((wordIdx shl 6) + bitPos)
          inc removedCount
    remainingRows -= removedCount
    for i in 0..<removedCount:
      let rowIdx = int(removedRows[i])
      let rowWord = rowIdx shr 6
      let clearMask = not (1'u64 shl uint(rowIdx and 63))
      let sliceStart = int(rowStart[rowIdx])
      let sliceStop = int(rowStart[rowIdx + 1])
      for k in sliceStart..<sliceStop:
        let colIdx = int(rowColsFlat[k])
        colMask[colIdx][rowWord] = colMask[colIdx][rowWord] and clearMask
        dec colDegree[colIdx]

  return coverCount
```

Bitsets hold the rows each street crosses. A dominant column covers a whole row group. Removal clears row bits and lowers degrees.

**Case driver.**

```nim
readAllInput()
let caseCount = nextSigned()
for _ in 0..<caseCount:
  let sectionCount = nextSigned()
  var sectionLengths = newSeq[int](sectionCount)
  for i in 0..<sectionCount:
    sectionLengths[i] = nextSigned()

  var vertices = newSeq[Point](sectionCount + 1)
  var posX = 0
  var posY = 0
  vertices[0] = Point(x: 0, y: 0)
  for i in 0..<sectionCount:
    if (i and 1) == 0: posY += sectionLengths[i]
    else: posX += sectionLengths[i]
    vertices[i + 1] = Point(x: posX, y: posY)

  let verticalStreets = extractAxisSegments(vertices, false)
  let horizontalStreets = extractAxisSegments(vertices, true)
  let verticalCount = verticalStreets.len
  let horizontalCount = horizontalStreets.len

  var horizontalAdj = newSeq[seq[int32]](horizontalCount)
  var verticalAdj = newSeq[seq[int32]](verticalCount)
  for i in 0..<verticalCount:
    let streetX = verticalStreets[i].axisCoord
    let streetLow = verticalStreets[i].lowCoord
    let streetHigh = verticalStreets[i].highCoord
    for j in 0..<horizontalCount:
      if horizontalStreets[j].lowCoord <= streetX and streetX <= horizontalStreets[j].highCoord and
         streetLow <= horizontalStreets[j].axisCoord and horizontalStreets[j].axisCoord <= streetHigh:
        verticalAdj[i].add(int32(j))
        horizontalAdj[j].add(int32(i))

  let verticalCover = solveChordalSetCover(horizontalCount, verticalCount, horizontalAdj)
  let horizontalCover = solveChordalSetCover(verticalCount, horizontalCount, verticalAdj)
  appendInt(verticalCover + horizontalCover)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
  outputBuffer.setLen(0)
```

The wall walk yields both street sets. Pairwise tests build the crossing graph. Two covers add, and one line holds the answer.

## Complexity

Street extraction and the crossing graph dominate.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total numbers) | O(Input size) |
| Street extraction | O(S^2 log S) | O(S) |
| Crossing graph | O(V * H) | O(V * H) |
| Greedy cover | O(S^3 / 64) | O(S^2 / 64) |

S is the street count, V vertical and H horizontal.

| Measure | Bound |
| --- | --- |
| Time | O(S^3 / 64) worst case |
| Space | O(S^2 / 64) |

Bitsets keep the cover loop compact.

Testing every street subset would grow exponentially with the wall size.
