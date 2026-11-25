# MMCUT — Tree Cut (SPOJ)

<https://www.spoj.com/problems/MMCUT/>

## Problem

A star tree has one root and many leaf edges. Cut leaf edges so every given pair of vertices separates, then minimize the largest number of cut edges on any pair's path.

Input starts with `N M`. The root is vertex `N - 1`. The next `M` lines each give one distinct pair `si ti`.

Output one line with the minimum possible maximum cut count.

| item | bound |
|---|---|
| vertices N | 1 to 100000 |
| commodities M | 1 to 100000 |
| judge limit | 7601 ms, 1536 MB |

Every path has one or two leaf edges, so the answer is 1 or 2.

Sample input:

```
10 2
0 5
4 8
```

Sample output:

```
1
```

## Idea

Treat each leaf edge as a light switch, like flipping switches in a hallway. A pair with the root needs its leaf switch on. A leaf-to-leaf pair needs exactly one of its two switches on when the answer is 1. Those exact-one rules form a graph that must be two-colored.

The algorithm is bipartite coloring by iterative depth-first search. Each rule costs one edge in the constraint graph. Checking all rules once beats trying every cut set, which has exponentially many choices.

A conflict forces two cuts on some path, so the answer rises to 2.

## Why It Works

1. Every commodity path contains its leaf endpoints and no other leaf edge.
2. A root-involving commodity forces that leaf edge to be cut.
3. A leaf-to-leaf commodity needs at least one of its two edges cut.
4. Keeping the maximum at 1 means cutting exactly one of the two.
5. Exact-one is an inequality of opposite colors in the constraint graph.
6. A coloring conflict proves that answer 1 is impossible.

| term | meaning |
|---|---|
| `mustCut` | leaves forced by commodities that touch the root |
| `adjacency` | exact-one constraints between leaf vertices |
| `vertexColor` | chosen side of each leaf in the two-coloring |
| `coloringPossible` | false after any conflicting constraint |

The sample pairs `{0, 5}` and `{4, 8}` share no leaf, so answer 1 works.

A worked example with `N = 4` and pairs `0 1`, `1 2`, `0 2`:

```
pair 0 1 -> colors 0 and 1
pair 1 2 -> colors 1 and 0
pair 0 2 -> needs colors 0 and 2 opposite, but both equal 0
conflict -> answer 2
```

The third constraint closes an odd cycle and forces the higher answer.

## Code

**Input and output setup.** One read of stdin feeds the hand scanner, and one buffer collects the answer.

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

The scanner skips spaces and newlines without allocating tokens.
The output buffer flushes only after reaching the block size.
One final write releases the remaining bytes.

**Commodity parsing.** Root pairs force a cut; leaf pairs add an exact-one constraint.

```nim
let vertexCount = nextInt(inputData, scanPos)
let commodityCount = nextInt(inputData, scanPos)
let rootVertex = vertexCount - 1

var adjacency = newSeq[seq[int]](vertexCount)
var mustCut = newSeq[bool](vertexCount)

for commodityIndex in 0 .. commodityCount - 1:
  let firstVertex = nextInt(inputData, scanPos)
  let secondVertex = nextInt(inputData, scanPos)
  if firstVertex == rootVertex:
    mustCut[secondVertex] = true
  elif secondVertex == rootVertex:
    mustCut[firstVertex] = true
  else:
    adjacency[firstVertex].add secondVertex
    adjacency[secondVertex].add firstVertex
```

The root label follows directly from the vertex count.
Each commodity contributes either a forced leaf or one graph edge.
The parse loop runs once per commodity, so it stays linear.

**Two-coloring.** An explicit stack assigns opposite colors across each constraint edge.

```nim
var vertexColor = newSeq[int](vertexCount)
for vertexIndex in 0 .. vertexCount - 1:
  vertexColor[vertexIndex] = -1

var coloringPossible = true

proc colorComponent(startVertex: int, startColor: int): bool =
  var pending = newSeq[int]()
  pending.add startVertex
  vertexColor[startVertex] = startColor
  while pending.len > 0:
    let currentVertex = pending.pop()
    let wantedColor = 1 - vertexColor[currentVertex]
    for neighborVertex in adjacency[currentVertex]:
      if vertexColor[neighborVertex] == -1:
        vertexColor[neighborVertex] = wantedColor
        pending.add neighborVertex
      elif vertexColor[neighborVertex] != wantedColor:
        return false
  return true
```

Forced leaves start on color 1, which means cut.
Unvisited components may start on either color.
A repeated vertex with the wrong color ends the search early.

**Answer selection.** Forced leaves and remaining components are colored, then the minimum is written.

```nim
for leafVertex in 0 .. rootVertex - 1:
  if mustCut[leafVertex]:
    if vertexColor[leafVertex] == 0 or not colorComponent(leafVertex, 1):
      coloringPossible = false

if coloringPossible:
  for leafVertex in 0 .. rootVertex - 1:
    if vertexColor[leafVertex] == -1:
      if not colorComponent(leafVertex, 1):
        coloringPossible = false

var answer = 2
if commodityCount == 0:
  answer = 0
elif coloringPossible:
  answer = 1

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop handles every forced leaf before free components.
A conflict sets the flag, but the loops still finish safely.
The final newline goes out with the last buffer write.

## Complexity

Each commodity adds one edge or one forced leaf.

| phase | time | space |
|---|---|---|
| input read | one pass over M pairs | one input string |
| parsing | one step per commodity | adjacency arrays |
| coloring | one visit per vertex and edge | color stack |
| output | one line | block buffer |

Every vertex and constraint edge is visited once, so parsing and coloring dominate.

| measure | Big O |
|---|---|
| time | O(N + M) |
| space | O(N + M) |

Trying every cut set would take exponential time, while two-coloring settles the answer in one pass.
