# MMINMAX — Minimax Triangulation (SPOJ)

<https://www.spoj.com/problems/MMINMAX/>

## Problem

Cut a polygon into triangles so the largest triangle is as small as possible, then report that largest area with one decimal digit.

The input starts with the scenario count. Each scenario gives the vertex count m and then m vertex pairs in border order. Output one line per scenario with the minimax area.

| item | bound |
|---|---|
| scenarios | positive integer |
| vertices m | 3 to 49 |
| coordinates x and y | 0 to 10000 |
| judge limit | 1000 ms, 1536 MB |

A triangulation uses m minus three chords and creates m minus two triangles. The chord set must not cross itself inside the polygon.

Sample input:

```
1
6
7 0
6 2
9 5
3 5
0 3
1 1
```

Sample output:

```
9.0
```

## Idea

Cutting a polygon is like sharing a cake so the biggest slice is as small as possible: each candidate cut leaves two smaller pieces to balance.

Any triangulation of a vertex chain splits at one triangle and two smaller chains. An interval DP stores the best worst-triangle area for every chain.

Each transition tries one split and takes the maximum of three areas. It then keeps the smallest maximum. Listing every triangulation grows by Catalan numbers and cannot finish at m = 49.

Try every split of every chain, keep the best maximum, and print it as halves.

## Why It Works

1. A chain from vertex i to vertex j with no interior vertices needs zero cuts.
2. Choosing split k creates triangle (i, k, j) and the chains (i, k) and (k, j).
3. The worst triangle of that choice is the maximum of three values.
4. The DP keeps the smallest such maximum over all k.
5. Twice the area is an integer cross product, so output has only .0 or .5.

| term | meaning |
|---|---|
| `bestMaxAreas` | least worst area for each vertex chain |
| `doubledTriangleArea` | twice the area of one triangle |
| `spanLength` | number of edges in the current chain |
| `splitVertex` | vertex chosen as the triangle tip |
| `answerDoubled` | twice the final minimax area |
| `largeArea` | sentinel for an unprocessed chain |

The names above match the driver, so each fact maps to one line of code.

For the sample, the chain from vertex 1 to vertex 5 has value 18 in doubled units. Splitting at vertex 1 gives triangle (0, 1, 5) with doubled area 11.

The remaining chain has value 18. Splitting elsewhere gives a larger maximum, so the answer is 18 / 2 = 9.0.

Twice an area stays integral because coordinates are integers. The sentinel is far larger than any triangle in a 10000 by 10000 box.

## Code

**Input and area helper.** The reader stores vertices and defines a cross-product area.

```nim
const flushBlockBytes = 1 shl 17
const largeArea = int64(1000000000000000000)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc doubledTriangleArea(firstX: int64, firstY: int64, secondX: int64, secondY: int64,
                         thirdX: int64, thirdY: int64): int64 =
  let crossProduct = (secondX - firstX) * (thirdY - firstY) -
                     (secondY - firstY) * (thirdX - firstX)
  if crossProduct < 0:
    return -crossProduct
  return crossProduct
```

Vertex pairs arrive in border order.
The area helper returns twice the true area.
The absolute value removes orientation concerns.

**Interval DP and output.** Chains grow by span and try every split vertex.

```nim
let scenarioCount = nextInt(inputData, scanPos)
for scenarioIndex in 0 .. scenarioCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  var vertexXs = newSeq[int64](vertexCount)
  var vertexYs = newSeq[int64](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    vertexXs[vertexIndex] = int64(nextInt(inputData, scanPos))
    vertexYs[vertexIndex] = int64(nextInt(inputData, scanPos))
  var bestMaxAreas = newSeq[int64](vertexCount * vertexCount)
  for stateIndex in 0 .. vertexCount * vertexCount - 1:
    bestMaxAreas[stateIndex] = largeArea
  for leftVertex in 0 .. vertexCount - 2:
    bestMaxAreas[leftVertex * vertexCount + leftVertex + 1] = 0
  for spanLength in 2 .. vertexCount - 1:
    for leftVertex in 0 .. vertexCount - spanLength - 1:
      let rightVertex = leftVertex + spanLength
      var smallestMaximum = largeArea
      for splitVertex in leftVertex + 1 .. rightVertex - 1:
        var candidate = doubledTriangleArea(
          vertexXs[leftVertex], vertexYs[leftVertex],
          vertexXs[splitVertex], vertexYs[splitVertex],
          vertexXs[rightVertex], vertexYs[rightVertex])
        let leftMaximum = bestMaxAreas[leftVertex * vertexCount + splitVertex]
        if leftMaximum > candidate:
          candidate = leftMaximum
        let rightMaximum = bestMaxAreas[splitVertex * vertexCount + rightVertex]
        if rightMaximum > candidate:
          candidate = rightMaximum
        if candidate < smallestMaximum:
          smallestMaximum = candidate
      bestMaxAreas[leftVertex * vertexCount + rightVertex] = smallestMaximum
  let answerDoubled = bestMaxAreas[vertexCount - 1]
  let wholePart = answerDoubled div 2
  if answerDoubled mod 2 == 0:
    appendOutput($wholePart & ".0\n")
  else:
    appendOutput($wholePart & ".5\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Adjacent vertices form a chain with area zero.
Shorter spans are ready before longer ones need them.
The final entry covers the whole polygon.

## Complexity

The DP fills one entry per chain and tries every split for it.

| phase | time | space |
|---|---|---|
| input read | one pass over m vertices | two coordinate arrays |
| interval DP | O(m cubed) split trials | one table of m squared entries |
| output | one line per scenario | block buffer |

The table shows that the split loop dominates for large m.

| measure | Big O |
|---|---|
| time per scenario | O(m cubed) |
| space per scenario | O(m squared) |

At m = 49 the DP runs about 117000 split trials.
Enumerating all triangulations would produce Catalan-sized output and time out.
Interval DP reaches the same optimum with one entry per chain.
