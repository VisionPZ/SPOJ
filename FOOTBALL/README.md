# FOOTBALL — Football (SPOJ)
<https://www.spoj.com/problems/FOOTBALL/>

## Problem

Eric paints half of a classic soccer ball green and traces a loop along the seams. Given only the loop's vertices and the number of green faces at each corner, he wants the counts of black, white, and green pieces.

The input starts with a test count t. Each case gives a vertex count n, then n values of 1 or 2, one per vertex. Value 1 means one green piece at that vertex, and value 2 means two. The closing edge always lies between two hexagons. Print three integers: black pieces, white pieces, and green pieces.

The judge limits are:

| Item | Value |
| --- | --- |
| Vertices per case | 6 to 60 |
| Green pieces at a vertex | 1 or 2 |
| Closing edge | joins two hexagons |
| Time limit | 100 ms |
| Memory limit | 1536 MB |

A polygon visits each ball vertex at most once, so a case stays small.

The sample input reads:

```text
1
21 
1 2 1 2 1 2 1 1 1 2 2 1 1 1 1 2 2 2 1 1 1 
```

The sample output reads:

```text
11 15 6 
```

## Idea

Count faces with Euler's formula (a rule linking vertices, edges, and faces on a surface), like balancing a ledger instead of rebuilding the ball. The sum of vertex values gives the green pentagons after one substitution. A three-state walk along the loop supplies the corner count that fixes the green hexagons. Each vertex costs one state transition, so the work is linear. Rebuilding the ball would need geometry the input does not provide. Takeaway: sum corners, walk states, then apply two formulas.

## Why It Works

1. Every ball vertex touches one pentagon and two hexagons.
2. Let V, E, and F count vertices, edges, and faces of the green disk; Euler gives V - E + F = 1.
3. Let S be the sum of vertex values, P the green pentagons, and H the green hexagons.
4. Counting face edges gives `5P + 6H = 2Ei + n`. Counting face corners gives `5P + 6H = 3Vi + S`, with Ei and Vi for interior items.
5. Substituting into Euler yields `P = 2S - 3n + 6`.
6. Counting pentagon corners at boundary vertices yields `H = (10P + S - 3Q) / 6`, where Q counts vertices with a green pentagon.
7. The walk starts in the hexagon-edge state and updates its state from the incoming edge type and S's value at that vertex.

The table defines the terms.

| Term | Meaning |
| --- | --- |
| S | sum of the n green-piece counts |
| P | number of green pentagons |
| H | number of green hexagons |
| Q | vertices whose pentagon is green |
| greenPentagonVertices | the running value of Q |

These terms feed the two counting formulas.

A script replayed the sample walk. The state column names the edge leaving each vertex.

| Vertex | ai | State after vertex | Q |
| --- | --- | --- | --- |
| 1 | 1 | PH, green face hexagon | 0 |
| 2 | 2 | PH, green face hexagon | 0 |
| 3 | 1 | HH, green face hexagon | 0 |
| 4 | 2 | PH, green face pentagon | 1 |
| 5 | 1 | PH, green face pentagon | 2 |
| 6 | 2 | HH, green face hexagon | 3 |
| 7 | 1 | PH, green face hexagon | 3 |
| 8 | 1 | HH, green face hexagon | 3 |
| 9 | 1 | PH, green face hexagon | 3 |
| 10 | 2 | PH, green face hexagon | 3 |
| 11 | 2 | PH, green face hexagon | 3 |
| 12 | 1 | HH, green face hexagon | 3 |
| 13 | 1 | PH, green face hexagon | 3 |
| 14 | 1 | HH, green face hexagon | 3 |
| 15 | 1 | PH, green face hexagon | 3 |
| 16 | 2 | PH, green face hexagon | 3 |
| 17 | 2 | PH, green face hexagon | 3 |
| 18 | 2 | PH, green face hexagon | 3 |
| 19 | 1 | HH, green face hexagon | 3 |
| 20 | 1 | PH, green face hexagon | 3 |
| 21 | 1 | HH, green face hexagon | 3 |

The walk ends on an HH edge. With S = 29, n = 21, and Q = 3, the formulas give P = 1 and H = 5. The answer is 11 black, 15 white, and 6 green pieces.

## Code

**States and constants.** The three walk states cover every edge type the loop can follow.

```nim
type BoundaryState = enum
  statePentagonFace, stateHexagonFace, stateHexagonEdge

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
```

The enum names the three states, and the constants name the digit base and flush threshold. One state describes the most recent edge. The declarations cost no runtime work.

**Input and scanner.** The program reads all input into one buffer and walks it by index.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  let dataLength = data.len
  while i < dataLength and (data[i] < '0' or data[i] > '9'):
    i += 1
  result = 0
  while i < dataLength and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + (int(data[i]) - firstDigitValue)
    i += 1
```

`readLine` runs once per input line and appends to one buffer. The scanner skips separators and consumes digits in place. Parsing visits each input byte once. All values are non-negative, so no sign branch is needed.

**Output writer.** One buffer collects all answer lines.

```nim
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

The buffer flushes after 256 KiB, not after each answer. The trailing space in each line matches the sample bytes. The cost is O(1) amortized per answer.

**State walk and driver.** The outer loop runs caseCount times and the inner loop runs vertexCount times.

```nim
let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let vertexCount = nextInt(inputData, i)
  var greenPieceSum = 0
  var greenPentagonVertices = 0
  var boundaryState = stateHexagonEdge
  for k in 0..<vertexCount:
    let adjoiningGreenPieces = nextInt(inputData, i)
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

The state branches add Q only where a pentagon is green. Both formulas use sums gathered in the same pass. The walk costs O(n) time and O(1) extra space per case. The final write emits the remaining buffered bytes.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read one case | O(n) | one input buffer |
| Walk vertices | O(n) | O(1) |
| Write answers | O(total output bytes) | one block |

No phase grows faster than the vertex count.

The walk is linear in the polygon length.

| Measure | Bound |
| --- | --- |
| Per case | O(n) time, O(1) extra space |
| Whole run | O(input bytes + output bytes) |
| Buffers | input buffer plus one 256 KiB block |

A naive program rebuilds the ball and counts faces by geometry. It costs more per case and needs data the input lacks.
