# MAXISET — Maximal Independent Set (SPOJ)

<https://www.spoj.com/problems/MAXISET/>

## Problem

For each query subset of vertices, report the largest total vertex weight of an independent set inside the induced subgraph. An independent set picks no two vertices joined by an edge. Blank lines separate the output of successive test cases.

Input starts with the test count. Each case gives the vertex count and edge count, then the weights, then the edges, then the query count and the query vertex lists. Output one weight per query.

| Item | Bound |
|---|---|
| Test cases | up to 20 in set 1, 10 in set 2 |
| Vertices | up to 30 in set 1, 40 in set 2 |
| Edges | up to 1000 |
| Queries | up to 1000 in set 1, 100 in set 2 |
| Vertex weight | up to 1000 |
| Judge limit | 1183 ms, 1536 MB |

The vertex count sets the table sizes, since a half-graph of 20 vertices has a million masks.

Sample input:

```
2
5 1
1 2 3 4 5
0 1
3
3 0 1 2
3 1 2 3
2 0 1
3 3
1 2 3
0 1
0 2
1 2
1
3 0 1 2
```

The first graph has one edge; the second has no edges.

Sample output:

```
5
9
2

3
```

The blank line marks the boundary between the two cases.

## Idea

Split the vertices into two halves, like sorting two piles of cards before pairing them. Precompute the best choice inside the right pile for every subset, then try every legal choice from the left pile and look up the matching right answer.

The algorithm is meet-in-the-middle with subset dynamic programming. Each half has at most twenty vertices, so each mask table has at most a million entries. Trying all subsets of all vertices would cost two to the forty per query, while a left-side submask walk touches at most a million entries. A short lookup closes each left choice with the best compatible right choice.

## Why It Works

1. Every independent set splits into a left part and a right part.
2. The left part forbids exactly the right vertices adjacent to it.
3. The right part may use any remaining vertices of the query.
4. The precomputed right table holds the best independent set for every right mask.
5. Maximizing over all independent left submasks of the query therefore finds the best total.

| Term | Meaning |
|---|---|
| `leftForbidden` | right vertices blocked by one left choice |
| `leftIndependent` | whether a left mask contains no edge |
| `rightBest` | best independent weight inside one right mask |
| `allowedRight` | query right vertices not blocked by the left choice |

The terms above are the complete query state.

A worked trace for the first sample query:

```
left half {0}, right half {1,2}; query {0,1,2}
left choice empty: right {1,2} has edge, best is 2
left choice {0}: weight 1, right {2} allowed, best 3
maximum is 1 + 3 = 5
```

The trace matches the first sample answer.

## Code

**Input and scanner.** All stdin is read once and parsed by a digit scanner.

```nim
const flushBlockBytes = 1 shl 17

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
```

Weights and vertex ids are all nonnegative.
One block holds many answer lines.

**Half tables.** Each mask stores independence, weight, and blocked right vertices.

```nim
proc lowestBitIndex(maskValue: int): int =
  var bitIndex = 0
  while (maskValue and (1 shl bitIndex)) == 0:
    bitIndex += 1
  return bitIndex
```

The helper finds the least significant set bit.
Each table entry is built from that smaller mask.

**Graph split.** Edges are stored as bitmasks inside each half or across the cut.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var weights = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    weights[vertexIndex] = nextInt(inputData, scanPos)
  let leftCount = vertexCount div 2
  let rightCount = vertexCount - leftCount
  var leftNeighbors = newSeq[int](leftCount)
  var rightNeighbors = newSeq[int](rightCount)
  var leftCross = newSeq[int](leftCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let firstVertex = nextInt(inputData, scanPos)
    let secondVertex = nextInt(inputData, scanPos)
    if firstVertex < leftCount and secondVertex < leftCount:
      leftNeighbors[firstVertex] = leftNeighbors[firstVertex] or (1 shl secondVertex)
      leftNeighbors[secondVertex] = leftNeighbors[secondVertex] or (1 shl firstVertex)
    elif firstVertex >= leftCount and secondVertex >= leftCount:
      let rightFirst = firstVertex - leftCount
      let rightSecond = secondVertex - leftCount
      rightNeighbors[rightFirst] = rightNeighbors[rightFirst] or (1 shl rightSecond)
      rightNeighbors[rightSecond] = rightNeighbors[rightSecond] or (1 shl rightFirst)
    else:
      if firstVertex >= leftCount:
        leftCross[secondVertex] = leftCross[secondVertex] or (1 shl (firstVertex - leftCount))
      else:
        leftCross[firstVertex] = leftCross[firstVertex] or (1 shl (secondVertex - leftCount))
```

Cross edges are kept on the left side.
Each edge is stored once.

**Precomputation.** Subset recurrences fill both half tables.

```nim
  let leftMasks = 1 shl leftCount
  let rightMasks = 1 shl rightCount
  var leftIndependent = newSeq[bool](leftMasks)
  var leftWeight = newSeq[int](leftMasks)
  var leftForbidden = newSeq[int](leftMasks)
  leftIndependent[0] = true
  for maskValue in 1 .. leftMasks - 1:
    let lowestBit = maskValue and -maskValue
    let vertexIndex = lowestBitIndex(lowestBit)
    let remaining = maskValue xor lowestBit
    leftIndependent[maskValue] = leftIndependent[remaining] and
                                 ((leftNeighbors[vertexIndex] and remaining) == 0)
    leftWeight[maskValue] = leftWeight[remaining] + weights[vertexIndex]
    leftForbidden[maskValue] = leftForbidden[remaining] or leftCross[vertexIndex]
  var rightBest = newSeq[int](rightMasks)
  for maskValue in 1 .. rightMasks - 1:
    let lowestBit = maskValue and -maskValue
    let vertexIndex = lowestBitIndex(lowestBit)
    let remaining = maskValue xor lowestBit
    let withoutVertex = remaining and not rightNeighbors[vertexIndex]
    let takeValue = weights[leftCount + vertexIndex] + rightBest[withoutVertex]
    if takeValue > rightBest[maskValue]:
      rightBest[maskValue] = takeValue
    if rightBest[remaining] > rightBest[maskValue]:
      rightBest[maskValue] = rightBest[remaining]
```

The empty mask is independent with weight zero.
The right table takes the better of including or skipping a vertex.

**Queries.** Each query walks the independent submasks of its left part.

```nim
  let queryCount = nextInt(inputData, scanPos)
  if caseIndex > 0:
    appendOutput("\n")
  for queryIndex in 0 .. queryCount - 1:
    let memberCount = nextInt(inputData, scanPos)
    var leftMask = 0
    var rightMask = 0
    for memberIndex in 0 .. memberCount - 1:
      let vertexIndex = nextInt(inputData, scanPos)
      if vertexIndex < leftCount:
        leftMask = leftMask or (1 shl vertexIndex)
      else:
        rightMask = rightMask or (1 shl (vertexIndex - leftCount))
    var bestSet = 0
    var submask = leftMask
    while true:
      if leftIndependent[submask]:
        let allowedRight = rightMask and not leftForbidden[submask]
        let candidate = leftWeight[submask] + rightBest[allowedRight]
        if candidate > bestSet:
          bestSet = candidate
      if submask == 0:
        break
      submask = (submask - 1) and leftMask
    appendOutput($bestSet & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A blank line precedes every case except the first.
The submask walk visits each legal left choice once.
The final flush clears the buffer.

## Complexity

Building the two half tables dominates a test case.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over graph data | one input string |
| Half tables | one pass over each half's masks | four mask arrays |
| Queries | one submask walk per query | two query masks |
| Output | one write per block | block buffer |

The phase table shows the mask arrays are the main memory cost.

| Measure | Big O |
|---|---|
| Time | O(n times 2^(n/2) plus q times 2^(n/2)) |
| Space | O(2^(n/2)) |

Trying every vertex subset costs two to the n per query, while the split reduces the exponent by half.
