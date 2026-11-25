# TRANCLS — Transitive Closure (SPOJ)

<https://www.spoj.com/problems/TRANCLS/>

## Problem

A relation is a set of ordered pairs. When a path of pairs leads from a to b and from b to c, the pair (a, c) must also exist. Report how many missing pairs must be added.

Each case gives the pair count N, then N pairs with endpoints from 0 to N-1. Print `Case #i: X` where X is the number of pairs to add.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| pair count N | 1 to 100 |
| endpoint range | 0 to N-1 |
| judge limit | 1000 ms, 1536 MB |

Repeated pairs count once.

Sample input:

```
3
4
0 1
1 2
2 3
1 3
2
0 1
1 0
1
0 0
```

Sample output:

```
Case #1: 2
Case #2: 2
Case #3: 0
```

## Idea

Think of towns linked by one-way roads: every pair of towns connected by a route must also have a direct road.

The program builds the adjacency matrix, then runs Floyd-Warshall style transitive closure. For each intermediate vertex it merges reachable rows. Each triple of vertices costs constant work, so one case costs O(N^3).

Walking every possible path separately would repeat the same work many times.

The boolean matrix merge gives the closure in one cubic pass.

## Why It Works

1. A stored pair is a direct edge between two vertices.
2. A transitive closure adds every pair joined by a path.
3. Floyd-Warshall processes vertices one at a time as intermediates.
4. After using intermediate k, row i contains every destination reachable through k.
5. The OR of two boolean rows is the union of reachable sets.
6. Missing pairs are closure entries that were not direct edges.

| term | meaning |
|---|---|
| `originalPairs` | direct pairs from the input |
| `reachablePairs` | pairs reachable after closure |
| `viaVertex` | current intermediate vertex |
| `missingPairs` | count of pairs to add |

Duplicates collapse because the matrix stores booleans.

A script trace uses sample case 1:

```
direct pairs     0->1 1->2 2->3 1->3
closure adds     0->2 through 1
closure adds     0->3 through 2
missing count    2
```

The trace matches the first sample answer.

## Code

**Input and scanning.** The reader builds the direct-pair matrix.

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

The scanner ignores spaces and newlines.
Both matrices start as all false.
A repeated pair leaves the matrix unchanged.

**Closure and count.** The triple loop merges reachable rows.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pairCount = nextInt(inputData, scanPos)
  var originalPairs = newSeq[seq[bool]](pairCount)
  var reachablePairs = newSeq[seq[bool]](pairCount)
  for vertex in 0 .. pairCount - 1:
    originalPairs[vertex] = newSeq[bool](pairCount)
    reachablePairs[vertex] = newSeq[bool](pairCount)
    for neighbor in 0 .. pairCount - 1:
      originalPairs[vertex][neighbor] = false
      reachablePairs[vertex][neighbor] = false
  for pairIndex in 0 .. pairCount - 1:
    let startVertex = nextInt(inputData, scanPos)
    let endVertex = nextInt(inputData, scanPos)
    originalPairs[startVertex][endVertex] = true
    reachablePairs[startVertex][endVertex] = true
  for viaVertex in 0 .. pairCount - 1:
    for startVertex in 0 .. pairCount - 1:
      if reachablePairs[startVertex][viaVertex]:
        for endVertex in 0 .. pairCount - 1:
          if reachablePairs[viaVertex][endVertex]:
            reachablePairs[startVertex][endVertex] = true
  var missingPairs = 0
  for startVertex in 0 .. pairCount - 1:
    for endVertex in 0 .. pairCount - 1:
      if reachablePairs[startVertex][endVertex] and not originalPairs[startVertex][endVertex]:
        missingPairs += 1
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $missingPairs)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The intermediate loop comes outermost.
A row merge runs only when the intermediate is reachable.
The final loop counts closure entries absent from the input.

## Complexity

Each intermediate vertex may merge each row with each column.

| phase | time | space |
|---|---|---|
| input read | one pass over pairs | one input string |
| closure | N cubed boolean tests | two N by N matrices |
| comparison | N squared pairs | constant extra space |

Both matrices use N squared boolean slots.

| measure | Big O |
|---|---|
| time per case | O(N^3) |
| space per case | O(N^2) |

Searching each path separately can cost far more than the cubic merge.

The matrix closure is the takeaway.
