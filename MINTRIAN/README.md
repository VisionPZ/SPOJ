# MINTRIAN — Minimal Triangulations of Graphs (SPOJ)

<https://www.spoj.com/problems/MINTRIAN/>

## Problem

Decide whether each given graph is chordal, meaning every cycle of four or more vertices has a shortcut edge. Print `YES` for chordal graphs and `NO` otherwise.

Each test starts with a header line `n=N,m=M`. The next line lists `M` edges as `{u,v}` pairs. Input ends after `t` graphs.

| item | bound |
|---|---|
| test cases t | 1 to 200 |
| vertices n | up to about 1000 |
| edges m | up to about 80000 |
| judge limit | 6919 ms, 1536 MB |

The edge count drives the search for a good elimination order.

Sample input:

```
2
n=6,m=4
{0,1} {2,3} {3,4} {3,5} 
n=6,m=7
{0,3} {1,2} {1,3} {2,4} {2,5} {3,4} {3,5} 
```

Sample output:

```
YES
NO
```

## Idea

Think of removing vertices one at a time, like peeling layers from an onion. A graph is chordal exactly when every step has a vertex whose neighbors already form a clique.

Maximum Cardinality Search builds that removal order by always taking the vertex with the most already-chosen neighbors. The check then confirms each vertex's later neighbors form a clique.

Testing every cycle would take exponential time. The order gives a linear check.

One order and one neighbor scan decide each graph.

## Why It Works

1. A graph is chordal when a perfect elimination order exists.
2. In such an order, neighbors chosen earlier form a clique at each step.
3. Maximum Cardinality Search produces this order for chordal graphs.
4. Checking one anchor neighbor against all later neighbors proves the clique.
5. A failed anchor pair proves a chordless cycle exists.

| term | meaning |
|---|---|
| `adjacency` | flat matrix of edge presence |
| `neighborMarks` | count of already-chosen neighbors |
| `eliminationOrder` | vertices in the order chosen |
| `rankInOrder` | choice step for each vertex |

A worked trace follows for the four-cycle `0-1-2-3-0`.

```
chosen neighbours of 3 in the four-cycle: 2 and 0
edge {0,2} missing
answer NO
```

The missing edge is the chord that a chordal graph would need.

## Code

**Input and scanner.** One buffer holds all headers and edge lines.

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

The scanner ignores braces, commas and labels.
Header numbers and edge endpoints use the same reader.
Duplicate edges enter the matrix once.

**Building the order.** Each step picks the most connected remaining vertex.

```nim
proc isChordal(vertexCount: int, edgeCount: int, scanPosition: var int): bool =
  var adjacency = newSeq[bool](vertexCount * vertexCount)
  var neighborList = newSeq[seq[int]](vertexCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let firstVertex = nextInt(inputData, scanPosition)
    let secondVertex = nextInt(inputData, scanPosition)
    if firstVertex == secondVertex:
      continue
    let forwardIndex = firstVertex * vertexCount + secondVertex
    let backwardIndex = secondVertex * vertexCount + firstVertex
    if not adjacency[forwardIndex]:
      adjacency[forwardIndex] = true
      adjacency[backwardIndex] = true
      neighborList[firstVertex].add secondVertex
      neighborList[secondVertex].add firstVertex

  var neighborMarks = newSeq[int](vertexCount)
  var chosen = newSeq[bool](vertexCount)
  var eliminationOrder = newSeq[int](vertexCount)
  for stepIndex in 0 .. vertexCount - 1:
    var bestVertex = -1
    var bestMark = -1
    for vertexIndex in 0 .. vertexCount - 1:
      if not chosen[vertexIndex] and neighborMarks[vertexIndex] > bestMark:
        bestVertex = vertexIndex
        bestMark = neighborMarks[vertexIndex]
    chosen[bestVertex] = true
    eliminationOrder[stepIndex] = bestVertex
    for neighborIndex in neighborList[bestVertex]:
      if not chosen[neighborIndex]:
        neighborMarks[neighborIndex] += 1
```

A flat matrix answers edge queries in constant time.
Marks rise only when a chosen vertex is a neighbor.
Choosing the maximum mark gives the search its name.

**Clique verification.** One anchor neighbor tests the whole earlier set.

```nim
  var rankInOrder = newSeq[int](vertexCount)
  for stepIndex in 0 .. vertexCount - 1:
    rankInOrder[eliminationOrder[stepIndex]] = stepIndex

  for stepIndex in 0 .. vertexCount - 1:
    let currentVertex = eliminationOrder[stepIndex]
    var anchorVertex = -1
    for neighborIndex in neighborList[currentVertex]:
      if rankInOrder[neighborIndex] < stepIndex:
        anchorVertex = neighborIndex
        break
    if anchorVertex < 0:
      continue
    for neighborIndex in neighborList[currentVertex]:
      if rankInOrder[neighborIndex] < stepIndex and neighborIndex != anchorVertex:
        if not adjacency[anchorVertex * vertexCount + neighborIndex]:
          return false
  return true
```

Vertices without earlier neighbors need no check.
A missing anchor edge rejects the graph.
The first valid order proves chordality.

**Test loop.** Each graph adds one answer line.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  if isChordal(vertexCount, edgeCount, scanPos):
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan position advances through every edge.
Buffered writes avoid one syscall per graph.
The final flush ends the output.

## Complexity

Order construction and clique checks dominate.

| phase | time | space |
|---|---|---|
| input read | one pass over edge bytes | input string |
| maximum cardinality search | O(n^2 + m) | marks and order |
| clique check | O(n + m) | adjacency matrix |
| output | one buffered write per block | block buffer |

The matrix stores each edge twice for fast lookup.

| measure | Big O |
|---|---|
| time | O(n^2 + m) per graph |
| space | O(n^2) |

Enumerating every cycle would take exponential time instead of polynomial time.

The degree-based order keeps each graph check small, even across two hundred cases.
