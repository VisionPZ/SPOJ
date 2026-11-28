# KNIGHTS — Knights of the Round Table (SPOJ)

<https://www.spoj.com/problems/KNIGHTS/>

## Problem

Some knights hate each other, and a legal seating needs an odd cycle of pairwise non-hating neighbors. Count the knights that cannot sit in such a cycle.

Input holds several cases. Each starts with `n m`, then `m` hate pairs using one-based knight numbers. A case with `n = m = 0` ends the input. Output holds one expelled count per case.

The bounds from the statement:

| item | bound |
|---|---|
| knights n | 1 to 1000 |
| hate pairs m | 1 to 1000000 |
| judge limit | 2000 ms, 1536 MB |

A knight with only one non-hating neighbor cannot sit, even when that neighbor lies in a triangle.

Sample input:

```
5 5
1 4
1 5
2 5
3 4
4 5
0 0
```

This figure is the sample input copied from the statement.

Sample output:

```
2
```

This figure is the sample output, one count per case.

## Idea

Turn hate edges into friendship edges; a legal table is then an odd cycle in the friendship graph.

Think of cycles as rooms joined by single doors: a knight sits when some room has an odd loop and contains him.

Tarjan's algorithm splits the friendship graph into biconnected components, and a two-color test marks each odd component.

Checking every knight against every possible cycle costs far more than one pass over components. The block decomposition keeps the search local.

## Why It Works

1. Two neighbors at the table must be friends, so a seating is a cycle in the friendship graph.
2. An odd cycle appears exactly when some connected part is not two-colorable.
3. Biconnected components split the graph at articulation points, where no cycle can pass through two blocks at once.
4. Every vertex of a non-two-colorable block lies on an odd cycle inside that block.
5. Marking those vertices and counting the rest gives the expelled knights.

The main terms:

| term | meaning |
|---|---|
| `adjacency` | friendship graph, the complement of the hate pairs |
| `edgeStack` | edges waiting to form a biconnected component |
| `oddCycle` | result of the two-color test on one component |
| `canSit` | marks knights that lie in an odd component |

The table names the values used by the search.

A script traced the sample case:

```
block (1,2),(2,3),(1,3): same-color conflict, odd cycle, knights 1,2,3 sit
block (2,4): two vertices, two-colorable, knight 4 expelled
block (3,5): two vertices, two-colorable, knight 5 expelled
expelled = 2
```

The friendship triangle seats three knights, which matches the sample answer.

The matrix `hates` makes complement construction a single pass over all pairs. The `colorValue` array is reset only for vertices of the current component.

## Code

**Input and scanner.** The reader loads all cases, and the scanner walks integer tokens.

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
```

Knight numbers are converted to zero-based indexes.
All cases share one output buffer.
Parsing skips line breaks without special cases.

**Component test.** A two-color search decides whether one block has an odd cycle.

```nim
proc examineComponent(componentVertices: seq[int]) =
  componentId += 1
  for vertex in componentVertices:
    componentMark[vertex] = componentId
  var vertexQueue = newSeq[int](componentVertices.len)
  var queueHead = 0
  var queueTail = 0
  colorValue[componentVertices[0]] = 0
  vertexQueue[queueTail] = componentVertices[0]
  queueTail += 1
  var oddCycle = false
  while queueHead < queueTail and not oddCycle:
    let currentVertex = vertexQueue[queueHead]
    queueHead += 1
    for neighbor in adjacency[currentVertex]:
      if componentMark[neighbor] != componentId:
        continue
      if colorValue[neighbor] == -1:
        colorValue[neighbor] = 1 - colorValue[currentVertex]
        vertexQueue[queueTail] = neighbor
        queueTail += 1
      elif colorValue[neighbor] == colorValue[currentVertex]:
        oddCycle = true
        break
  if oddCycle:
    for vertex in componentVertices:
      canSit[vertex] = true
  for vertex in componentVertices:
    colorValue[vertex] = -1
```

Only neighbors inside the current block take part.
A same-color edge proves an odd cycle.
Every vertex of that block becomes a valid knight.

**Tarjan sweep.** Depth-first search cuts components from the edge stack.

```nim
proc visitVertex(startVertex: int) =
  discovery[startVertex] = discoveryTimer
  lowLink[startVertex] = discoveryTimer
  discoveryTimer += 1
  for neighbor in adjacency[startVertex]:
    if discovery[neighbor] == -1:
      parentVertex[neighbor] = startVertex
      edgeStack.add((startVertex, neighbor))
      visitVertex(neighbor)
      if lowLink[neighbor] < lowLink[startVertex]:
        lowLink[startVertex] = lowLink[neighbor]
      if lowLink[neighbor] >= discovery[startVertex]:
        var componentVertices: seq[int] = @[]
        while true:
          let savedEdge = edgeStack[edgeStack.len - 1]
          edgeStack.setLen(edgeStack.len - 1)
          componentVertices.add(savedEdge.firstVertex)
          componentVertices.add(savedEdge.secondVertex)
          if savedEdge.firstVertex == startVertex and savedEdge.secondVertex == neighbor:
            break
        examineComponent(componentVertices)
    elif neighbor != parentVertex[startVertex] and discovery[neighbor] < discovery[startVertex]:
      edgeStack.add((startVertex, neighbor))
      if discovery[neighbor] < lowLink[startVertex]:
        lowLink[startVertex] = discovery[neighbor]
```

The low-link test identifies one component per tree edge.
Back edges are stored once, from the newer vertex to the older one.
Each edge leaves the stack exactly once.

**Case driver.** The driver builds the complement, runs the sweep, and counts failures.

```nim
while true:
  let requestedKnights = nextInt(inputData, scanPos)
  let requestedPairs = nextInt(inputData, scanPos)
  if requestedKnights == 0 and requestedPairs == 0:
    break
  knightCount = requestedKnights
  var hates = newSeq[bool](knightCount * knightCount)
  for pairIndex in 0 .. requestedPairs - 1:
    let firstKnight = nextInt(inputData, scanPos) - 1
    let secondKnight = nextInt(inputData, scanPos) - 1
    hates[firstKnight * knightCount + secondKnight] = true
    hates[secondKnight * knightCount + firstKnight] = true

  adjacency = newSeq[seq[int]](knightCount)
  for firstKnight in 0 .. knightCount - 1:
    adjacency[firstKnight] = @[]
  for firstKnight in 0 .. knightCount - 1:
    for secondKnight in firstKnight + 1 .. knightCount - 1:
      if not hates[firstKnight * knightCount + secondKnight]:
        adjacency[firstKnight].add(secondKnight)
        adjacency[secondKnight].add(firstKnight)

  discovery = newSeq[int](knightCount)
  lowLink = newSeq[int](knightCount)
  parentVertex = newSeq[int](knightCount)
  colorValue = newSeq[int](knightCount)
  componentMark = newSeq[int](knightCount)
  canSit = newSeq[bool](knightCount)
  for vertex in 0 .. knightCount - 1:
    discovery[vertex] = -1
    parentVertex[vertex] = -1
    colorValue[vertex] = -1
    componentMark[vertex] = 0
  discoveryTimer = 0
  componentId = 0
  edgeStack = @[]

  for vertex in 0 .. knightCount - 1:
    if discovery[vertex] == -1:
      visitVertex(vertex)
    if edgeStack.len > 0:
      edgeStack.setLen(0)

  var expelledCount = 0
  for vertex in 0 .. knightCount - 1:
    if not canSit[vertex]:
      expelledCount += 1
  appendOutput($expelledCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Adjacency lists are initialized before any edge is added.
Every disconnected part gets its own depth-first sweep.
The final loop counts knights left without an odd block.

## Complexity

Each case builds a complement graph and runs one depth-first sweep over it.

The cost breakdown by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over hate pairs | one input string |
| complement build | O(n^2) pair checks | n by n hate matrix |
| component sweep | O(n^2) edges and tests | arrays of n vertices |
| output | one line per case | block buffer |

Complement construction and the sweep dominate the work.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(n^2 + m) per case |
| space | O(n^2) |

Trying every possible cycle for each knight grows far faster than one two-color test per biconnected block.
