# QSTABLE — Queen and Stable Relationships (SPOJ)
<https://www.spoj.com/problems/QSTABLE/>

## Problem

People are connected by relationships, and acquaintances form connected components. Each query asks whether two people stay acquainted after one relationship ends or after one person leaves college. Print STABLE when they stay connected and NOT STABLE otherwise.

Input gives the number of people N and relationships M, then M lines of two names. A line with Q follows, then Q query lines. A type 1 query holds four names: the two people tested and the pair that breaks up. A type 2 query holds three names: the two people tested and the person who leaves.

| item | bound |
|---|---|
| people N | 1 to 10000 |
| relationships M | 1 to 50000 |
| queries Q | 1 to 10000 |
| name length | under 50 characters |
| judge limit | 1000 ms, 1536 MB |

Removing a person drops every relationship touching that person; removing a relationship drops one edge.

Sample input:

```
3 2
Person1 Person2
Person1 Person3
2
2 Person2 Person3 Person1
1 Person1 Person2 Person1 Person3
```

The sample uses one vertex removal and one relationship removal.

Sample output:

```
NOT STABLE
STABLE
```

Without Person1, the other two people lose their only link.

## Idea

Think of a bridge as the only plank across a river and an articulation person as the only knot tying two ropes together. One depth-first search finds both kinds of weak points. For an edge removal, only a bridge can split the graph. For a person removal, only a separating child branch can hide the two tested people in different pieces. Searching the graph again for every query would cost far more; the depth-first data answers each query with a few checks. One search prepares all answers.

## Why It Works

1. Depth-first search numbers each vertex when it is first reached.
2. `lowValue` is the smallest discovery number reachable from a subtree by one back edge.
3. A tree edge to a child is a bridge when the child's `lowValue` exceeds the parent's discovery number.
4. Removing a nonbridge or a missing edge leaves every pair connected.
5. After a bridge splits the graph, the two sides are the child's subtree and the rest.
6. A child of a cut vertex separates its subtree when its `lowValue` is at least the cut vertex's discovery number.
7. Removing any other child branch leaves a route through the cut vertex's parent side.
8. `regionLabel` climbs parent links and returns the separating child below the cut vertex.
9. Two people stay connected exactly when their region labels match.

| term | meaning |
|---|---|
| `discovery` | depth-first entry number of a vertex |
| `lowValue` | earliest discovery number reachable from that subtree |
| `subtreeEnd` | largest entry number inside the subtree |
| `treeParent` | parent in the depth-first tree |
| `hasEdge` | checks whether the named pair has a relationship |
| `regionLabel` | identifies which piece survives without the cut vertex |

All tests use these arrays; no graph traversal runs during query answering.

The generator script produced this example from the sample. The search numbers the people in input order.

| person | `discovery` | `lowValue` | parent |
|---|---|---|---|
| Person1 | 1 | 1 | none |
| Person2 | 2 | 2 | Person1 |
| Person3 | 3 | 3 | Person1 |

Both child subtrees have `lowValue` above 1, so each is a bridge and a separate region.

The comparison uses entry numbers and subtree ends, so no floating point or rounding is involved.

## Code

**Input and hashing.** Read stdin, tokenize names, and map each name to a vertex number.

```nim
import hashes

const flushBlockBytes = 1 shl 17
const nameTableSize = 1 shl 15
const edgeTableSize = 1 shl 19

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    pos += 1
  return data[tokenStart .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var nameSlots = newSeq[int](nameTableSize)
var storedNames = newSeq[string](0)

proc nameSlotFor(name: string): int =
  result = int(hash(name)) and (nameTableSize - 1)
  while nameSlots[result] != 0 and storedNames[nameSlots[result] - 1] != name:
    result = (result + 1) and (nameTableSize - 1)

proc getIdFor(name: string): int =
  let slot = nameSlotFor(name)
  if nameSlots[slot] == 0:
    storedNames.add name
    nameSlots[slot] = storedNames.len
    return storedNames.len - 1
  return nameSlots[slot] - 1
```

`nextToken` reads names without copying the whole input.
`nameSlots` uses linear probing to map names to compact vertex numbers.
`getIdFor` also assigns numbers to names seen only in queries.

**Graph and query storage.** Keep both endpoints, build adjacency, and index every edge pair.

```nim
discard nextInt(inputData, scanPos)
let notedRelationships = nextInt(inputData, scanPos)
var edgeFirst = newSeq[int](notedRelationships)
var edgeSecond = newSeq[int](notedRelationships)
for edgeIndex in 0 .. notedRelationships - 1:
  let firstPerson = nextToken(inputData, scanPos)
  let secondPerson = nextToken(inputData, scanPos)
  edgeFirst[edgeIndex] = getIdFor(firstPerson)
  edgeSecond[edgeIndex] = getIdFor(secondPerson)

let queryCount = nextInt(inputData, scanPos)
var queryKinds = newSeq[int](queryCount)
var queryFirst = newSeq[int](queryCount)
var querySecond = newSeq[int](queryCount)
var queryThird = newSeq[int](queryCount)
var queryFourth = newSeq[int](queryCount)
for queryIndex in 0 .. queryCount - 1:
  queryKinds[queryIndex] = nextInt(inputData, scanPos)
  queryFirst[queryIndex] = getIdFor(nextToken(inputData, scanPos))
  querySecond[queryIndex] = getIdFor(nextToken(inputData, scanPos))
  queryThird[queryIndex] = getIdFor(nextToken(inputData, scanPos))
  queryFourth[queryIndex] = if queryKinds[queryIndex] == 1: getIdFor(nextToken(inputData, scanPos)) else: -1

let vertexCount = storedNames.len
var adjacency = newSeq[seq[int]](vertexCount)
var adjacencyEdges = newSeq[seq[int]](vertexCount)
for vertexIndex in 0 .. vertexCount - 1:
  adjacency[vertexIndex] = newSeq[int](0)
  adjacencyEdges[vertexIndex] = newSeq[int](0)
for edgeIndex in 0 .. notedRelationships - 1:
  let firstVertex = edgeFirst[edgeIndex]
  let secondVertex = edgeSecond[edgeIndex]
  adjacency[firstVertex].add secondVertex
  adjacencyEdges[firstVertex].add edgeIndex
  adjacency[secondVertex].add firstVertex
  adjacencyEdges[secondVertex].add edgeIndex

var edgeSlots = newSeq[int](edgeTableSize)
proc edgeKeyFor(firstVertex, secondVertex: int): int =
  if firstVertex < secondVertex:
    return firstVertex * vertexCount + secondVertex + 1
  return secondVertex * vertexCount + firstVertex + 1
proc edgeSlotFor(key: int): int =
  result = int(hash(key)) and (edgeTableSize - 1)
  while edgeSlots[result] != 0 and edgeSlots[result] != key:
    result = (result + 1) and (edgeTableSize - 1)
proc hasEdge(firstVertex, secondVertex: int): bool =
  let key = edgeKeyFor(firstVertex, secondVertex)
  return edgeSlots[edgeSlotFor(key)] == key
for edgeIndex in 0 .. notedRelationships - 1:
  edgeSlots[edgeSlotFor(edgeKeyFor(edgeFirst[edgeIndex], edgeSecond[edgeIndex]))] = edgeKeyFor(edgeFirst[edgeIndex], edgeSecond[edgeIndex])
```

All names get numbers before the graph is built.
`adjacencyEdges` stores edge numbers so parallel edges stay correct.
`hasEdge` answers whether the pair in a query appears among the relationships.

**Depth-first search.** Compute entry times, low values, subtree ends and region labels.

```nim
var discovery = newSeq[int](vertexCount)
var lowValue = newSeq[int](vertexCount)
var treeParent = newSeq[int](vertexCount)
var parentEdge = newSeq[int](vertexCount)
var subtreeEnd = newSeq[int](vertexCount)
var edgeCursor = newSeq[int](vertexCount)
for vertexIndex in 0 .. vertexCount - 1:
  treeParent[vertexIndex] = -1
  parentEdge[vertexIndex] = -1
var searchTimer = 0
for rootVertex in 0 .. vertexCount - 1:
  if discovery[rootVertex] != 0:
    continue
  var dfsStack = newSeq[int](0)
  discovery[rootVertex] = searchTimer + 1
  lowValue[rootVertex] = searchTimer + 1
  searchTimer += 1
  dfsStack.add rootVertex
  while dfsStack.len > 0:
    let currentVertex = dfsStack[dfsStack.len - 1]
    if edgeCursor[currentVertex] < adjacency[currentVertex].len:
      let neighborVertex = adjacency[currentVertex][edgeCursor[currentVertex]]
      let currentEdge = adjacencyEdges[currentVertex][edgeCursor[currentVertex]]
      edgeCursor[currentVertex] += 1
      if currentEdge == parentEdge[currentVertex]:
        continue
      if discovery[neighborVertex] == 0:
        treeParent[neighborVertex] = currentVertex
        parentEdge[neighborVertex] = currentEdge
        discovery[neighborVertex] = searchTimer + 1
        lowValue[neighborVertex] = searchTimer + 1
        searchTimer += 1
        dfsStack.add neighborVertex
      elif discovery[neighborVertex] < lowValue[currentVertex]:
        lowValue[currentVertex] = discovery[neighborVertex]
    else:
      dfsStack.setLen(dfsStack.len - 1)
      subtreeEnd[currentVertex] = searchTimer
      if dfsStack.len > 0:
        let parentVertex = dfsStack[dfsStack.len - 1]
        if lowValue[currentVertex] < lowValue[parentVertex]:
          lowValue[parentVertex] = lowValue[currentVertex]

proc regionLabel(startVertex, cutVertex: int): int =
  var currentVertex = startVertex
  while currentVertex != cutVertex and currentVertex >= 0:
    let parentVertex = treeParent[currentVertex]
    if parentVertex == cutVertex and lowValue[currentVertex] >= discovery[cutVertex]:
      return currentVertex + 1
    currentVertex = parentVertex
  return 0
```

An explicit stack avoids deep recursion on long chains.
`subtreeEnd` is the last entry number inside a subtree.
`regionLabel` returns zero when no separating child lies below the cut vertex.

**Answers.** Apply the bridge or cut-vertex tests and write one line per query.

```nim
for queryIndex in 0 .. queryCount - 1:
  let personA = queryFirst[queryIndex]
  let personB = querySecond[queryIndex]
  let personC = queryThird[queryIndex]
  var stable = false
  if queryKinds[queryIndex] == 1:
    let personD = queryFourth[queryIndex]
    if not hasEdge(personC, personD):
      stable = true
    else:
      var separatingChild = -1
      var bridgeParent = -1
      if treeParent[personD] == personC:
        separatingChild = personD
        bridgeParent = personC
      elif treeParent[personC] == personD:
        separatingChild = personC
        bridgeParent = personD
      if separatingChild < 0 or lowValue[separatingChild] <= discovery[bridgeParent]:
        stable = true
      else:
        let firstInside = discovery[personA] >= discovery[separatingChild] and discovery[personA] <= subtreeEnd[separatingChild]
        let secondInside = discovery[personB] >= discovery[separatingChild] and discovery[personB] <= subtreeEnd[separatingChild]
        stable = firstInside == secondInside
  else:
    if personA != personC and personB != personC:
      stable = regionLabel(personA, personC) == regionLabel(personB, personC)
  if stable:
    appendOutput("STABLE\n")
  else:
    appendOutput("NOT STABLE\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A missing edge or a nonbridge always leaves the pair connected.
A bridge splits the graph into its child subtree and the rest.
The final write flushes all answer lines together.

## Complexity

One depth-first search prepares the graph for every query.

| phase | time | space |
|---|---|---|
| input read | one pass over names and queries | two hash tables |
| depth-first search | one visit per vertex and edge | five vertex arrays |
| query answering | a few comparisons per query | one output buffer |

The hash tables map names and edge pairs without scanning lists.

| measure | Big O |
|---|---|
| preprocessing | O(N + M) |
| type 1 query | O(1) |
| type 2 query | O(N) worst case |
| space | O(N + M) |

The parent climb is short on shallow trees and bounded by N on long chains.

Rebuilding the graph and searching it for every query would cost O(QM) time.

The single search keeps all queries well inside the judge limit.
