# ADABRANC — Ada and Branches (SPOJ)

<https://www.spoj.com/problems/ADABRANC/>

## Problem

For each traveller, count the fruits reachable from a starting fruit using only branches that carry the traveller's weight. A branch carries a traveller when its strength is at least that weight.

The input gives one case: `N` fruits, `M` branches, then `Q` travellers. Each branch line gives two fruit indexes and a strength. Each query line gives a starting fruit and a weight. Fruit indexes run from `0` to `N - 1`. Print one reachable count per query, in input order.

| Item | Bound |
|---|---|
| Fruits N | 2 to 100000 |
| Branches M | 1 to 200000 |
| Queries Q | 1 to 300000 |
| Branch strength | 1 to 100000 |
| Traveller weight | 1 to 100000 |
| Judge limit | 2000 ms, 1536 MB |

Parallel branches are allowed and never change reachability.

The sample case has four fruits and four branches:

```
4 4 3
1 2 4
2 3 3
3 0 4
0 1 3
1 3
1 4
1 5
```

The expected output is:

```
4
2
1
```

At weight three every branch works, at weight four only the strong pair of paths works.

## Idea

Add branches from strongest to weakest, like unlocking roads as a storm fades and watching neighborhoods merge. Use a disjoint-set union for the merged neighborhoods. Answer each traveller the moment the weight drops to that traveller's value. Sorting is replaced by buckets, because all strengths and weights are at most 100000.

## Why It Works

1. A traveller of weight `Y` may cross exactly the branches with strength at least `Y`.
2. Processing strengths downward makes the current union-find contain exactly those branches.
3. All queries with weight `Y` see the same union-find state.
4. A root's component size equals the number of fruits reachable from that root.
5. Answers stored by query index are printed in input order.

| Term | Meaning |
|---|---|
| `edgeHead` | first branch of each strength, using index plus one as a sentinel |
| `queryHead` | first query of each weight, with the same sentinel |
| `parent` | union-find parent for each fruit |
| `componentSize` | fruit count of the set rooted at each fruit |

Every bucket holds a singly linked list, so no comparison sort runs.

A short trace with the sample branches:

```
strength 4: join 1-2 and 3-0, sets {1,2} and {0,3}
weight 4 query at 1: size of {1,2} = 2
strength 3: join 2-3 and 0-1, all four fruits merge
weight 3 query at 1: size of {0,1,2,3} = 4
weight 5 query at 1: no branch added yet, answer 1
```

The trace matches the sample output lines in reverse strength order.

## Code

**Input and scanning.** The hand reader loads the whole case, and the sentinel check allows more than one case.

```nim
const flushBlockBytes = 1 shl 17
const maxCapacity = 100000

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner advances one index per number.
One output buffer serves all answer lines.
Large answers are flushed in blocks.

**Set operations.** Each merge attaches the smaller set to the larger one.

```nim
proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

proc unionComponents(parent: var seq[int], componentSize: var seq[int], firstNode: int, secondNode: int) =
  var firstRoot = findRoot(parent, firstNode)
  var secondRoot = findRoot(parent, secondNode)
  if firstRoot == secondRoot:
    return
  if componentSize[firstRoot] > componentSize[secondRoot]:
    swap firstRoot, secondRoot
  parent[firstRoot] = secondRoot
  componentSize[secondRoot] = componentSize[secondRoot] + componentSize[firstRoot]
```

Path compression shortens later root lookups.
Size-based attachment keeps trees shallow.
A repeated branch leaves both roots and sizes unchanged.

**Bucket build.** Branches and queries are placed in lists indexed by their weight.

```nim
while hasNextNumber(inputData, scanPos):
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var parent = newSeq[int](nodeCount)
  var componentSize = newSeq[int](nodeCount)
  for node in 0 .. nodeCount - 1:
    parent[node] = node
    componentSize[node] = 1
  var edgeHead = newSeq[int](maxCapacity + 1)
  var edgeNext = newSeq[int](edgeCount)
  var edgeFrom = newSeq[int](edgeCount)
  var edgeTo = newSeq[int](edgeCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    let capacity = nextInt(inputData, scanPos)
    edgeFrom[edgeIndex] = fromNode
    edgeTo[edgeIndex] = toNode
    edgeNext[edgeIndex] = edgeHead[capacity]
    edgeHead[capacity] = edgeIndex + 1
  var queryHead = newSeq[int](maxCapacity + 1)
  var queryNext = newSeq[int](queryCount)
  var queryStart = newSeq[int](queryCount)
  for queryIndex in 0 .. queryCount - 1:
    let startNode = nextInt(inputData, scanPos)
    let weight = nextInt(inputData, scanPos)
    queryStart[queryIndex] = startNode
    queryNext[queryIndex] = queryHead[weight]
    queryHead[weight] = queryIndex + 1
  var queryAnswer = newSeq[int](queryCount)
```

Storing index plus one makes zero a free-list sentinel.
Input order is kept through the query index arrays.
Every fruit starts as its own one-member set.

**Descending sweep.** One pass over strengths answers every query.

```nim
  var capacity = maxCapacity
  while capacity >= 1:
    var edgeLink = edgeHead[capacity]
    while edgeLink != 0:
      let edgeIndex = edgeLink - 1
      unionComponents(parent, componentSize, edgeFrom[edgeIndex], edgeTo[edgeIndex])
      edgeLink = edgeNext[edgeIndex]
    var queryLink = queryHead[capacity]
    while queryLink != 0:
      let queryIndex = queryLink - 1
      queryAnswer[queryIndex] = componentSize[findRoot(parent, queryStart[queryIndex])]
      queryLink = queryNext[queryIndex]
    capacity -= 1
  for queryIndex in 0 .. queryCount - 1:
    appendOutput($queryAnswer[queryIndex])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Merges happen before queries of the same strength.
The component size is the reachable fruit count.
The final flush writes the buffered answer lines.

## Complexity

Buckets replace sorting, and the sweep visits each branch and query once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over branches and queries | one input string |
| Bucket build | O(M + Q) | one link per item |
| Descending sweep | O(M + Q) plus union-find work | two union-find arrays |
| Output | one buffered pass over Q lines | block buffer |

Each array is sized by a stated bound, not by an input guess.

| Measure | Big O |
|---|---|
| Time | O(C + (M + Q) α(N)) |
| Space | O(C + N + M + Q) |

Here `C` is 100000, the largest strength or weight.
A fresh traversal per query would cost O(Q × (N + M)) instead, so the sweep wins.
