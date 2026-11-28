# ADATOMEL — Ada and Tomel (SPOJ)
<https://www.spoj.com/problems/ADATOMEL/>

## Problem

For each query, take the union of three paths in a rooted tree and count the distinct fruit flavors on it. The tree is built from a parent list, and every node carries one flavor from 1 to K. Paths include both endpoints.

The first line gives `nodeCount`, `flavorCount`, and `queryCount`. The next line has `nodeCount − 1` parent numbers, then one line of flavors. Each of the next `queryCount` lines holds six node numbers: two endpoints per path. Print one count per query.

| item | bound |
|---|---|
| nodes and queries | 1 to 300000 |
| flavors K | 1 to 1000 |
| node numbers | 0 to `nodeCount − 1` |
| judge limit | 2000 ms, 1536 MB |

Node i has parent `Pi` with `Pi < i`. Node 0 is the root.

Sample input:

```
5 2 5
0 0 0 2
1 1 1 1 2
3 2 3 1 1 4
1 0 2 4 2 3
2 1 4 3 1 0
1 3 3 0 3 1
4 2 0 3 4 1
```

Sample output:

```
2
2
2
1
2
```

## Idea

Each upward jump carries a pre-packed bag of flavors, like grabbing a packed lunch for every flight of stairs. Store those bags as 16 machine words, one bit per flavor. Binary lifting gives a bag for every power-of-two jump from every node. Split each path at its common ancestor, merge the bags along both sides, and count set bits. Walking every path node costs linear time per query; jumping covers the same nodes with logarithmic merges. Pack once, jump fast, and count bits.

## Why It Works

1. A path between two nodes splits at their lowest common ancestor into two upward walks.
2. Binary lifting writes any upward walk as at most one jump per bit of the depth gap.
3. The bag for a jump holds every flavor on the nodes covered by that jump.
4. Sixteen 64-bit words cover 1000 flavors, so one merge handles the whole universe.
5. Merging three paths with OR gives the flavor set of their union.
6. Counting set bits in the merged words gives the number of distinct flavors.

These names carry the main data.

| term | meaning |
|---|---|
| `ancestors` | jumped-to node for each power of two |
| `jumpBits` | flavor bag for each node and jump level |
| `queryWords` | merged bag for the current query |
| `findCommonAncestor` | routine that finds the split point of a path |
| `addUpwardPath` | routine that merges bags along one side |

A jump bag stops immediately before its destination, so the ancestor flavor is added once by the path routine.

A script-generated trace of the first sample uses flavors 1 for nodes 0 to 3 and flavor 2 for node 4:

| query | three paths | flavors found | answer |
|---|---|---|---|
| 3-2, 3-1, 1-4 | 3-2; 3-2-1-0; 1-0-2-4 | 1, 2 | 2 |
| 1-0, 2-4, 2-3 | 1-0; 2-4; 2-3 | 1, 2 | 2 |
| 2-1, 4-3, 1-0 | 2-1; 4-2-3; 1-0 | 1, 2 | 2 |
| 1-3, 3-0, 3-1 | 1-0-2-3; 3-2-0; 3-2-1 | 1 | 1 |
| 4-2, 0-3, 4-1 | 4-2; 0-2-3; 4-2-1 | 1, 2 | 2 |

The last column matches the sample output.

The root points to itself, so jumps above the root stay valid. Words beyond the flavor universe remain zero and add nothing.

## Code

**Reader and bit count.** The scanner reads all tokens, and a SWAR routine counts set bits.

```nim
const flushBlockBytes = 1 shl 17
const flavorWords = 16

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

proc countBits(value: uint64): int =
  var packedBits = value
  packedBits = packedBits - ((packedBits shr 1) and 0x5555555555555555'u64)
  packedBits = (packedBits and 0x3333333333333333'u64) + ((packedBits shr 2) and 0x3333333333333333'u64)
  packedBits = (packedBits + (packedBits shr 4)) and 0x0f0f0f0f0f0f0f0f'u64
  return int((packedBits * 0x0101010101010101'u64) shr 56)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The parser skips spaces and newlines.
The SWAR masks gather bit counts into the top byte.

**Tree input.** Parent numbers, depths, and flavors are read in order.

```nim
let nodeCount = nextInt(inputData, scanPos)
let flavorCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)

var parentNodes = newSeq[int](nodeCount)
var depths = newSeq[int](nodeCount)
parentNodes[0] = 0
for nodeIndex in 1 .. nodeCount - 1:
  let parentNode = nextInt(inputData, scanPos)
  parentNodes[nodeIndex] = parentNode
  depths[nodeIndex] = depths[parentNode] + 1
var flavors = newSeq[int](nodeCount)
for node in 0 .. nodeCount - 1:
  flavors[node] = nextInt(inputData, scanPos) - 1
```

Parent indices are smaller than child indices, so depths follow directly.
Flavours are stored with zero as the first bit.

**Jump tables.** Ancestor links and flavor bags are built one level at a time.

```nim
var liftLevels = 1
while (1 shl liftLevels) <= nodeCount:
  liftLevels += 1
var ancestors = newSeq[int](nodeCount * liftLevels)
var jumpBits = newSeq[uint64](nodeCount * liftLevels * flavorWords)
for node in 0 .. nodeCount - 1:
  let baseSlot = node * liftLevels
  ancestors[baseSlot] = parentNodes[node]
  let flavorIndex = flavors[node]
  jumpBits[baseSlot * flavorWords + flavorIndex div 64] =
    jumpBits[baseSlot * flavorWords + flavorIndex div 64] or (1'u64 shl (flavorIndex mod 64))
for level in 1 .. liftLevels - 1:
  for node in 0 .. nodeCount - 1:
    let earlierAncestor = ancestors[node * liftLevels + level - 1]
    ancestors[node * liftLevels + level] = ancestors[earlierAncestor * liftLevels + level - 1]
    let currentSlot = (node * liftLevels + level) * flavorWords
    let previousSlot = (node * liftLevels + level - 1) * flavorWords
    let ancestorSlot = (earlierAncestor * liftLevels + level - 1) * flavorWords
    jumpBits[currentSlot] = jumpBits[previousSlot] or jumpBits[ancestorSlot]
    jumpBits[currentSlot + 1] = jumpBits[previousSlot + 1] or jumpBits[ancestorSlot + 1]
    jumpBits[currentSlot + 2] = jumpBits[previousSlot + 2] or jumpBits[ancestorSlot + 2]
    jumpBits[currentSlot + 3] = jumpBits[previousSlot + 3] or jumpBits[ancestorSlot + 3]
    jumpBits[currentSlot + 4] = jumpBits[previousSlot + 4] or jumpBits[ancestorSlot + 4]
    jumpBits[currentSlot + 5] = jumpBits[previousSlot + 5] or jumpBits[ancestorSlot + 5]
    jumpBits[currentSlot + 6] = jumpBits[previousSlot + 6] or jumpBits[ancestorSlot + 6]
    jumpBits[currentSlot + 7] = jumpBits[previousSlot + 7] or jumpBits[ancestorSlot + 7]
    jumpBits[currentSlot + 8] = jumpBits[previousSlot + 8] or jumpBits[ancestorSlot + 8]
    jumpBits[currentSlot + 9] = jumpBits[previousSlot + 9] or jumpBits[ancestorSlot + 9]
    jumpBits[currentSlot + 10] = jumpBits[previousSlot + 10] or jumpBits[ancestorSlot + 10]
    jumpBits[currentSlot + 11] = jumpBits[previousSlot + 11] or jumpBits[ancestorSlot + 11]
    jumpBits[currentSlot + 12] = jumpBits[previousSlot + 12] or jumpBits[ancestorSlot + 12]
    jumpBits[currentSlot + 13] = jumpBits[previousSlot + 13] or jumpBits[ancestorSlot + 13]
    jumpBits[currentSlot + 14] = jumpBits[previousSlot + 14] or jumpBits[ancestorSlot + 14]
    jumpBits[currentSlot + 15] = jumpBits[previousSlot + 15] or jumpBits[ancestorSlot + 15]
```

Each higher bag combines two bags from the level below.
The sixteen word updates are written out to keep the build tight.

**Path merging.** Each path contributes its upward bags and one ancestor flavor.

```nim
var queryWords = newSeq[uint64](flavorWords)

proc mergeJump(jumpSlot: int) =
  let baseSlot = jumpSlot * flavorWords
  queryWords[0] = queryWords[0] or jumpBits[baseSlot]
  queryWords[1] = queryWords[1] or jumpBits[baseSlot + 1]
  queryWords[2] = queryWords[2] or jumpBits[baseSlot + 2]
  queryWords[3] = queryWords[3] or jumpBits[baseSlot + 3]
  queryWords[4] = queryWords[4] or jumpBits[baseSlot + 4]
  queryWords[5] = queryWords[5] or jumpBits[baseSlot + 5]
  queryWords[6] = queryWords[6] or jumpBits[baseSlot + 6]
  queryWords[7] = queryWords[7] or jumpBits[baseSlot + 7]
  queryWords[8] = queryWords[8] or jumpBits[baseSlot + 8]
  queryWords[9] = queryWords[9] or jumpBits[baseSlot + 9]
  queryWords[10] = queryWords[10] or jumpBits[baseSlot + 10]
  queryWords[11] = queryWords[11] or jumpBits[baseSlot + 11]
  queryWords[12] = queryWords[12] or jumpBits[baseSlot + 12]
  queryWords[13] = queryWords[13] or jumpBits[baseSlot + 13]
  queryWords[14] = queryWords[14] or jumpBits[baseSlot + 14]
  queryWords[15] = queryWords[15] or jumpBits[baseSlot + 15]

proc findCommonAncestor(firstNode, secondNode: int): int =
  var nodeLeft = firstNode
  var nodeRight = secondNode
  if depths[nodeLeft] < depths[nodeRight]:
    swap nodeLeft, nodeRight
  var depthGap = depths[nodeLeft] - depths[nodeRight]
  var level = 0
  while depthGap > 0:
    if (depthGap and 1) == 1:
      nodeLeft = ancestors[nodeLeft * liftLevels + level]
    depthGap = depthGap shr 1
    level += 1
  if nodeLeft == nodeRight:
    return nodeLeft
  for levelIndex in countdown(liftLevels - 1, 0):
    let leftParent = ancestors[nodeLeft * liftLevels + levelIndex]
    let rightParent = ancestors[nodeRight * liftLevels + levelIndex]
    if leftParent != rightParent:
      nodeLeft = leftParent
      nodeRight = rightParent
  return parentNodes[nodeLeft]

proc addUpwardPath(startNode, stopNode: int) =
  var currentNode = startNode
  var depthGap = depths[currentNode] - depths[stopNode]
  var level = 0
  while depthGap > 0:
    if (depthGap and 1) == 1:
      mergeJump(currentNode * liftLevels + level)
      currentNode = ancestors[currentNode * liftLevels + level]
    depthGap = depthGap shr 1
    level += 1

proc addWholePath(firstNode, secondNode: int) =
  let meetingNode = findCommonAncestor(firstNode, secondNode)
  addUpwardPath(firstNode, meetingNode)
  addUpwardPath(secondNode, meetingNode)
  let meetingFlavor = flavors[meetingNode]
  let wordOffset = meetingFlavor div 64
  queryWords[wordOffset] = queryWords[wordOffset] or (1'u64 shl (meetingFlavor mod 64))
```

Depth gaps select the jumps in binary order.
The meeting node contributes its flavor exactly once.

**Query loop.** Three paths are merged into one bag, then counted.

```nim
for queryIndex in 0 .. queryCount - 1:
  let firstBegin = nextInt(inputData, scanPos)
  let firstEnd = nextInt(inputData, scanPos)
  let secondBegin = nextInt(inputData, scanPos)
  let secondEnd = nextInt(inputData, scanPos)
  let thirdBegin = nextInt(inputData, scanPos)
  let thirdEnd = nextInt(inputData, scanPos)
  queryWords[0] = 0'u64
  queryWords[1] = 0'u64
  queryWords[2] = 0'u64
  queryWords[3] = 0'u64
  queryWords[4] = 0'u64
  queryWords[5] = 0'u64
  queryWords[6] = 0'u64
  queryWords[7] = 0'u64
  queryWords[8] = 0'u64
  queryWords[9] = 0'u64
  queryWords[10] = 0'u64
  queryWords[11] = 0'u64
  queryWords[12] = 0'u64
  queryWords[13] = 0'u64
  queryWords[14] = 0'u64
  queryWords[15] = 0'u64
  addWholePath(firstBegin, firstEnd)
  addWholePath(secondBegin, secondEnd)
  addWholePath(thirdBegin, thirdEnd)
  var distinctFlavors = 0
  for wordIndex in 0 .. flavorWords - 1:
    distinctFlavors += countBits(queryWords[wordIndex])
  appendOutput($distinctFlavors)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The bag is cleared before each query.
Each answer goes through the block buffer.

## Complexity

The jump table costs one bag per node and level, and each query merges only a few bags.

| phase | time | space |
|---|---|---|
| input read | one pass over parent and flavor lists | one input string |
| jump table | 16 words per node and level | ancestor and bag tables |
| common ancestor | one pass over levels per path | none |
| query merge | 16 words per selected jump | one merged bag |
| output | one line per query | block buffer |

The bag size of 16 words is fixed by the flavor limit.

| measure | Big O |
|---|---|
| time | O((N + Q) log N * K / 64) |
| space | O(N log N * K / 64) |

Walking each path node would cost O(N) per query and fail on long paths.

Prepack flavor bags for jumps, then merge a logarithmic number of them per query.
