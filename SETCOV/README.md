# SETCOV — Set Cover (SPOJ)

<https://www.spoj.com/problems/SETCOV/>

## Problem

Choose the fewest sets that still cover every element. The instance is path-realizable: each element belongs to a consecutive block of edges on a hidden path with one edge per set.

Input starts with `N M`. Then come `M` groups. Each group gives the size of a set, followed by its elements when the size is positive.

Output `-1` when some element lies in no set. Otherwise output the cover size, then the sorted indices of the chosen sets.

| item | bound |
|---|---|
| universe size N | 1 to 300 |
| set count M | 1 to 300 |
| judge limit | 1500 ms, 1536 MB |

The hidden path turns set cover into interval stabbing.

Sample input:

```
3 4
0
2
2 1
2
1 0
0
```

Sample output:

```
2
1 2
```

## Idea

A hidden path is like a row of streetlights, and each element needs one lit edge between its two endpoints. Recover the order of the edges, then stab the intervals from left to right.

The algorithm uses bitsets to recover interval order, then a greedy sweep over the recovered intervals. Each column comparison costs five machine words. A general set cover search would be exponential, while interval stabbing is linear after ordering.

Sets with no members are reported as impossible before ordering begins.

## Why It Works

1. Each set maps to one edge on the hidden path.
2. Each element maps to the consecutive edges between its two path vertices.
3. Removing columns contained in other columns leaves one representative per interval start.
4. Columns that share a set form one connected component of overlapping intervals.
5. Within a component, the insertion rule recovers left-to-right endpoint order.
6. A group of intervals with common intersection needs exactly one chosen set.
7. Picking a set inside that intersection covers the whole group.

| term | meaning |
|---|---|
| `ColumnBits` | five 64-bit words holding the sets containing one element |
| `minimalColumns` | columns kept after removing contained duplicates |
| `orderedColumns` | one component's columns in left-to-right order |
| `endpoints` | artificial start and end coordinates for the recovered intervals |
| `chosenSets` | set indices selected for the cover |

A worked example from the sample:

```
element 0 belongs to set 2 only -> singleton edge 2
element 1 belongs to sets 1 and 2 -> edge interval 1..2
element 2 belongs to set 1 only -> singleton edge 1
singletons force sets 1 and 2
cover size 2, indices 1 2
```

The forced singletons determine both sets, so no other cover of size 2 exists.

## Code

**Input, bitsets, and buffered output.** Five words hold up to 300 set membership bits.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const wordCount = 5
const bitsPerWord = 64
const coveringSets = 300

type ColumnBits = object
  words: array[wordCount, uint64]

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

The scanner handles group sizes and element lists without token strings.
The word count is fixed because M never exceeds 300.
Output accumulates in one buffer until the block threshold.

**Bit operations.** Subset, intersection, and emptiness tests drive the ordering.

```nim
proc makeEmptyBits(): ColumnBits =
  for wordIndex in 0 .. wordCount - 1:
    result.words[wordIndex] = 0'u64

proc setBit(bits: var ColumnBits, bitIndex: int) =
  let wordIndex = bitIndex div bitsPerWord
  let bitOffset = bitIndex mod bitsPerWord
  bits.words[wordIndex] = bits.words[wordIndex] or (1'u64 shl bitOffset)

proc isEmptyBits(bits: ColumnBits): bool =
  for wordIndex in 0 .. wordCount - 1:
    if bits.words[wordIndex] != 0'u64:
      return false
  return true

proc isSubsetBits(left: ColumnBits, right: ColumnBits): bool =
  for wordIndex in 0 .. wordCount - 1:
    if (left.words[wordIndex] and not right.words[wordIndex]) != 0'u64:
      return false
  return true

proc intersectsBits(left: ColumnBits, right: ColumnBits): bool =
  for wordIndex in 0 .. wordCount - 1:
    if (left.words[wordIndex] and right.words[wordIndex]) != 0'u64:
      return true
  return false

proc equalBits(left: ColumnBits, right: ColumnBits): bool =
  for wordIndex in 0 .. wordCount - 1:
    if left.words[wordIndex] != right.words[wordIndex]:
      return false
  return true

proc commonBits(left: ColumnBits, right: ColumnBits): ColumnBits =
  for wordIndex in 0 .. wordCount - 1:
    result.words[wordIndex] = left.words[wordIndex] and right.words[wordIndex]

proc lowestSetBit(bits: ColumnBits): int =
  for bitIndex in 0 .. coveringSets - 1:
    let wordIndex = bitIndex div bitsPerWord
    let bitOffset = bitIndex mod bitsPerWord
    if (bits.words[wordIndex] and (1'u64 shl bitOffset)) != 0'u64:
      return bitIndex
  return -1
```

Each predicate scans the same five words.
Intersection tests decide which columns belong to one component.
The lowest set bit becomes the chosen set index.

**Input parse and pruning.** Supersets are removed so interval starts stay ordered.

```nim
let universeSize = nextInt(inputData, scanPos)
let collectionSize = nextInt(inputData, scanPos)
var columns = newSeq[ColumnBits](universeSize)
for columnIndex in 0 .. universeSize - 1:
  columns[columnIndex] = makeEmptyBits()

for setIndex in 0 .. collectionSize - 1:
  let memberCount = nextInt(inputData, scanPos)
  for memberIndex in 0 .. memberCount - 1:
    let elementIndex = nextInt(inputData, scanPos)
    setBit(columns[elementIndex], setIndex)

var hasUncovered = false
for columnIndex in 0 .. universeSize - 1:
  if isEmptyBits(columns[columnIndex]):
    hasUncovered = true

if hasUncovered:
  appendOutput("-1\n")
else:
  var minimalColumns = newSeq[ColumnBits]()
  for columnIndex in 0 .. universeSize - 1:
    var discardColumn = false
    for otherIndex in 0 .. universeSize - 1:
      if isSubsetBits(columns[otherIndex], columns[columnIndex]):
        if not equalBits(columns[columnIndex], columns[otherIndex]) or columnIndex < otherIndex:
          discardColumn = true
          break
    if not discardColumn:
      minimalColumns.add columns[columnIndex]
```

An empty column means one element has no covering set.
A strict superset is discarded because a smaller interval ends sooner.
Identical columns keep only the largest index.

**Component ordering.** Overlapping columns are inserted into left-to-right order.

```nim
  let columnCount = minimalColumns.len
  var visited = newSeq[bool](columnCount)
  var chosenSets = newSeq[int]()
  for startColumn in 0 .. columnCount - 1:
    if visited[startColumn]:
      continue
    var orderedColumns = newSeq[int]()
    var pending = newSeq[int]()
    pending.add startColumn
    while pending.len > 0:
      let currentColumn = pending.pop()
      if visited[currentColumn]:
        continue
      visited[currentColumn] = true
      if orderedColumns.len <= 1:
        orderedColumns.add currentColumn
      else:
        var overlapIndex = 0
        while not intersectsBits(minimalColumns[currentColumn],
                                 minimalColumns[orderedColumns[overlapIndex]]):
          overlapIndex += 1
        if overlapIndex + 1 < orderedColumns.len and
           isSubsetBits(commonBits(minimalColumns[currentColumn],
                                   minimalColumns[orderedColumns[overlapIndex + 1]]),
                        commonBits(minimalColumns[currentColumn],
                                   minimalColumns[orderedColumns[overlapIndex]])):
          orderedColumns.insert(currentColumn, overlapIndex)
        else:
          while true:
            if overlapIndex == orderedColumns.len - 1 or
               not isSubsetBits(commonBits(minimalColumns[currentColumn],
                                           minimalColumns[orderedColumns[overlapIndex]]),
                                commonBits(minimalColumns[currentColumn],
                                           minimalColumns[orderedColumns[overlapIndex + 1]])):
              orderedColumns.insert(currentColumn, overlapIndex + 1)
              break
            overlapIndex += 1
      for otherColumn in 0 .. columnCount - 1:
        if otherColumn != startColumn and
           intersectsBits(minimalColumns[currentColumn], minimalColumns[otherColumn]):
          pending.add otherColumn
```

Each connected component is visited once.
Insertion compares overlap strength with neighbours already placed.
The explicit stack keeps the walk iterative.

**Endpoint sweep.** Artificial coordinates separate interval ends, then groups are covered.

```nim
    let intervalCount = orderedColumns.len
    var endpoints = newSeq[tuple[first: int, second: int]](intervalCount)
    var cursors = newSeq[int](intervalCount)
    for intervalIndex in 0 .. intervalCount - 1:
      endpoints[intervalIndex].first = intervalIndex * intervalCount
      cursors[intervalIndex] = intervalIndex * intervalCount + 1
    for intervalIndex in 0 .. intervalCount - 1:
      var scanIndex = intervalIndex + 1
      while scanIndex < intervalCount and
            intersectsBits(minimalColumns[orderedColumns[intervalIndex]],
                           minimalColumns[orderedColumns[scanIndex]]):
        scanIndex += 1
      endpoints[intervalIndex].second = cursors[scanIndex - 1]
      cursors[scanIndex - 1] += 1

    var groupStart = 0
    while groupStart < intervalCount:
      var shared = minimalColumns[orderedColumns[groupStart]]
      var groupEnd = groupStart + 1
      while groupEnd < intervalCount and
            endpoints[groupEnd].first < endpoints[groupStart].second:
        shared = commonBits(shared, minimalColumns[orderedColumns[groupEnd]])
        groupEnd += 1
      groupStart = groupEnd
      chosenSets.add(lowestSetBit(shared))
```

Start coordinates are spaced far enough apart to sort ends.
A group ends when the next interval starts after the current end.
One set from the shared intersection covers the entire group.

**Answer output.** Chosen indices are sorted and written through the buffer.

```nim
  chosenSets.sort(proc(left, right: int): int =
    if left < right: -1
    elif left > right: 1
    else: 0)

  appendOutput($(chosenSets.len))
  appendOutput("\n")
  for chosenIndex in 0 .. chosenSets.len - 1:
    if chosenIndex > 0:
      appendOutput(" ")
    appendOutput($(chosenSets[chosenIndex]))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Sorting makes the answer independent of component order.
The size line and index line are both buffered.
The final write flushes every remaining byte.

## Complexity

Each column comparison costs five word operations.

| phase | time | space |
|---|---|---|
| input read | one pass over membership lists | one input string |
| pruning | all pairs of columns | bitset array |
| ordering | one visit per overlap edge | component state |
| sweep | one pass per component | endpoint array |
| output | two lines | block buffer |

Both word count and component count stay bounded by the 300-item limits.

| measure | Big O |
|---|---|
| time | O(N^2 * M / 64 + ordering) |
| space | O(N * M / 64) |

Searching all set subcollections would be exponential, while bitset ordering reduces the instance to interval stabbing.
