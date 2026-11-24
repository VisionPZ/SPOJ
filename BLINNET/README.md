## Problem

Read several test cases. Each case lists cities with their neighbours and connection costs. Print the least cost that connects every city, one answer per case.

The statement and judge table give these bounds.

| item | bound |
|---|---|
| test cases | at most 10 |
| cities per case | at most 10 000 |
| city name length | at most 10 lowercase letters |
| connection cost | positive, total at most 2^32 - 1 |
| judge limit | 4000 ms, 1536 MB |

The graph can be dense, so the program stores edges in one flat array.

## Idea

Build one flat list of connections, sort it by cost, then run Kruskal's algorithm (a minimum spanning tree method). A union-find table holds the groups of cities already joined. Each accepted connection joins two different groups, and the loop stops after n - 1 connections.

Cost per connection: one sort comparison plus nearly constant union-find work.

## Why It Works

A sorted list makes each accepted connection the cheapest one crossing its cut, which is safe for a minimum spanning tree. A connection with both ends in one group would form a cycle, so the program skips it. A reverse copy of a connection meets the same test and is skipped too.

One decision uses these terms.

| term | meaning |
|---|---|
| `findRoot` | the group that currently holds the city |
| `firstRoot == secondRoot` | both ends share a group, so skip the connection |
| `treeEdges == cityCount - 1` | the spanning tree is complete, so stop |

Union by rank keeps each find short even on a large case.

This trace uses the four-city sample. The input lists both directions of each connection.

| cost | connection | decision | tree cost | edges |
|---|---|---|---|---|
| 1 | gdansk - bydgoszcz | accept | 1 | 1 |
| 1 | bydgoszcz - gdansk | reject, same group | 1 | 1 |
| 1 | bydgoszcz - torun | accept | 2 | 2 |
| 1 | torun - bydgoszcz | reject, same group | 2 | 2 |
| 1 | torun - warszawa | accept | 3 | 3 |
| 1 | warszawa - torun | stop, tree complete | 3 | 3 |

The tree cost is 3, which matches the sample output.

## Code

**Setup and input.**

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
```

`flushBlockBytes` is 128 KiB. The read loop runs to EOF, so all input lands in one string. Cost: one pass over the input bytes.

**Digit scanner.**

```nim
proc nextInt(): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value
```

The scanner skips bytes below a space, then accumulates digits by index. `i` is shared state, so no token object is built. Cost: one pass over each number's digits.

**Word reader.**

```nim
proc nextWord(): string =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var j = i
  while i < inputData.len and inputData[i] > ' ': i = i + 1
  return inputData[j .. i - 1]
```

The loop stops at the next whitespace byte. The caller discards each city name, since the neighbour indices identify cities. Cost: one slice per name.

**Union-find.**

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
```

`findRoot` walks to the root, then rewrites each visited pointer to that root. The second walk compresses the path for later calls. Cost: nearly constant work per call.

**Connection type and order.**

```nim
type Connection = tuple[connectionCost: int; firstCity: int; secondCity: int]

proc cheaperConnection(first, second: Connection): int =
  if first.connectionCost < second.connectionCost: return -1
  if first.connectionCost > second.connectionCost: return 1
  return 0
```

`cheaperConnection` compares only the cost field. Ties keep the input order, which is safe for a spanning tree. Cost: one comparison per sort step.

**Input for one case.**

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
```

The loop runs once per test case. Each neighbour pair adds one connection with its cost and both endpoint indices. `edgeTotal` counts the pairs, including reverse copies. Cost: one add per listed neighbour.

**Kruskal loop.**

```nim
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
```

The sort runs once per case over `connectionList`. The scan walks positions from 0 to `edgeTotal - 1` and stops at `treeEdges == cityCount - 1`. The same-root test rejects cycles and duplicate edges. Cost: O(E log E) per case.

**Output.**

```nim
  outputBuffer.add $treeCost
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

Each case writes one line to `outputBuffer`. `setLen 0` reuses the buffer, and the final write covers the tail. Cost: one answer per case.

## Complexity

Costs by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| one case, sorting | O(E log E) | E connections |
| one case, union-find | O(E alpha(V)) | V roots and ranks |
| output | one write per 128 KiB block | 128 KiB |

The sort dominates the run, since alpha(V) stays tiny.

Big O terms:

| measure | form |
|---|---|
| time | O(E log E) per case |
| space | O(V + E) per case |

Both measures scale with the edge list, not with name lengths.

Trying spanning trees one by one is exponential. Prim's method with an adjacency matrix costs O(V^2) time per case, which is worse on sparse graphs.
