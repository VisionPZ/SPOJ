# BLINNET — Bytelandian Blingors Network (SPOJ)
<https://www.spoj.com/problems/BLINNET/>

## Problem

Byteland's cities need a new communication network. Each possible link has a known cost, and the goal is to join every city as cheaply as possible. Print that minimum cost for each network.

Input starts with a case count. Each case gives a city count, then one block per city: its name, its neighbour count, and each neighbour index with a link cost. Both directions of a link appear in the input. Output one cost per case.

The statement and judge table give these bounds:

| Item | Bound |
| --- | --- |
| Test cases | at most 10 |
| Cities per case | at most 10,000 |
| City name length | at most 10 lowercase letters |
| Link cost | positive, total at most 2^32 - 1 |
| Time limit | 4000 ms |
| Memory limit | 1536 MB |

The graph can be dense, so the program stores edges in one flat array.

The sample input and output:

```
2
4
gdansk
2
2 1
3 3
bydgoszcz
3
1 1
3 1
4 4
torun
3
1 3
2 1
4 1
warszawa
2
2 4
3 1
3
ixowo
2
2 1
3 3
iyekowo
2
1 1
3 7
zetowo
2
1 3
2 7
```

```
3
4
```

The four-city case needs three links of cost one each.

## Idea

Sort every link by cost, then join cities with Kruskal's algorithm (a minimum spanning tree method). A union-find table (a structure that tracks which cities share a group) decides whether a link joins two different groups. Accept that link and stop after cityCount minus one accepts.

Each edge costs one sort comparison plus almost constant union-find work. Trying all spanning trees would take exponential time, and a heap-based Prim run needs extra per-case state. Sorted edges keep the whole decision in one pass.

Takeaway: cheapest link first, skip cycles, stop at n - 1 links.

## Why It Works

1. The cheapest link crossing a group boundary is safe to accept, by the cut property of minimum spanning trees.
2. A link whose ends share a group would close a cycle, so the program skips it.
3. A reversed copy of a link meets the same test and is skipped as well.
4. `findRoot` compresses the path to the group leader, which keeps later finds short.
5. Union by rank attaches the smaller tree, which bounds the depth.

The decision uses these terms.

| Term | Meaning |
| --- | --- |
| `findRoot` | the group that currently holds a city |
| `firstRoot == secondRoot` | both ends share a group, so skip the link |
| `rankLevel` | tree height guess used to choose the new leader |
| `treeEdges == cityCount - 1` | the spanning tree is complete, so stop |

Every accepted link lowers the group count by one.

A script traced the sorted links of the four-city case:

| Cost | Link | Decision | Tree cost | Links kept |
| --- | --- | --- | --- | --- |
| 1 | gdansk - bydgoszcz | accept | 1 | 1 |
| 1 | bydgoszcz - gdansk | reject, same group | 1 | 1 |
| 1 | bydgoszcz - torun | accept | 2 | 2 |
| 1 | torun - warszawa | accept | 3 | 3 |
| 3 | gdansk - torun | reject, same group | 3 | 3 |

The loop stops once three links connect four cities.

## Code

**Input and scanners.**
```nim
import sequtils
import algorithm

const flushBlockBytes = 1 shl 17

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0

proc nextInt(): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

proc nextWord(): string =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var j = i
  while i < inputData.len and inputData[i] > ' ': i = i + 1
  return inputData[j .. i - 1]
```
The line loop gathers all input into `inputData`. `nextInt` walks digits, and `nextWord` returns a city name slice. `nextWord` discards the name, since array indices identify cities.

**Union-find and link type.**
```nim
var parentIndex: seq[int]
var rankLevel: seq[int]

proc findRoot(vertex: int): int =
  var walker = vertex
  while parentIndex[walker] != walker: walker = parentIndex[walker]
  var climber = vertex
  while parentIndex[climber] != walker:
    var nextCity = parentIndex[climber]
    parentIndex[climber] = walker
    climber = nextCity
  return walker

type Connection = tuple[connectionCost: int; firstCity: int; secondCity: int]

proc cheaperConnection(first, second: Connection): int =
  if first.connectionCost < second.connectionCost: return -1
  if first.connectionCost > second.connectionCost: return 1
  return 0
```
`findRoot` follows parent pointers, then rewrites the path to the leader. `Connection` stores cost and both city indices. `cheaperConnection` gives the sort its ordering.

**Kruskal driver.**
```nim
var connectionList: seq[Connection]

var testCount = nextInt()
var outputBuffer: string
for _ in 1 .. testCount:
  var cityCount = nextInt()
  connectionList = newSeq[Connection]()
  for j in 0 .. cityCount - 1:
    discard nextWord()
    var neighbourCount = nextInt()
    for _ in 1 .. neighbourCount:
      var neighbourIndex = nextInt() - 1
      var connectionCost = nextInt()
      connectionList.add (connectionCost, j, neighbourIndex)
  var edgeTotal = connectionList.len
  sort(connectionList, cheaperConnection)
  parentIndex = repeat(0, cityCount)
  rankLevel = repeat(0, cityCount)
  for j in 0 .. cityCount - 1: parentIndex[j] = j
  var treeCost = 0
  var treeEdges = 0
  for j in 0 .. edgeTotal - 1:
    var connectionCost = connectionList[j].connectionCost
    var firstRoot = findRoot(connectionList[j].firstCity)
    var secondRoot = findRoot(connectionList[j].secondCity)
    if firstRoot == secondRoot: continue
    if rankLevel[firstRoot] < rankLevel[secondRoot]:
      swap(firstRoot, secondRoot)
    parentIndex[secondRoot] = firstRoot
    if rankLevel[firstRoot] == rankLevel[secondRoot]: rankLevel[firstRoot] += 1
    treeCost = treeCost + connectionCost
    treeEdges = treeEdges + 1
    if treeEdges == cityCount - 1: break
  outputBuffer.add $treeCost
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```
Each case reads all neighbour blocks into `connectionList`. The list is sorted once, then each link is tested. `treeCost` accumulates the accepted costs, and `treeEdges` ends the loop.

## Complexity

Work is dominated by sorting the links.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Link collection | O(E) | E links |
| Sort | O(E log E) | same array |
| Union-find passes | nearly O(E) | two arrays of n |
| Output | one write per block | flushBlockBytes |

The union-find work grows almost linearly with the link count.

| Measure | Big O |
| --- | --- |
| Time per case | O(E log E) |
| Space per case | O(E + n) |

Enumerating spanning trees would be exponential, while sorted links settle each case in one sort and one scan.
