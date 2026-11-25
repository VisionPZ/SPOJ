# SDF4F — Praktikum 4 SDF F (SPOJ)

<https://www.spoj.com/problems/SDF4F/>

## Problem

Luffy visits N islands, and some pairs already have a bridge. He wants every island reachable from every other island, so he asks how many new bridges are needed.

Input starts with N and P, the island count and existing bridge count. The next P lines each give two connected island numbers from 1 to N. Output one integer, the number of bridges still to build.

| item | bound |
|---|---|
| islands N | fits in integer range |
| bridges P | fits in integer range |
| judge limit | 1000 ms, 1536 MB |

Each new bridge joins two island groups, so the answer depends only on the group count.

Sample input:

```
5 2
1 3
2 4
```

Sample output:

```
2
```

The five islands start in three groups, and two bridges merge them into one.

## Idea

Treat each island group like a pile of connected blocks, then count the piles. One new bridge merges exactly two piles, like tying two stacks of papers with one clip.

The algorithm is a disjoint set with path compression. Each union costs nearly constant time, and the final pass finds one root per island. A traversal per island would still work, but it would repeatedly walk the same edges. Merge groups once, then count the merges needed.

## Why It Works

1. Islands in one connected group share the same root in the disjoint set.
2. An existing bridge makes its two endpoints share a root.
3. A new bridge can lower the group count by at most one.
4. Scanning islands in order and joining neighbours gives exactly one merge per extra group.

| term | meaning |
|---|---|
| `parent` | root index stored for each island |
| `findRoot` | returns the group root with path compression |
| `joinSets` | merges two different groups |
| `bridgeCount` | number of merges performed in the final pass |

The final pass turns group counting into a simple adjacent-pair scan.

The sample trace from the generator is:

```
islands: 1 2 3 4 5
existing: (1,3), (2,4)
groups: {1,3}, {2,4}, {5}
merge 1-3 groups, then 3-5 groups -> 2 bridges
```

The trace gives the same answer as the sample output.

## Code

**Input and helpers.** The reader loads stdin once and builds the disjoint set operations.

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

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

proc joinSets(parent: var seq[int], firstNode, secondNode: int) =
  let firstRoot = findRoot(parent, firstNode)
  let secondRoot = findRoot(parent, secondNode)
  if firstRoot != secondRoot:
    parent[firstRoot] = secondRoot
```

`findRoot` shortens paths while it walks, so later lookups stay cheap.
`joinSets` writes only when two roots differ.
Both helpers work on zero-based island indexes.

**Merging and output.** The program applies existing bridges, then counts the merges still needed.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let islandCount = nextInt(inputData, scanPos)
let connectionCount = nextInt(inputData, scanPos)
var parent = newSeq[int](islandCount)
for islandIndex in 0 .. islandCount - 1:
  parent[islandIndex] = islandIndex
for connectionIndex in 0 .. connectionCount - 1:
  let firstIsland = nextInt(inputData, scanPos) - 1
  let secondIsland = nextInt(inputData, scanPos) - 1
  joinSets(parent, firstIsland, secondIsland)
var bridgeCount = 0
for islandIndex in 0 .. islandCount - 2:
  if findRoot(parent, islandIndex) != findRoot(parent, islandIndex + 1):
    joinSets(parent, islandIndex, islandIndex + 1)
    bridgeCount += 1
appendOutput($bridgeCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Input island numbers are shifted down by one for array indexing.
The adjacent pass performs one join for each missing connection.
The answer is written once after the buffer fill.

## Complexity

The work splits into setup, merges, and output.

| phase | time | space |
|---|---|---|
| input read | one pass over input tokens | one input string |
| setup | one entry per island | N parent entries |
| merge | near constant per bridge and pair | disjoint set arrays |
| output | one line | block buffer |

Setup and output are linear, and merges dominate the constant work.

| measure | Big O |
|---|---|
| time | O((N + P) alpha(N)) |
| space | O(N) |

Rebuilding adjacency and running a traversal per island would repeat work. Merge once with a disjoint set, then count the remaining groups.
