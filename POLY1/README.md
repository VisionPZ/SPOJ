## Problem

Read a convex polygon with vertices numbered clockwise and one triangulation of it. Choose three polygon vertices and form their triangle. Print the largest number of triangulation triangles whose interiors meet that triangle's interior.

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded in the statement |
| Vertices per polygon | 3 to 1000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The vertex bound drives the design, since the number of vertex triples grows cubically.

## Idea

Treat an elementary triangle as three cuts on the polygon boundary. Those cuts split the polygon into three closed arcs. A triangulation triangle misses the chosen triangle only when all its vertices lie in one arc. Count those confined triangles for every arc, then pick the three cuts with the smallest confined total.

The program builds one arc-count table in O(n²) and scans all triples in O(n³).

## Why It Works

The vertices lie in convex position. Two triangles from this polygon have disjoint interiors in one case only. One vertex triple lies inside a closed arc between consecutive vertices of the other. The three arcs of the chosen triangle cover the whole boundary. Each triangulation triangle therefore either lies in one arc or meets the chosen triangle. Subtracting the confined count from n - 2 gives the number met.

For a triangle with sorted vertices u < v < w and a start vertex x, rotate positions by (vertex - x) mod n. The triangle fits arc [x,y] exactly when the largest rotated position is at most (y - x) mod n. The program fills a table f[x,y] with those counts using a difference row per start x.

| Elementary triangle | Confined in [a,b] | Confined in [b,c] | Confined in [c,a] | Triangles met |
| --- | --- | --- | --- | --- |
| (1,3,5) | none | none | none | 4 |
| (0,1,3) | none | none | (0,4,5) | 3 |

The sample polygon has six vertices and four triangulation triangles, so the first row reaches the full count of four.

## Code

The pragmas keep the program fast in a build without release flags. The input pass reads every line into one buffer and scans integers by digit. Blank lines between cases need no special handling.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The output buffer flushes after 256 KiB, so one case never causes many writes. The scanner skips every non-digit byte.

Sorting each triangle puts its three vertices in clockwise order for the arc updates.

```nim
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
```

The loop reads exactly n - 2 triangles. Three comparisons sort three values without a library call.

Each start vertex x can sit in any of the three gaps between u, v and w. The four ranges cover those gaps and the wrap around vertex n - 1.

```nim
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
```

The extra column holds the wrap marker. Omitting the first two gaps undercounts arcs that wrap past vertex n - 1.

A running sum turns each difference row into f[x,y]. The table uses one stride of n + 1 integers per row.

```nim
  for j in 0..<vertexCount:
    let rowBase = j * stride
    var running = 0
    for k in 0..<vertexCount:
      running += arcCounts[rowBase + k]
      arcCounts[rowBase + k] = running
```

The loop visits every cell once. Prefix sums over one row cost O(n).

The scan tries each cut pair a and b, then each third cut c. Arc counts never fall below zero, so the two breaks are safe.

```nim
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
```

The loops cover C(n,3) triples. Each step does two table reads, one add and one comparison.

## Complexity

Building the arc table reads n - 2 triangles and touches O(n) start positions per triangle, then prefix sums n rows. The scan visits O(n³) triples. Output costs one line per case.

The table holds n rows of n + 1 integers, so space is O(n²). The whole solution runs in O(n² + n³) time and O(n²) space per case. A geometric check of every triangle pair against every vertex triple costs O(n⁴) instead.
