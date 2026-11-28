# HARDQ — Hard Question (SPOJ)

<https://www.spoj.com/problems/HARDQ/>

## Problem

Decide whether some of the given rectangles cover a polygon exactly, with no land bought outside it. The rectangles are axis-parallel and mutually disjoint.

Input holds several cases separated by blank lines. Each case starts with N M, then N vertex coordinate lines, then M lines with two opposite corners of a rectangle. The case N=0, M=0 ends the input.

Output holds one line per case: YES when such a subset exists, otherwise NO.

The bounds from the statement:

| Item | Bound |
|---|---|
| Vertices N | at most 3000 |
| Rectangles M | at most 3000 |
| Coordinate size | within 10000 in absolute value in the IPSC data noted on the statement |
| Judge limit | 5 s, 1536 MB |

The vertex and rectangle counts drive the work; the area test removes any subset search.

The sample case:

```
4 2
0 0
0 2
2 2
2 0
1 0 0 2
1 0 2 2

3 1
0 0
2 2
2 0
0 0 1 1

0 0
```

```
YES
NO
```

The first park splits into two plots. The second park has a diagonal edge, so NO.

## Idea

Think of the park as a floor and the plots as whole tiles. A tile that pokes outside is useless. The kept tiles must fill the floor.

The program marks each plot that lies wholly inside the park, then adds the areas of those plots. Because the plots do not overlap, the sum never exceeds the park area. The answer is YES exactly when the sum equals the park area. A diagonal park edge fails at once, since no union of axis-parallel rectangles can produce it.

Each plot costs N edge checks and one center test, so a case costs O(MN). Trying every subset costs O(2^M), which M = 3000 rules out.

Area turns a subset search into one pass over the plots.

## Why It Works

1. A union of axis-parallel rectangles has only horizontal and vertical boundary edges. A diagonal park edge therefore makes an exact cover impossible.
2. A plot lies inside the park when no park edge crosses its open interior and its center lies inside the park. Border contact is allowed, since neighboring plots may share an edge.
3. Kept plots are disjoint subsets of the park, so their areas add without overlap and their sum stays at most the park area.
4. If the two areas match, choosing every kept plot covers the park. If they differ, no subset can match the area, so the answer is NO.

The main terms and formulas:

| Term | Meaning |
|---|---|
| `doubledParkArea` | edge sum that equals twice the signed park area |
| `2 * firstX + 1` | left side of the open plot, expressed in doubled coordinates |
| `plotAreaTotal` | sum of the areas of the kept plots |
| `doubledParkArea == 2 * plotAreaTotal` | exact cover test after the sign is made positive |

Doubling coordinates keeps every geometry test in integers, and the area equality decides the case.

A script traced the sample park with its two plots:

```
edge (0, 0)->(0, 2): 0
edge (0, 2)->(2, 2): 8
edge (2, 2)->(2, 0): 0
edge (2, 0)->(0, 0): 0
doubled park area 8 park area 4
plot (0, 0, 1, 2) area 2 clipped 2 kept True
plot (1, 0, 2, 2) area 2 clipped 2 kept True
kept total 4
answer YES
```

Each plot covers half the park, so the total matches the park area and the sample prints YES.

## Code

**Input and output plumbing.** The whole stream is read once, and output leaves in blocks.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ': pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return sign * value
```

The scan position survives across calls because it is a var parameter. The sign branch keeps negative coordinates intact. One buffer caps memory at 128 KiB.

**Border overlap.** Two axis-parallel segments are compared by their projections.

```nim
proc rangesOverlap(firstLow, firstHigh, secondLow, secondHigh: int): bool =
  return firstLow <= secondHigh and secondLow <= firstHigh

proc sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                    sideX1, sideY1, sideX2, sideY2: int): bool =
  var edgeLowX = edgeX1
  var edgeHighX = edgeX2
  if edgeLowX > edgeHighX:
    let swapValue = edgeLowX
    edgeLowX = edgeHighX
    edgeHighX = swapValue
  var edgeLowY = edgeY1
  var edgeHighY = edgeY2
  if edgeLowY > edgeHighY:
    let swapValue = edgeLowY
    edgeLowY = edgeHighY
    edgeHighY = swapValue
  var sideLowX = sideX1
  var sideHighX = sideX2
  if sideLowX > sideHighX:
    let swapValue = sideLowX
    sideLowX = sideHighX
    sideHighX = swapValue
  var sideLowY = sideY1
  var sideHighY = sideY2
  if sideLowY > sideHighY:
    let swapValue = sideLowY
    sideLowY = sideHighY
    sideHighY = swapValue
  if edgeLowX == edgeHighX:
    if sideLowX == sideHighX: return false
    return rangesOverlap(edgeLowY, edgeHighY, sideLowY, sideHighY) and
           edgeLowX >= sideLowX and edgeLowX <= sideHighX
  else:
    if sideLowY == sideHighY: return false
    return rangesOverlap(edgeLowX, edgeHighX, sideLowX, sideHighX) and
           edgeLowY >= sideLowY and edgeLowY <= sideHighY
```

Doubled park coordinates are even; open plot sides use odd coordinates. A park edge on a plot border therefore cannot be mistaken for a crossing. Vertical and horizontal cases each use one projection test.

**Center test.** A ray to the right counts park edges above and below the query point.

```nim
proc pointInsidePark(queryX, queryY: int, vertexX, vertexY: seq[int],
                     vertexCount: int): bool =
  var inside = false
  for i in 0..<vertexCount:
    let nextIndex = (i + 1) mod vertexCount
    let lowY = 2 * vertexY[i]
    let highY = 2 * vertexY[nextIndex]
    if (lowY > queryY) != (highY > queryY):
      if queryX < 2 * vertexX[i]:
        inside = not inside
  return inside
```

The half-open rule skips horizontal edges, so no division occurs. Each crossed vertical edge flips the state once. Doubled query coordinates avoid fractions at plot centers.

**Case read and park area.** The driver reads one case and measures the park in integer arithmetic.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

while true:
  let vertexCount = nextInt(inputData, scanPos)
  let plotCount = nextInt(inputData, scanPos)
  if vertexCount == 0 and plotCount == 0: break

  var vertexX = newSeq[int](vertexCount + 1)
  var vertexY = newSeq[int](vertexCount + 1)
  for i in 0..<vertexCount:
    vertexX[i] = nextInt(inputData, scanPos)
    vertexY[i] = nextInt(inputData, scanPos)
  vertexX[vertexCount] = vertexX[0]
  vertexY[vertexCount] = vertexY[0]

  var doubledParkArea: int64 = 0
  var axisAligned = true
  for i in 0..<vertexCount:
    doubledParkArea += int64(vertexX[i + 1] - vertexX[i]) *
                       int64(vertexY[i + 1] + vertexY[i])
    if vertexX[i + 1] != vertexX[i] and vertexY[i + 1] != vertexY[i]:
      axisAligned = false
```

The closing vertex is copied to index vertexCount, so edge loops stay simple. A non-axis-parallel park clears the axisAligned flag. The sign flip makes the area positive before comparison.

**Plot filter and decision.** Each plot is tested against every park edge, then by area.

```nim
  var plotAreaTotal: int64 = 0
  for j in 0..<plotCount:
    var firstX = nextInt(inputData, scanPos)
    var firstY = nextInt(inputData, scanPos)
    var secondX = nextInt(inputData, scanPos)
    var secondY = nextInt(inputData, scanPos)
    if firstX > secondX:
      let swapValue = firstX
      firstX = secondX
      secondX = swapValue
    if firstY > secondY:
      let swapValue = firstY
      firstY = secondY
      secondY = swapValue
    if not axisAligned: continue

    var plotInside = true
    for i in 0..<vertexCount:
      let edgeX1 = 2 * vertexX[i]
      let edgeY1 = 2 * vertexY[i]
      let edgeX2 = 2 * vertexX[i + 1]
      let edgeY2 = 2 * vertexY[i + 1]
      if sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                        2 * firstX + 1, 2 * firstY + 1,
                        2 * secondX - 1, 2 * firstY + 1) or
         sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                        2 * firstX + 1, 2 * firstY + 1,
                        2 * firstX + 1, 2 * secondY - 1) or
         sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                        2 * secondX - 1, 2 * secondY - 1,
                        2 * secondX - 1, 2 * firstY + 1) or
         sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                        2 * secondX - 1, 2 * secondY - 1,
                        2 * firstX + 1, 2 * secondY - 1):
        plotInside = false
        break
    if plotInside:
      plotInside = pointInsidePark(firstX + secondX, firstY + secondY,
                                   vertexX, vertexY, vertexCount)
    if plotInside:
      plotAreaTotal += int64(secondX - firstX) * int64(secondY - firstY)

  if doubledParkArea < 0: doubledParkArea = -doubledParkArea
  if doubledParkArea == 2 * plotAreaTotal and axisAligned:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
```

Corners are normalized before any test. Four open plot sides are checked per park edge, and the center test runs only when no border was crossed. Only kept plots add their area.

**Tail flush.** The final write emits any remaining bytes.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

The tail covers a short last block, and setLen 0 releases the buffer contents.

## Complexity

The cost sits in the per-plot edge loop.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Park setup | N edge products and axis checks | two sequences of N integers |
| Plot filter | four side tests and one ray test per plot | constant extra space |
| Decision and output | one comparison, one buffered write per case | 128 KiB block |

The park sequences dominate space; the input buffer and output block are bounded by their own sizes.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(MN) per case |
| Space | O(N) plus the input buffer |

A subset search costs O(2^M) time, which M = 3000 rules out.

One area comparison replaces the entire subset search.
