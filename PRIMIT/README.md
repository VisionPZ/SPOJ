## Problem

A primitivus code is a list of numbers. A feature is any pair of numbers that sit next to each other in that list. Read the required features and print the shortest list that contains every feature as a neighboring pair. Extra neighboring pairs are allowed.

These bounds shape the design.

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded by the statement; input is warned as enormous |
| Features in one case | at most 999000 |
| Number labels | 1 to 1000 |
| Time limit | 1600 ms |
| Memory limit | 1536 MB |

Only 1000 labels exist, so one small table per case handles even the largest input.

## Idea

Treat each feature as a directed edge and cover all edges with directed trails. A trail is a run of edges where each edge starts where the previous edge ends. Split a code at every neighboring pair that is not a feature, and each piece is a trail. If C trails cover the features, the shortest code has featureCount + C numbers. The program counts C from vertex degrees and weak components. Searching over feature subsets costs 2^n steps and cannot handle a large case.

Each feature costs two degree updates and one union operation.

## Why It Works

Each trail begins at one number. A vertex with d more outgoing features than incoming features must begin at least d trails. Each pass through that vertex uses one feature in each direction. Add those surpluses inside one weak component to get its lower bound. A closed tour begins at one number even when every surplus is zero, so a component needs at least max(1, surplus) trails. Degree sequences with this surplus split into exactly that many trails, so the bound is tight.

outDeg[v] counts features leaving v. inDeg[v] counts features entering v. max(0, outDeg - inDeg) is the surplus at v. parent links two labels joined by a feature, so one root names one weak component. compImbalance[root] adds the surplus of every vertex in that component. trailCount adds max(1, compImbalance[root]) for each root.

The script in gen.py computes the sample walk.

| Number | Out | In | Surplus |
| --- | --- | --- | --- |
| 1 | 1 | 1 | 0 |
| 2 | 2 | 1 | 1 |
| 3 | 1 | 1 | 0 |
| 4 | 2 | 1 | 1 |
| 5 | 2 | 2 | 0 |
| 6 | 0 | 3 | 0 |
| 7 | 1 | 1 | 0 |
| 8 | 2 | 1 | 1 |
| 9 | 1 | 1 | 0 |

features 12 surplus 3 components 1 trails 3 answer 15

Three surplus vertices give three trails, so 12 + 3 = 15 numbers.

## Code

The line loop reads every byte once into inputData. nextInt skips blank separators and stops at the first non-digit. Scanning costs one pass over the input.

```nim
{.push checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const vertexLimit = 1000

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The tables hold 1000 labels and never grow with featureCount. findRoot compresses the path it walks, which keeps each union nearly constant. touchedVertices resets only what the case used.

```nim
var outDeg: array[0..vertexLimit, int]
var inDeg: array[0..vertexLimit, int]
var parent: array[0..vertexLimit, int]
var compImbalance: array[0..vertexLimit, int]
var isTouched: array[0..vertexLimit, bool]
var touchedVertices: seq[int]
for vertex in 0..vertexLimit:
  parent[vertex] = vertex

proc findRoot(vertex: int): int =
  var root = vertex
  while parent[root] != root:
    root = parent[root]
  var walk = vertex
  while parent[walk] != walk:
    let nextVertex = parent[walk]
    parent[walk] = root
    walk = nextVertex
  return root

proc unionVertices(firstVertex: int, secondVertex: int) =
  let firstRoot = findRoot(firstVertex)
  let secondRoot = findRoot(secondVertex)
  if firstRoot != secondRoot:
    parent[secondRoot] = firstRoot
```

flushBlockBytes is 2^18. A block write avoids one stream call per answer. The buffer holds at most one block.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The feature loop runs featureCount times. compImbalance is read after every union, so roots are stable. The else branch gives a balanced component one trail. The final write flushes the remainder.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let featureCount = nextInt(inputData, scanPos)
  touchedVertices.setLen 0
  for edgeIndex in 0..<featureCount:
    let leftVertex = nextInt(inputData, scanPos)
    let rightVertex = nextInt(inputData, scanPos)
    if not isTouched[leftVertex]:
      isTouched[leftVertex] = true
      touchedVertices.add leftVertex
    if not isTouched[rightVertex]:
      isTouched[rightVertex] = true
      touchedVertices.add rightVertex
    outDeg[leftVertex] += 1
    inDeg[rightVertex] += 1
    unionVertices(leftVertex, rightVertex)
  for vertex in touchedVertices:
    let imbalance = outDeg[vertex] - inDeg[vertex]
    if imbalance > 0:
      compImbalance[findRoot(vertex)] += imbalance
  var trailCount = 0
  for vertex in touchedVertices:
    if parent[vertex] == vertex:
      if compImbalance[vertex] > 0:
        trailCount += compImbalance[vertex]
      else:
        trailCount += 1
  appendOutput($(featureCount + trailCount))
  outputBuffer.add '\n'
  for vertex in touchedVertices:
    isTouched[vertex] = false
    outDeg[vertex] = 0
    inDeg[vertex] = 0
    compImbalance[vertex] = 0
    parent[vertex] = vertex

stdout.write outputBuffer
outputBuffer.setLen 0
```

## Complexity

Reading the input takes time proportional to its byte count. Each union costs nearly constant time, so one case takes O(n + v) time for n features and v used labels. Resetting touchedVertices costs O(v) per case. Output takes O(t) time for t cases. The total is O(B + n + v + t) for B input bytes. The tables use O(1000) integers, the input uses O(B) bytes, and the output buffer uses one block. A walk search over covered feature subsets costs O(v * 2^n) and cannot run on a large case.
