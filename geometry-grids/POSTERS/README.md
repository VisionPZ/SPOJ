# POSTERS — Election Posters (SPOJ)

<https://www.spoj.com/problems/POSTERS/>

## Problem

Posters cover ranges of wall sections and are hung one after another. Count how many posters still show at least one section after later ones cover them.

Input: `t` test cases. Each case starts with `n`, followed by `n` lines `li ri`, the sections one poster covers in hanging order. Output: one integer per case, the number of posters with a visible section.

The bounds from the statement:

| Item | Bound |
|---|---|
| Posters per case `n` | 1 ≤ n ≤ 40000 |
| Section numbers | 1 ≤ li < ri ≤ 10^7 |
| Order | input order is hanging order |
| Judge limit | 7000 ms, 1536 MB |

A case can span ten million wall sections, so painting them one by one is too slow.

The sample input and output:

```
1
5
1 4
2 6
8 10
3 4
7 10
```

```
4
```

## Idea

Read the posters backwards, like peeling notices off a wall from the top sheet down. The last poster still shows everywhere it hangs. An earlier poster shows only where no later poster already claimed a section.

The program compresses endpoints first. For each `li, ri` it adds six values: `li − 1, li, li + 1, ri − 1, ri, ri + 1`. They form a sorted unique list. Each compressed value stands for one wall section.

A disjoint-set (a table that jumps each covered point to the next free one) skips sections already taken. For each poster in reverse order, jump to the first free point in its range. A free point means the poster is visible, and the program then marks the whole range covered.

Sorting `6n` values costs O(n log n). The reverse pass removes each point once, so it costs O(n α(n)). Painting every wall section up to 10^7 times per case would miss the limit.

Backward order plus a skip table turns heavy painting into one light pass.

## Why It Works

Four facts carry the method.

1. A poster stays visible exactly when one section in its range has no later poster over it.
2. Processing from last to first guarantees that every covered section belongs to a later poster. The first free point therefore settles visibility at once.
3. Adding the two neighbors of each endpoint keeps every section boundary in the compressed list. `lowerBound(li)` and `lowerBound(ri)` then give the representative index range.
4. `findNext` compresses paths to the next free point, so each section is removed once. Across all posters the removal work stays linear.

The arrays that drive the sweep:

| Term | Meaning |
|---|---|
| `compressedValues` | sorted unique representatives of wall sections |
| `lowerBound` | first index whose value is at least the query |
| `nextFree` | disjoint-set table of each next uncovered point |
| `visibleCount` | posters that kept at least one free section |

Compressing endpoints preserves order, so the skip table behaves exactly like the real wall.

A script-traced example with the five sample posters:

```
poster 5  [7,10]  sections 7,8,9,10 free  -> visible; mark 7-10
poster 4  [3,4]   sections 3,4 free       -> visible; mark 3-4
poster 3  [8,10]  8,9,10 already marked   -> hidden
poster 2  [2,6]   2,5,6 free              -> visible; mark 2,5,6
poster 1  [1,4]   1 free                  -> visible; mark 1
visible posters = 4
```

The six-neighbor compression maps these endpoints onto indices 0 through 11. Poster 1 spans `lowerBound(1) = 1` through `lowerBound(4) = 4`.

## Code

**Setup and scanner.** The whole stream goes into one buffer before any case runs.

```nim
import std/algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

`compressedValues` and `nextFree` are module-level, so each case reuses the same storage. `nextInt` walks the buffer by index and returns one integer at a time.

**Output helper.** Text collects in one buffer and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush threshold is 256 KiB. `setLen 0` reuses one allocation instead of growing a new string.

**Skip table and comparator.** `findNext` returns the next uncovered representative.

```nim
proc compareInts(first, second: int): int =
  return system.cmp(first, second)

var compressedValues: seq[int]
var nextFree: seq[int]

proc findNext(i: int): int =
  var root = i
  while nextFree[root] != root:
    root = nextFree[root]
  var j = i
  while nextFree[j] != j:
    var parent = nextFree[j]
    nextFree[j] = root
    j = parent
  return root
```

The first loop finds the root, and the second loop rewrites each visited pointer to that root. Path compression makes later jumps nearly free. `compareInts` passes the ordering to `sort`.

**Lower bound.** A binary search maps a wall section to its compressed index.

```nim
proc lowerBound(value: int): int =
  var i = 0
  var j = compressedValues.len
  while i < j:
    var k = (i + j) div 2
    if compressedValues[k] < value:
      i = k + 1
    else:
      j = k
  return i
```

The loop halves the index window until it finds the first value at least `value`. It runs O(log n) times per call and allocates nothing.

**Reverse sweep.** Each poster is checked from the newest to the oldest.

```nim
let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let posterCount = nextInt(inputData, i)
  var leftBounds = newSeq[int](posterCount)
  var rightBounds = newSeq[int](posterCount)
  compressedValues = newSeq[int](posterCount * 6)
  var l = 0
  for k in 0..<posterCount:
    let leftBound = nextInt(inputData, i)
    let rightBound = nextInt(inputData, i)
    leftBounds[k] = leftBound
    rightBounds[k] = rightBound
    compressedValues[l] = leftBound - 1
    l += 1
    compressedValues[l] = leftBound
    l += 1
    compressedValues[l] = leftBound + 1
    l += 1
    compressedValues[l] = rightBound - 1
    l += 1
    compressedValues[l] = rightBound
    l += 1
    compressedValues[l] = rightBound + 1
    l += 1
  sort(compressedValues, compareInts)
  var uniqueCount = 0
  for k in 0..<compressedValues.len:
    if k == 0 or compressedValues[k] != compressedValues[uniqueCount - 1]:
      compressedValues[uniqueCount] = compressedValues[k]
      uniqueCount += 1
  compressedValues.setLen(uniqueCount)
  nextFree = newSeq[int](uniqueCount + 1)
  for k in 0..uniqueCount:
    nextFree[k] = k
  var visibleCount = 0
  for k in countdown(posterCount - 1, 0):
    let i = lowerBound(leftBounds[k])
    let j = lowerBound(rightBounds[k])
    var l = findNext(i)
    if l <= j:
      visibleCount += 1
      while l <= j:
        nextFree[l] = findNext(l + 1)
        l = findNext(l)
  appendOutput($(visibleCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The six pushes per poster create the compression list before sorting. The outer poster loop counts down from `posterCount − 1` to 0. The inner walk marks each free point once through `findNext(l + 1)`.

## Complexity

Each case compresses endpoints, then sweeps posters backwards.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Compression | sort `6n` values | O(n) |
| Reverse sweep | each point removed once | O(n) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n log n) dominated by the sort | O(n) |

The sweep is linear, and the sort sets the overall cost.

| Measure | Big O |
|---|---|
| Time | O(n log n) per case for `n` posters |
| Space | O(n) for bounds, compressed values, and the skip table |

No data structure grows with the ten-million-section range.

Painting each section of every poster would cost up to 10^7 steps per poster. Compression and skipping replace that with one pass over at most `6n` points.
