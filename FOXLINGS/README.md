# FOXLINGS — Foxlings (SPOJ)

<https://www.spoj.com/problems/FOXLINGS/>

## Problem

A cracker given to one friend can be split and passed along friendship links. The minimum number of crackers equals the number of separate friend groups, with each lonely friend counted as a group.

Input starts with one line holding `nodeCount` and `friendshipCount`. Each of the next `friendshipCount` lines holds two distinct friend numbers. Output one integer, the minimum number of crackers.

The bounds from the statement:

| Item | Bound |
|---|---|
| Foxlings N | 1 to 1000000000 |
| Friendships M | 1 to 100000 |
| Friend numbers | 1 to N |
| Judge limit | 2000 ms, 1536 MB |

The large N bound affects the answer, not the memory, because only friends in a friendship need storage.

The sample input:

```
9 5
3 1
6 1
7 6
2 7
8 9
```

The sample output:

```
4
```

One cracker per group covers all nine numbered friends in the sample.

## Idea

One cracker spreads through a friendship group like ink through connected pipes, so the answer is the number of separate groups.

The algorithm is a disjoint-set union with path compression and size-based joins. Each friendship costs a constant number of steps after its two ends are compressed to small indexes. A naive grid of size N cannot be built because N reaches one billion, while at most two hundred thousand distinct numbers appear. Sort those numbers once, find each end by binary search, and count successful joins. The takeaway is that compressing the input makes the union structure small and fast.

## Why It Works

1. A cracker can be divided without limit and passed along any friendship path.
2. Therefore one cracker reaches every friend in a connected component.
3. Friends in different components share no path, so each component needs its own cracker.
4. A friend with no friendship is a component of size one and needs a cracker.
5. Starting from `uniqueCount` components, each successful join lowers `componentCount` by one.
6. Adding lonely friends as `nodeCount - int64(uniqueCount)` gives the full answer.

The main terms:

| Term | Meaning |
|---|---|
| `allIds` | every friend number seen in the friendships |
| `uniqueIds` | sorted friend numbers with duplicates removed |
| `parent` | representative index for each compressed friend |
| `componentCount` | current number of groups among seen friends |

The table shows that only distinct friend numbers occupy union-find slots.

The generator trace for the sample uses these visible values:

```
sorted unique ids: 1 2 3 6 7 8 9
distinct ids: 7
successful joins: (3,1) (6,1) (7,6) (2,7) (8,9)
components after joins: 2
lonely friends: 9 - 7 = 2
answer: 2 + 2 = 4
```

The trace reaches the sample output of four crackers.

## Code

**Input and scanning.** The reader loads the header and every friendship into arrays.

```nim
import algorithm

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

The loop reads M friendship pairs and keeps both endpoints.
Each number is built one digit at a time from the input string.
The scanner ignores line breaks and spaces.

**Output and compression.** The buffer batches the single answer, and duplicate friend numbers are removed after sorting.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let nodeCount = int64(nextInt(inputData, scanPos))
let friendshipCount = nextInt(inputData, scanPos)
var firstEndpoints = newSeq[int](friendshipCount)
var secondEndpoints = newSeq[int](friendshipCount)
var allIds = newSeq[int](friendshipCount * 2)
for pairIndex in 0 .. friendshipCount - 1:
  let firstId = nextInt(inputData, scanPos)
  let secondId = nextInt(inputData, scanPos)
  firstEndpoints[pairIndex] = firstId
  secondEndpoints[pairIndex] = secondId
  allIds[pairIndex * 2] = firstId
  allIds[pairIndex * 2 + 1] = secondId

proc compareIds(left: int, right: int): int =
  if left < right: return -1
  if left > right: return 1
  return 0

allIds.sort(compareIds)
var uniqueIds = newSeq[int](allIds.len)
var uniqueCount = 0
for index in 0 .. allIds.len - 1:
  if index == 0 or allIds[index] != allIds[index - 1]:
    uniqueIds[uniqueCount] = allIds[index]
    uniqueCount += 1
uniqueIds.setLen(uniqueCount)
```

Sorting uses an explicit comparator for the judge compiler.
The deduplication pass shrinks `uniqueIds` to the distinct friend count.
Both loops run over at most two hundred thousand numbers.

**Union-find and answer.** Binary search maps each endpoint, and each successful join lowers the group count.

```nim
proc findId(ids: seq[int], target: int): int =
  var low = 0
  var high = ids.len - 1
  while low <= high:
    let middle = (low + high) div 2
    if ids[middle] == target: return middle
    if ids[middle] < target: low = middle + 1
    else: high = middle - 1
  return -1

var parent = newSeq[int](uniqueCount)
var groupSize = newSeq[int](uniqueCount)
for index in 0 .. uniqueCount - 1:
  parent[index] = index
  groupSize[index] = 1

proc findRoot(node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

var componentCount = uniqueCount
for pairIndex in 0 .. friendshipCount - 1:
  let rootFirst = findRoot(findId(uniqueIds, firstEndpoints[pairIndex]))
  let rootSecond = findRoot(findId(uniqueIds, secondEndpoints[pairIndex]))
  if rootFirst != rootSecond:
    if groupSize[rootFirst] < groupSize[rootSecond]:
      parent[rootFirst] = rootSecond
      groupSize[rootSecond] += groupSize[rootFirst]
    else:
      parent[rootSecond] = rootFirst
      groupSize[rootFirst] += groupSize[rootSecond]
    componentCount -= 1

let crackerCount = int64(componentCount) + (nodeCount - int64(uniqueCount))
appendOutput($crackerCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Path compression keeps roots short, and size comparison keeps trees shallow.
The final sum uses int64 because N reaches one billion.
One buffered write emits the answer.

## Complexity

Sorting dominates the work, and the union passes are linear in the number of friendships.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over M pairs | endpoint arrays |
| Sorting and dedup | O(M log M) | sorted id array |
| Union-find | M binary searches and joins | parent and size arrays |
| Output | one line | block buffer |

The table shows that memory depends on M, not on N.

| Measure | Big O |
|---|---|
| Time | O(M log M) |
| Space | O(M) |

A naive array over all N friends would need a billion slots and cannot run under the memory cap. Compressing to distinct ids keeps both time and space tied to M.
