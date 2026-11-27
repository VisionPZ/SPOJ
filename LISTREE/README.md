# LISTREE — LIS and tree (SPOJ)

<https://www.spoj.com/problems/LISTREE/>

## Problem

A tree has N vertices labeled 1 through N without repeats. Every simple path gives a sequence of labels in path order. Report the largest longest-increasing-subsequence length over all those paths.

The first line holds the test count. Each case gives N and then N-1 tree edges. Print one answer per case.

| item | bound |
|---|---|
| test cases | 1 to 1000 |
| vertices N | 1 to 100000 |
| input file size | at most 2 MB |
| judge limit | 2000 ms, 1536 MB |

The number of simple paths drives the search design.

Sample input:

```
2
12
3 1
1 4
4 12
12 8
4 5
5 11
5 6
5 2
3 9
9 10
9 7
12
1 8
8 6
8 3
3 12
3 10
3 5
5 4
5 2
1 9
9 11
9 7
```

Sample output:

```
4
5
```

## Idea

Think of each starting vertex as the first card in a hand, then walk every route and lay down more cards, like dealing along a branching path. Patience sorting reads each route in order and keeps the smallest useful tail for every subsequence length. The largest length seen over all routes is the answer.

The search starts once from each vertex and walks every simple path with backtracking. Each visited prefix produces one LIS length. Enumerating subsequences separately would multiply the work again.

## Why It Works

1. Every simple path starts at some vertex and visits each later vertex once.
2. Starting from each vertex and walking all branches enumerates every path.
3. The parent check prevents revisiting a vertex on the same walk.
4. Patience sorting keeps one tail value per subsequence length.
5. A new label replaces the first tail that is not smaller than it.
6. The tail count after the last vertex equals that path's LIS length.

| term | meaning |
|---|---|
| `treeAdjacency` | neighbor lists for the tree |
| `currentPath` | vertices on the walk from the start |
| `subsequenceLength` | patience-sorting length for one path prefix |
| `bestLength` | largest length seen over every path |

Patience sorting gives the same length as the slower pairwise recurrence.

A script-generated trace from the second sample tree:

```
path: 2 5 3 8 1 9 11
increasing picks: 2 3 8 9 11
length: 5
```

The trace matches the second sample output.

## Code

**Input and scanner.** The reader loads all tokens and extracts integers by hand.

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

The scanner ignores whitespace between edges.
Vertex numbers are decremented to zero-based indexes.
The buffer constant serves the output path.

**Buffered output.** All answers accumulate in one string.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after a large block fills.
Individual answers cause no write.
A final write flushes leftover text.

**Path walk.** Patience sorting runs on every prefix of every path.

```nim
var treeAdjacency = newSeq[seq[int]](0)
var vertexLabels = newSeq[int](0)
var bestLength = 1

proc subsequenceLength(path: seq[int]): int =
  var tails = newSeq[int](0)
  for vertexIndex in path:
    let labelValue = vertexLabels[vertexIndex]
    var lowIndex = 0
    var highIndex = tails.len
    while lowIndex < highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if tails[middleIndex] < labelValue:
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex
    if lowIndex == tails.len:
      tails.add labelValue
    else:
      tails[lowIndex] = labelValue
  return tails.len

proc explorePaths(currentNode: int, parentNode: int, path: var seq[int]) =
  path.add currentNode
  let currentLength = subsequenceLength(path)
  if currentLength > bestLength:
    bestLength = currentLength
  for neighborNode in treeAdjacency[currentNode]:
    if neighborNode != parentNode:
      explorePaths(neighborNode, currentNode, path)
  path.setLen(path.len - 1)
```

The walk skips only the edge it came from.
Backtracking restores the path before the next branch.
The tail array is rebuilt for each prefix.

**Case driver.** Each case builds the tree and starts one walk per vertex.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  treeAdjacency = newSeq[seq[int]](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    treeAdjacency[vertexIndex] = newSeq[int](0)
  for edgeIndex in 0 .. vertexCount - 2:
    let firstVertex = nextInt(inputData, scanPos) - 1
    let secondVertex = nextInt(inputData, scanPos) - 1
    treeAdjacency[firstVertex].add secondVertex
    treeAdjacency[secondVertex].add firstVertex
  vertexLabels = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    vertexLabels[vertexIndex] = vertexIndex + 1

  bestLength = 1
  var currentPath = newSeq[int](0)
  for startVertex in 0 .. vertexCount - 1:
    explorePaths(startVertex, -1, currentPath)

  appendOutput($bestLength)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each vertex label equals its input number.
The walk limit is one start per vertex.
The best length is written once per case.

## Complexity

Each start walks every simple path, and patience sorting reads each path prefix.

| phase | time | space |
|---|---|---|
| input read | one pass over all edges | one input string |
| path walk | one walk per start vertex | path and adjacency arrays |
| LIS per prefix | binary search over the prefix tails | tail array |
| output | one line per case | block buffer |

The path walk dominates the total work.

| measure | Big O |
|---|---|
| time | O(N^2 log N) in the worst case |
| space | O(N) |

Testing every subsequence of every path would cost exponential time. Patience sorting reduces each path prefix to one binary-search pass.
