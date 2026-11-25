# PRIMIT — Primitivus recurencis (SPOJ)

<https://www.spoj.com/problems/PRIMIT/>

## Problem

A biologist lists every consecutive pair seen in a creature's genetic code. Rebuild the shortest genetic code that contains all those pairs in order. The pairs alone do not tell you how the creature chained them together.

Input: `t` cases separated by blank lines. Each case starts with `n`, the number of distinct features, then `n` lines `l r`. Output: one integer per case, the length of the shortest code containing every feature.

The bounds from the statement:

| Item | Bound |
|---|---|
| Endpoint values | 1 ≤ l, r ≤ 1000 |
| Features | distinct pairs, never `(p, p)` |
| Cases | separated by blank lines |
| Judge limit | 1600 ms, 1536 MB |

The input and output are large, so the program reads once and writes in blocks.

The sample input and output:

```
1
12
2 3
3 9
9 6
8 5
5 7
7 6
4 5
5 1
1 4
4 2
2 8
8 6
```

```
15
```

## Idea

Treat each feature as a one-way arrow between two numbers, then find the fewest arrows you must add to make one continuous walk. Think of connecting train legs into the shortest itinerary that visits every leg.

The program builds a directed graph and groups numbers with union-find (a table that merges sets sharing any arrow). Each number records an out-degree and an in-degree. A component needs as many extra starts as its total positive imbalance, or one start when already balanced.

The answer is the feature count plus those extra starts. Union-find runs in near-constant time per arrow, and the two passes over touched numbers cost O(V) with `V ≤ 1000`. Ordering all pairs by brute force would take factorial time.

Imbalance counts tell the code exactly how many extra walks it needs.

## Why It Works

Four facts carry the method.

1. An Euler trail (a walk using every edge once) starts where out-degree exceeds in-degree. It ends where the reverse holds.
2. A component whose positive imbalances sum to `P` needs `P` separate trails to cover every arrow. Each trail adds one new starting number to the code.
3. A component with zero imbalance still needs one trail, so it contributes one start.
4. Union-find groups all numbers joined by any feature. Clearing only touched numbers keeps components from leaking into the next case.

The values the program keeps:

| Term | Meaning |
|---|---|
| `outDeg`, `inDeg` | arrows leaving and entering a number |
| `compImbalance` | positive imbalance summed over a component |
| `findRoot` | union-find representative of a component |
| `trailCount` | number of extra starting points needed |

One component with positive imbalance `P` adds exactly `P` starts.

A script-traced example with the twelve sample features:

```
vertex   1   2   3   4   5   6   7   8   9
out-in   0  +1   0  +1   0  -3   0  +1   0

positive imbalance sum = 1 + 1 + 1 = 3
all vertices share one component
trailCount = 3
answer = 12 features + 3 trails = 15
```

One shortest code of length 15 is `8 5 1 4 2 3 9 6 4 5 7 6 2 8 6`. Pairs `6 4` and `6 2` are the added bridges.

## Code

**Setup and scanner.** The input is read once, and vertex arrays stay fixed in size.

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

`vertexLimit = 1000` fixes the arrays. `nextInt` walks the buffer by index, so blank lines between cases cause no trouble.

**Degree and membership arrays.** All vertex state lives in fixed arrays.

```nim
var outDeg: array[0..vertexLimit, int]
var inDeg: array[0..vertexLimit, int]
var parent: array[0..vertexLimit, int]
var compImbalance: array[0..vertexLimit, int]
var isTouched: array[0..vertexLimit, bool]
var touchedVertices: seq[int]
for vertex in 0..vertexLimit:
  parent[vertex] = vertex
```

`isTouched` records which vertices need clearing after a case. `touchedVertices` holds their numbers, so reset costs one pass over used vertices only.

**Union-find.** `findRoot` compresses paths, and `unionVertices` merges two sets.

```nim
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

The first loop in `findRoot` climbs to the root. The second loop rewrites each visited pointer to that root. Each merge attaches one root under the other.

**Output helper.** Results gather in one buffer and flush in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The 256 KiB threshold keeps writes rare. `setLen 0` reuses the allocation after a flush.

**Case loop.** Each feature updates degrees and components, then the code counts trails.

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

Each arrow raises `outDeg` of its left vertex and `inDeg` of its right vertex. Positive imbalances accumulate at component roots. A root with no positive imbalance still adds one trail. The last loop restores every touched array for the next case.

## Complexity

Each case scans features, then walks only touched vertices.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Feature pass | O(n α(V)) with merges | O(V) |
| Imbalance pass | O(V) over touched vertices | O(1) |
| Reset | O(V) over touched vertices | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n α(V)) | O(V) |

With `V ≤ 1000`, every pass stays tiny.

| Measure | Big O |
|---|---|
| Time | O(n α(V)) per case, V ≤ 1000 |
| Space | O(V) for degree and union-find arrays |

`α` is the near-constant inverse Ackermann function from union-find.

Sorting the pairs into every possible order would take factorial time. Degree imbalance gives the same answer with one linear pass.
