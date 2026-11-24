## Problem

Read an axis-aligned polygon and a rectangular window. The polygon interior is red; its boundary is not. Print the number of disconnected red pieces visible through the window.

| Quantity | Bound |
| --- | --- |
| Coordinates | 0 to 10000 |
| Polygon vertices | 4 to 5000 |
| Window corners | 0 to 10000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The vertex count drives the work, since the coordinate range is small.

## Idea

Sweep horizontal bands from the bottom of the window to the top. In each band, pair the x coordinates of active vertical edges. Clip the pairs to the window. Join intervals that overlap the band below with union-find. Testing every unit square would touch up to 100 million cells per case.

Cost per band: one pass over at most 5000 vertical edges.

## Why It Works

A vertical edge crosses a band when its lower end is at or below the band bottom. Its upper end must be at or above the band top. A horizontal line crosses a simple polygon an even number of times, so pairing consecutive crossings gives the inside intervals. Several crossings at one x cancel in pairs, so only an odd count matters. Two bands join where their intervals overlap with positive length; one shared point does not join open interiors.

The count update is `componentCount = componentCount + newStarts - (referencedCount - usedRoots)`.

- `newStarts` counts current intervals with no interval below, so each starts a new piece.
- `referencedCount` counts distinct old pieces touched from below.
- `usedRoots` counts those pieces after this band merges them.
- The difference `referencedCount - usedRoots` is the number of merges.

The generator verified this trace for a U-shaped polygon of 18 vertices and the window `(0,3,4,1)`:

| Band | Crossings | Intervals | Pieces |
| --- | --- | --- | --- |
| (1,2) | 0 1 3 4 | (0,1), (3,4) | 2 |
| (2,3) | 0 1 3 4 | (0,1), (3,4) | 2 |

Both pieces continue upward, so the answer is 2.

## Code

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

The read loop ends at end of input, and the scanner skips the empty lines between cases. A non-negative input keeps the scanner free of sign handling. The output buffer flushes once per block; one answer costs O(1) amortized time.

```nim
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

There are at most 5002 band boundaries. A version stamp clears the mark array in O(1) per case. The insertion sort that follows touches each boundary at most once in the common case.

```nim
  edgeX.setLen(0)
  edgeLo.setLen(0)
  edgeHi.setLen(0)
  for i in 0..<vertexCount:
    let j = (i + 1) mod vertexCount
    if vertX[i] == vertX[j] and vertY[i] != vertY[j]:
      edgeX.add vertX[i]
      edgeLo.add (if vertY[i] < vertY[j]: vertY[i] else: vertY[j])
      edgeHi.add (if vertY[i] < vertY[j]: vertY[j] else: vertY[i])
```

The vertex loop runs `vertexCount` times and collects at most half as many vertical edges. Sorting edges by x once lets each band read them in order. The wrap-around index closes the polygon.

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
```

The loop visits every vertical edge once per band. An even group count leaves no crossing, which avoids zero-width intervals. Pairing consecutive crossings gives one inside interval per pair in O(1) per crossing.

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

Both loops are bounded by the pieces alive in one band. Ending pieces are kept in the total, so a band with no intervals never erases an answer. The union-find arrays hold only current labels, which keeps the space small.

## Complexity

Reading input costs O(total tokens) once. Per case, band and edge sorting cost O(n^2) in the worst case. The sweep visits at most O(n) edges in each of O(n) bands. The sweep also costs O(n^2). Space is O(n) per case plus the single input buffer. A unit-square flood fill would cost O(10^8) cells per case.
