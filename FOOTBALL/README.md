## Problem

Read a simple closed polygon drawn along the edges of a classic football. The ball has 12 black pentagons and 20 white hexagons. Each case gives the polygon vertex count and the number of green pieces at each vertex. The closing edge joins two hexagons. Print the counts of black pieces, white pieces, and green pieces on the whole ball.

The input bounds follow from the ball and the statement.

| Item | Bound |
| --- | --- |
| Polygon vertices per case | 6 to 60 |
| Green pieces at a vertex | 1 or 2 |
| Closing edge | joins two hexagons |
| Time limit | 100 ms |
| Memory limit | 1536 MB |

A polygon visits each ball vertex at most once, so a case stays small.

## Idea

Euler's formula on the green disk counts green pentagons from the sum of vertex values, and a corner count gives the green hexagons. A three-state walk supplies that corner count in one pass, so each vertex costs O(1). Rebuilding the ball needs geometry the input does not give.

## Why It Works

Every ball vertex touches one pentagon and two hexagons. The polygon cuts the sphere into two disks. Let V, E, F count the green disk's vertices, edges and faces. Euler gives V - E + F = 1. Define S as the sum of vertex values, P as the green pentagons, and H as the green hexagons. Let Vi and Ei count interior vertices and interior edges.

Each term below follows from one count on the green disk.

- 5P + 6H = 2Ei + n sums face edges; a boundary edge is seen once.
- E = Ei + n = (5P + 6H + n)/2 isolates all green edges.
- 5P + 6H = 3Vi + S sums face corners; a boundary vertex gives ai corners.
- V = Vi + n = (5P + 6H - S)/3 + n isolates all green vertices.
- Substituting V, E and F = P + H into Euler gives P = 2S - 3n + 6.

The complement gives the same equation, so count pentagon corners instead. Let Q be the number of polygon vertices where the pentagon is green. Then 5P = Vi + Q and 6H = 2Vi + S - Q, so H = (10P + S - 3Q)/6.

The closing edge joins two hexagons, so the walk starts in the HH state. At each vertex the incoming edge type and ai fix the next state and tell whether Q grows.

The sample gives this trace. The state column describes the incoming edge.

| Vertex | ai | Incoming edge state | Q |
| --- | --- | --- | --- |
| 1 | 1 | HH, green face hexagon | 0 |
| 2 | 2 | PH, green face hexagon | 0 |
| 3 | 1 | PH, green face hexagon | 0 |
| 4 | 2 | HH, green face hexagon | 1 |
| 5 | 1 | PH, green face pentagon | 2 |
| 6 | 2 | PH, green face pentagon | 3 |
| 7 | 1 | HH, green face hexagon | 3 |
| 8 | 1 | PH, green face hexagon | 3 |
| 9 | 1 | HH, green face hexagon | 3 |
| 10 | 2 | PH, green face hexagon | 3 |
| 11 | 2 | PH, green face hexagon | 3 |
| 12 | 1 | PH, green face hexagon | 3 |
| 13 | 1 | HH, green face hexagon | 3 |
| 14 | 1 | PH, green face hexagon | 3 |
| 15 | 1 | HH, green face hexagon | 3 |
| 16 | 2 | PH, green face hexagon | 3 |
| 17 | 2 | PH, green face hexagon | 3 |
| 18 | 2 | PH, green face hexagon | 3 |
| 19 | 1 | PH, green face hexagon | 3 |
| 20 | 1 | HH, green face hexagon | 3 |
| 21 | 1 | PH, green face hexagon | 3 |

The walk ends in the HH state, and S = 29, P = 1, Q = 3 and H = 5 give 11 15 6.

## Code

The state set has three values, so the case statement covers every branch.

```
type BoundaryState = enum
  statePentagonFace, stateHexagonFace, stateHexagonEdge

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
```

These constants name the three walk states, the digit base and the flush threshold.

The input lives in one buffer, and the scanner walks that buffer by index.

```
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  let dataLength = data.len
  while position < dataLength and (data[position] < '0' or data[position] > '9'):
    position += 1
  result = 0
  while position < dataLength and data[position] >= '0' and data[position] <= '9':
    result = result * 10 + (int(data[position]) - firstDigitValue)
    position += 1
```

readLine runs once per input line and appends to one buffer. The scanner skips separators and consumes digits in place. The parse visits each input byte once.

One output buffer collects answers and flushes in fixed blocks.

```
var outputBuffer = ""

proc appendResult(blackCount, whiteCount, greenCount: int) =
  outputBuffer.add $blackCount
  outputBuffer.add ' '
  outputBuffer.add $whiteCount
  outputBuffer.add ' '
  outputBuffer.add $greenCount
  outputBuffer.add " \n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 256 KiB, not after each answer. A per-case write enters the stream layer on every answer. The final write emits the remainder, and the cost is O(1) amortized per answer.

The outer loop runs caseCount times, and the inner loop runs vertexCount times.

```
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  var greenPieceSum = 0
  var greenPentagonVertices = 0
  var boundaryState = stateHexagonEdge
  for vertexIndex in 0..<vertexCount:
    let adjoiningGreenPieces = nextInt(inputData, scanPos)
    greenPieceSum += adjoiningGreenPieces
    case boundaryState
    of statePentagonFace:
      if adjoiningGreenPieces == 1:
        boundaryState = statePentagonFace
      else:
        boundaryState = stateHexagonEdge
      inc greenPentagonVertices
    of stateHexagonFace:
      if adjoiningGreenPieces == 1:
        boundaryState = stateHexagonEdge
      else:
        boundaryState = stateHexagonFace
    of stateHexagonEdge:
      if adjoiningGreenPieces == 1:
        boundaryState = stateHexagonFace
      else:
        boundaryState = statePentagonFace
        inc greenPentagonVertices
  let greenPentagons = 2 * greenPieceSum - 3 * vertexCount + 6
  let greenHexagons = (10 * greenPentagons + greenPieceSum - 3 * greenPentagonVertices) div 6
  appendResult(12 - greenPentagons, 20 - greenHexagons, greenPentagons + greenHexagons)

stdout.write outputBuffer
```

The state branches add Q only at a vertex with a green pentagon. Both formulas use sums gathered in the same pass. The walk costs O(n) time and O(1) extra space per case.

## Complexity

The program reads once, walks each case, and writes in blocks.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(total input bytes) | O(total input bytes) |
| Per case | O(n) | O(1) |
| Output | O(total output bytes) | O(256 KiB) |
| Total | O(input + output) | O(input + 256 KiB) |

The walk is linear in the polygon length, and the two buffers dominate space. Big O per case is O(n), and the whole run is O(input bytes + output bytes). A naive rebuild of the ball and an exhaustive face count cost more per case and need data the input lacks.
