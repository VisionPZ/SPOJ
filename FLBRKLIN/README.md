# FLBRKLIN — Flat broken lines (SPOJ)
<https://www.spoj.com/problems/FLBRKLIN/>

## Problem

A draftsman draws flat broken lines across a sheet of graph paper to cover marked points. Each stroke runs left to right and never tilts more than 45 degrees from horizontal. Find the fewest strokes that cover every point.

The first line holds the test count t. Each case starts with a point count n, then n lines with coordinates x and y. Points are distinct and both coordinates run from 0 to 30000. Print one integer per case, the minimum number of lines.

The judge limits are:

| Item | Value |
| --- | --- |
| Points per case | at most 30000 |
| Coordinates | 0 to 30000 |
| Time limit | 5 s |
| Memory limit | 1536 MB |

The point count rules out any pairwise method.

The sample input reads:

```text
1
6
1 6
10 8
1 5
2 20
4 4
6 2
```

The sample output reads:

```text
3
```

## Idea

Rewrite each point using two diagonal coordinates, like labeling a parcel with two routing numbers. Set u = y - x and v = y + x. One flat line covers points whose u does not rise while v does not fall. By Dilworth's theorem (a rule linking chain covers to antichains), the fewest lines equal the largest group with both u and v rising. Patience sorting (a card-game method for longest rising runs) counts that group in one pass. Each point costs one sort comparison and one binary search. A matching built from point pairs would cost cubic time. Takeaway: sort by one coordinate, then count rising values of the other.

## Why It Works

1. For two points with x1 < x2, one line covers both exactly when |y2 - y1| is at most x2 - x1.
2. That inequality splits into u2 <= u1 and v2 >= v1.
3. Those two rules define a partial order, and one flat line covers a chain in that order.
4. Dilworth's theorem equates the minimum chain cover with the largest antichain.
5. Two points are incomparable exactly when u rises and v rises, so the answer is a longest rising subsequence of v.
6. The packed key sorts by u ascending and, for equal u, by v descending, which keeps equal-u points out of one rising run.

The table defines each term used above.

| Term | Meaning |
| --- | --- |
| u | y - x, the up-diagonal coordinate |
| v | y + x, the down-diagonal coordinate |
| lisTails | smallest tail value for each rising-run length |
| keyShift | 16 bits reserved for the low part of a key |

These four terms cover the sort and the scan.

A script transformed the sample points and replayed the scan.

| Point | u | v | `lisTails` after |
| --- | --- | --- | --- |
| (6, 2) | -4 | 8 | 8 |
| (10, 8) | -2 | 18 | 8, 18 |
| (4, 4) | 0 | 8 | 8, 18 |
| (1, 5) | 4 | 6 | 6, 18 |
| (1, 6) | 5 | 7 | 6, 7 |
| (2, 20) | 18 | 22 | 6, 7, 22 |

The tails end at length 3, so three flat lines cover the sample.

## Code

**Scanner and buffers.** The code slurps input once and parses coordinates with a digit scanner.

```nim
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const coordBound = 30000
const keyShift = 16
const keyMask = (1 shl keyShift) - 1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The read loop runs once per input line. The digit loop visits each character once, so parsing costs O(input bytes). Coordinates are non-negative, so no sign branch is needed. `keyMask` isolates the low 16 bits of a packed key.

**Shared sequences and writer.** The two sequences are reused across cases.

```nim
var sortKeys: seq[int] = @[]
var lisTails: seq[int] = @[]

proc compareKey(left, right: int): int =
  if left < right: return -1
  if left > right: return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen` in the driver reuses capacity, so no per-case allocation is needed. `compareKey` gives the sort a plain ascending order. `flushBlockBytes` caps memory at 256 KiB and avoids one write per answer. The helper cost is constant per case.

**Key building and sort.** The program packs both diagonal coordinates into one sortable integer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pointCount = nextInt(inputData, scanPos)
  sortKeys.setLen(pointCount)
  for i in 0..<pointCount:
    let x = nextInt(inputData, scanPos)
    let y = nextInt(inputData, scanPos)
    let upValue = y - x
    let downValue = y + x
    sortKeys[i] = (upValue + coordBound) * (1 shl keyShift) + (keyMask - downValue)

  sort(sortKeys, compareKey)
```

The loop bound equals the point count of the current case. Storing `keyMask - downValue` makes v fall inside each equal-u group. Key building is linear, and the sort costs O(n log n).

**Rising-run scan.** A binary search maintains the smallest tail for each run length.

```nim
  lisTails.setLen(0)
  for i in 0..<pointCount:
    let downValue = keyMask - (sortKeys[i] and keyMask)
    var lo = 0
    var hi = lisTails.len
    while lo < hi:
      let mid = (lo + hi) div 2
      if lisTails[mid] < downValue:
        lo = mid + 1
      else:
        hi = mid
    if lo == lisTails.len:
      lisTails.add downValue
    else:
      lisTails[lo] = downValue

  appendOutput($(lisTails.len))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The strict test at `lo` keeps equal v values out of one rising run. Each point costs one binary search, so the scan costs O(n log n). The final write flushes any bytes left below the block size.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Parse one case | O(n) | O(n) keys |
| Sort keys | O(n log n) | O(1) extra |
| Rising-run scan | O(n log n) | O(n) tails |

Both main phases grow logarithmically.

Sorting and scanning share the same logarithmic factor.

| Measure | Bound |
| --- | --- |
| Per case | O(n log n) time |
| Per case | O(n) space |
| Total | O(input bytes + sum of n log n) |

A pairwise matching method would build a graph with one edge per point pair and cost cubic time per case.
