# POLY1 — Polygon (SPOJ)
<https://www.spoj.com/problems/POLY1/>

## Problem

A convex polygon is cut into elementary triangles. Choose one more triangle whose corners are polygon vertices. How many triangles of the given triangulation can it intersect?

Two triangles intersect when their interiors share a point. You need the largest possible count over all choices of the three corners.

Input: the first integer is t, the number of cases; cases are separated by a blank line. Each case gives n and then n − 2 triangles, each as three vertex numbers. Output: one integer per case, the maximum intersection count.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | from the input |
| Vertices n | 3 to 1000 |
| Triangulation triangles | n − 2 |
| Vertex numbering | 0 to n − 1, clockwise |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The sample uses a hexagon with four triangles:

```
1
6
0 1 2
2 3 4
0 4 5
0 2 4
```

```
4
```

The elementary triangle with corners 1, 3, and 5 intersects all four.

## Idea

Count the triangles a chosen triangle misses, then subtract from the total. Picture drawing a triangle on a pie chart and counting the slices wholly tucked inside its three arcs.

The program first builds a table `arcCounts`. Entry (j, k) counts triangulation triangles whose vertices all lie on the clockwise arc from vertex j to vertex k. Each input triangle adds one unit to three row intervals, and a prefix pass turns those differences into counts.

For every triple a < b < c, the hidden triangles are `arcCounts[a][b] + arcCounts[b][c] + arcCounts[c][a]`. Minimizing that sum maximizes intersections; the answer is (n − 2) minus the minimum.

Building the table costs O(n²), and the triple loop costs O(n³) with early breaks. Checking every elementary triangle against every triangulation triangle costs O(n⁴).

Takeaway: a prefix-sum table reduces each triple to three integer lookups.

## Why It Works

Four facts justify the subtraction.

1. An elementary triangle with corners a < b < c splits the polygon into three arcs: a → b, b → c, and c → a. These regions cover the polygon and meet only on the triangle edges.
2. A triangulation triangle misses the chosen triangle exactly when all three of its vertices lie in one arc. Otherwise its interior crosses a side of the chosen triangle.
3. `arcCounts[j][k]` counts the triangles inside arc j → k. The difference updates mark intervals of rows, and the prefix pass converts each row of differences into exact counts.
4. For a triple, the three arc counts add without overlap, so their sum is the number of hidden triangles. Minimizing it over all triples maximizes the intersected count.

These are the quantities in one triple check:

| Term | Meaning |
| --- | --- |
| `triMin`, `triMid`, `triMax` | sorted corners of an input triangle |
| `stride` | row width, n + 1 |
| `arcCounts[j][k]` | triangles wholly inside the arc from j to k |
| `fixedCost` | arcCounts[a][b] for the current triple |
| `partialCost` | fixedCost plus arcCounts[b][c] |
| `confined` | partialCost plus arcCounts[c][a] |
| `bestConfined` | smallest confined value found |

A script evaluates triples for the sample triangulation:

```
triangles: [(0, 1, 2), (2, 3, 4), (0, 4, 5), (0, 2, 4)]
  (1,3,5): arc[a][b]=0 arc[b][c]=0 arc[c][a]=0 total=0
  (0,2,4): arc[a][b]=1 arc[b][c]=1 arc[c][a]=1 total=3
  (0,1,2): arc[a][b]=0 arc[b][c]=0 arc[c][a]=3 total=3
  (2,3,4): arc[a][b]=0 arc[b][c]=0 arc[c][a]=3 total=3
  (0,4,5): arc[a][b]=3 arc[b][c]=0 arc[c][a]=0 total=3
  (0,1,3): arc[a][b]=0 arc[b][c]=0 arc[c][a]=1 total=1
bestConfined=0 answer=4
```

The triple 1, 3, 5 hides nothing, so all four triangles are intersected. No geometry with floating point is needed.

## Code

**Input.** One buffer holds the cases, and the scanner skips blank lines.

```nim
{.push optimization: speed.}
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
```

The scanner treats blank lines like any other separator. Vertex triples are read in input order. Cost is one pass over the input bytes.

**Output.** One buffer collects answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush triggers every `flushBlockBytes` bytes. No write occurs during the triple loop. The cost is one pass over the answer text.

**Driver.** Each case builds the arc table, then searches all triples.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let triangleCount = vertexCount - 2
  var triMin = newSeq[int](triangleCount)
  var triMid = newSeq[int](triangleCount)
  var triMax = newSeq[int](triangleCount)
  for i in 0..<triangleCount:
    var firstVertex = nextInt(inputData, scanPos)
    var secondVertex = nextInt(inputData, scanPos)
    var thirdVertex = nextInt(inputData, scanPos)
    if firstVertex > secondVertex:
      let tmpValue = firstVertex
      firstVertex = secondVertex
      secondVertex = tmpValue
    if secondVertex > thirdVertex:
      let tmpValue = secondVertex
      secondVertex = thirdVertex
      thirdVertex = tmpValue
    if firstVertex > secondVertex:
      let tmpValue = firstVertex
      firstVertex = secondVertex
      secondVertex = tmpValue
    triMin[i] = firstVertex
    triMid[i] = secondVertex
    triMax[i] = thirdVertex

  let stride = vertexCount + 1
  var arcCounts = newSeq[int](vertexCount * stride)
  for i in 0..<triangleCount:
    let lowVertex = triMin[i]
    let midVertex = triMid[i]
    let highVertex = triMax[i]
    for j in lowVertex + 1 .. midVertex:
      let rowBase = j * stride
      arcCounts[rowBase + lowVertex] += 1
      arcCounts[rowBase + j] -= 1
    for j in midVertex + 1 .. highVertex:
      let rowBase = j * stride
      arcCounts[rowBase + midVertex] += 1
      arcCounts[rowBase + j] -= 1
    for j in highVertex + 1 ..< vertexCount:
      let rowBase = j * stride
      arcCounts[rowBase + highVertex] += 1
      arcCounts[rowBase + j] -= 1
    for j in 0 .. lowVertex:
      let rowBase = j * stride
      arcCounts[rowBase + highVertex] += 1
      arcCounts[rowBase + vertexCount] -= 1
      if j > 0:
        arcCounts[rowBase] += 1
        arcCounts[rowBase + j] -= 1

  for j in 0..<vertexCount:
    let rowBase = j * stride
    var running = 0
    for k in 0..<vertexCount:
      running += arcCounts[rowBase + k]
      arcCounts[rowBase + k] = running

  var bestConfined = high(int)
  for a in 0..<vertexCount:
    let rowA = a * stride
    for b in a + 1 ..< vertexCount:
      let fixedCost = arcCounts[rowA + b]
      if fixedCost >= bestConfined:
        break
      let rowB = b * stride
      for c in b + 1 ..< vertexCount:
        let partialCost = fixedCost + arcCounts[rowB + c]
        if partialCost >= bestConfined:
          break
        let confined = partialCost + arcCounts[c * stride + a]
        if confined < bestConfined:
          bestConfined = confined

  appendOutput($(triangleCount - bestConfined))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Sorting each triangle's three corners makes the arc ranges well defined. `arcCounts[rowBase + vertexCount]` is a sentinel column for wrapping intervals. Both `break` statements prune triples that cannot beat the best value.

## Complexity

Table building and triple scanning carry the work.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Sort triangle corners | O(n) | O(n) |
| Difference updates | O(n²) total | O(n²) |
| Prefix pass | O(n²) | O(n²) |
| Triple search | O(n³) worst case | O(1) |
| Output | O(cases) | O(block size) |

The triple search dominates with O(n³) time; the table costs O(n²) space.

| Measure | Big O |
| --- | --- |
| Time per case | O(n³) |
| Total time | O(sum of n³ over cases) |
| Working space | O(n²) |

Checking each candidate triangle against every triangulation triangle costs O(n⁴) time.
