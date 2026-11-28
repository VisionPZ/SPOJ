# UNTITLE1 — Untitled Problem II (SPOJ)

<https://www.spoj.com/problems/UNTITLE1/>

## Problem

A signed array evolves under range additions, and each query asks for the largest prefix sum `S_i` whose index lies in a given range. Here `S_i` is the sum of array entries `1` through `i`.

Input gives N, then N array values, then M operations. An update `0 x y k` adds `k` to entries `x` through `y`. A query `1 x y` asks for the maximum `S_i` with `x <= i <= y`. Output one line per query.

| item | bound |
|---|---|
| array length N | up to 50000 |
| operations M | up to 50000 |
| array and increment values | -10000 to 10000 |
| judge limit | 1000 ms, 1536 MB |

Both N and M reach 50000, so each operation needs sublinear work.

Sample input:

```
5
238 -9622 5181 202 -6943
5
1 3 4
0 5 5 4846
1 3 5
0 3 5 -7471
1 3 3
```

Sample output:

```
-4001
-4001
-11674
```

## Idea

Treat the array as shelves in a warehouse, each holding a fixed number of boxes. A full shelf gets a single sticky note recording the change, like marking the whole shelf at once. Only the two boundary shelves need individual repacking.

The algorithm is sqrt decomposition with lazy tags per block. Each block caches its prefix sums and largest prefix. A full-block update changes only the lazy tag and sum, then rebuilds that block on demand.

A per-element scan would cost O(N) per operation, which is too slow at M = 50000.

## Why It Works

1. Splitting the array into blocks of 512 entries leaves at most about 100 blocks for N = 50000.
2. An update touching a whole block changes every entry there by the same increment, so one lazy tag records it.
3. A partial block touches at most 512 entries, which are updated directly.
4. Rebuilding a block recomputes its prefix sums and its largest prefix in one pass.
5. A query joins full blocks by their cached sums and scans only the two boundary blocks.

| term | meaning |
|---|---|
| `blockWidth` | number of entries in one block, fixed at 512 |
| `blockLazy` | increment applied to every entry of a block |
| `blockPrefixes` | running sum from the block start to each entry |
| `blockBestPrefix` | largest running sum inside a block |
| `passedTotal` | sum of all entries before the block being scanned |

The sample first query reads prefix sums at indices 3 and 4:

```
S3 = 238 - 9622 + 5181 = -4203
S4 = -4203 + 202 = -4001
maximum of S3 and S4 = -4001
```

The third query asks for `S3` after two updates and returns `-11674`.

## Code

**Input and layout.** The scanner accepts negative numbers and the block arrays are sized once.

```nim
const flushBlockBytes = 1 shl 17
const blockWidth = 512

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var sequenceLength = 0
var blockCount = 0
var baseValues = newSeq[int64](0)
var blockOffsets = newSeq[int](0)
var blockLazy = newSeq[int64](0)
var blockTotals = newSeq[int64](0)
var blockBestPrefix = newSeq[int64](0)
var blockPrefixes = newSeq[int64](0)
var blockReady = newSeq[bool](0)
```

The minus branch handles negative values and updates.
Each block stores a lazy increment and cached sums.
All sums use int64 for the stated bounds.

**Block rebuild and update.** A dirty block is rebuilt once, and updates separate whole blocks from edges.

```nim
proc ensureBlock(blockIndex: int) =
  if blockReady[blockIndex]:
    return
  let startIndex = blockOffsets[blockIndex]
  let stopIndex = blockOffsets[blockIndex + 1]
  var runningTotal: int64 = 0
  var bestTotal: int64 = -(1 shl 60)
  for position in startIndex ..< stopIndex:
    runningTotal = runningTotal + baseValues[position] + blockLazy[blockIndex]
    blockPrefixes[position] = runningTotal
    if runningTotal > bestTotal:
      bestTotal = runningTotal
  blockTotals[blockIndex] = runningTotal
  blockBestPrefix[blockIndex] = bestTotal
  blockReady[blockIndex] = true

proc updateRange(leftIndex, rightIndex: int; increment: int64) =
  let firstBlock = leftIndex div blockWidth
  let lastBlock = rightIndex div blockWidth
  for blockIndex in firstBlock .. lastBlock:
    let startIndex = blockOffsets[blockIndex]
    let stopIndex = blockOffsets[blockIndex + 1]
    var segmentLeft = leftIndex
    if segmentLeft < startIndex:
      segmentLeft = startIndex
    var segmentRight = rightIndex
    if segmentRight >= stopIndex:
      segmentRight = stopIndex - 1
    if segmentLeft == startIndex and segmentRight == stopIndex - 1:
      blockLazy[blockIndex] = blockLazy[blockIndex] + increment
      blockTotals[blockIndex] = blockTotals[blockIndex] + increment * int64(stopIndex - startIndex)
      blockReady[blockIndex] = false
    else:
      for position in segmentLeft .. segmentRight:
        baseValues[position] = baseValues[position] + increment
      blockTotals[blockIndex] = blockTotals[blockIndex] + increment * int64(segmentRight - segmentLeft + 1)
      blockReady[blockIndex] = false
```

A ready block avoids repeated scans.
Full blocks change only the lazy tag and total.
Edge blocks change stored values directly.

**Range query and driver.** Prefix sums are assembled from block totals and cached prefixes.

```nim
proc queryRange(leftIndex, rightIndex: int): int64 =
  let firstBlock = leftIndex div blockWidth
  let lastBlock = rightIndex div blockWidth
  var passedTotal: int64 = 0
  for blockIndex in 0 ..< firstBlock:
    passedTotal = passedTotal + blockTotals[blockIndex]

  var bestTotal: int64 = -(1 shl 60)
  for blockIndex in firstBlock .. lastBlock:
    ensureBlock(blockIndex)
    let startIndex = blockOffsets[blockIndex]
    let stopIndex = blockOffsets[blockIndex + 1]
    var segmentLeft = leftIndex
    if segmentLeft < startIndex:
      segmentLeft = startIndex
    var segmentRight = rightIndex
    if segmentRight >= stopIndex:
      segmentRight = stopIndex - 1
    if segmentLeft == startIndex and segmentRight == stopIndex - 1:
      let candidate = passedTotal + blockBestPrefix[blockIndex]
      if candidate > bestTotal:
        bestTotal = candidate
      passedTotal = passedTotal + blockTotals[blockIndex]
    else:
      for position in segmentLeft .. segmentRight:
        let candidate = passedTotal + blockPrefixes[position]
        if candidate > bestTotal:
          bestTotal = candidate
      passedTotal = passedTotal + blockTotals[blockIndex]
  return bestTotal

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

sequenceLength = nextInt(inputData, scanPos)
baseValues = newSeq[int64](sequenceLength)
for position in 0 .. sequenceLength - 1:
  baseValues[position] = int64(nextInt(inputData, scanPos))
blockCount = (sequenceLength + blockWidth - 1) div blockWidth
blockOffsets = newSeq[int](blockCount + 1)
blockLazy = newSeq[int64](blockCount)
blockTotals = newSeq[int64](blockCount)
blockBestPrefix = newSeq[int64](blockCount)
blockPrefixes = newSeq[int64](sequenceLength)
blockReady = newSeq[bool](blockCount)
for blockIndex in 0 .. blockCount - 1:
  blockOffsets[blockIndex] = blockIndex * blockWidth
blockOffsets[blockCount] = sequenceLength
for blockIndex in 0 .. blockCount - 1:
  ensureBlock(blockIndex)

let operationCount = nextInt(inputData, scanPos)
for operationIndex in 0 .. operationCount - 1:
  let operationType = nextInt(inputData, scanPos)
  if operationType == 0:
    let updateLeft = nextInt(inputData, scanPos) - 1
    let updateRight = nextInt(inputData, scanPos) - 1
    let increment = int64(nextInt(inputData, scanPos))
    updateRange(updateLeft, updateRight, increment)
  else:
    let queryLeft = nextInt(inputData, scanPos) - 1
    let queryRight = nextInt(inputData, scanPos) - 1
    appendOutput($queryRange(queryLeft, queryRight))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A whole block contributes one cached maximum.
Boundary blocks contribute one prefix per entry.
Answers accumulate in one output buffer.

## Complexity

Each operation touches at most two edge blocks and all whole blocks between them.

| phase | time | space |
|---|---|---|
| input read | one pass over array and operations | one input string |
| block rebuild | one scan of at most 512 entries | prefix array of N entries |
| update | two edge scans plus one tag per full block | block tag arrays |
| query | one max per full block plus two edge scans | block buffer |

Rebuild work is paid at most once between updates to a block.

| measure | Big O |
|---|---|
| time | O((N / 512 + 512) M) |
| space | O(N) |

A direct per-element scan would cost O(N) per operation.
