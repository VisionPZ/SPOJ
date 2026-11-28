# GNY07H — Tiling a Grid With Dominoes (SPOJ)

<https://www.spoj.com/problems/GNY07H/>

## Problem

Count the ways to cover a 4-by-W rectangle with 2-by-1 dominoes in either orientation. Print one count per grid width.

The first line holds the number of test cases. Each later line holds one width W. Each answer line holds the case number, a space, and the tiling count.

| item | bound |
|---|---|
| test cases | 1 to 1000 |
| width W | chosen so the count fits a 32-bit integer |
| judge limit | 9600 ms, 1536 MB |

The largest usable width is 21, where the count reaches 1752296281.

Sample input:

```
3
2
3
7
```

Sample output:

```
1 5
2 11
3 781
```

## Idea

Treat the right edge of the grid like a stack of four slots that a domino can fill, like packing a bookshelf one shelf at a time. Track three counts: full grids, grids with two corner cells missing, and grids with two cells missing on one side. Recurrence fills the next column from those three states. Each width costs one constant-time step after the table is built. A fresh search over all domino placements repeats far more work. Precompute once and answer every width by lookup.

## Why It Works

1. A full 4-by-n grid ends in two vertical dominoes, four horizontal dominoes, or one of two mixed ends.
2. A mixed end leaves a two-cell corner gap or a two-cell side notch in the previous column.
3. The three counts therefore obey three linked recurrences.
4. The counts for n equal the sum of the smaller states that complete column n.
5. Every tiling ends in exactly one of those shapes, so the sum counts each tiling once.

| term | meaning |
|---|---|
| `fullTileCounts` | tilings of a complete 4-by-n grid |
| `cornerGapCounts` | tilings with the top and bottom cells of the last column empty |
| `edgeNotchCounts` | tilings with two adjacent cells of the last column empty |

The three states partition every possible right edge.

The generator traces width 3 with explicit numbers:

| n | full | corner gap | side notch |
|---|---|---|---|
| 0 | 1 | 0 | 0 |
| 1 | 1 | 1 | 1 |
| 2 | 5 | 1 | 2 |
| 3 | 11 | 6 | 7 |

The full count 11 matches the sample answer for width 3.

## Code

**Input and scanning.** The reader loads all widths before building the table.

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
```

Whitespace between tokens is ignored.
The largest width drives the table size.
Scanning finishes before any counting starts.

**Recurrence table.** Three sequences advance together up to the largest width.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var widths = newSeq[int](caseCount)
var largestWidth = 1
for caseIndex in 0 .. caseCount - 1:
  widths[caseIndex] = nextInt(inputData, scanPos)
  if widths[caseIndex] > largestWidth:
    largestWidth = widths[caseIndex]

var fullTileCounts = newSeq[int64](largestWidth + 1)
var cornerGapCounts = newSeq[int64](largestWidth + 1)
var edgeNotchCounts = newSeq[int64](largestWidth + 1)
```

The base cases cover widths zero and one.
Each later width reads only the two previous widths.
The sequences use int64 to keep intermediates exact.

**Answer emission.** One buffered line reports each case.

```nim
fullTileCounts[0] = 1
fullTileCounts[1] = 1
cornerGapCounts[1] = 1
edgeNotchCounts[1] = 1
var widthIndex = 2
while widthIndex <= largestWidth:
  fullTileCounts[widthIndex] = fullTileCounts[widthIndex - 1] + fullTileCounts[widthIndex - 2] + cornerGapCounts[widthIndex - 1] + 2 * edgeNotchCounts[widthIndex - 1]
  cornerGapCounts[widthIndex] = fullTileCounts[widthIndex - 1] + cornerGapCounts[widthIndex - 2]
  edgeNotchCounts[widthIndex] = fullTileCounts[widthIndex - 1] + edgeNotchCounts[widthIndex - 1]
  widthIndex += 1

for caseIndex in 0 .. caseCount - 1:
  appendOutput($(caseIndex + 1))
  outputBuffer.add ' '
  appendOutput($fullTileCounts[widths[caseIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The mixed end contributes two notch tilings.
Case numbers start at one.
The buffer flushes once after the loop.

## Complexity

The table advances once for each width, and each case is one lookup.

| phase | time | space |
|---|---|---|
| input read | one pass over width tokens | array of widths |
| table build | one step per width | three arrays |
| output | one buffered line per case | block buffer |

Every test case reuses the same table.

| measure | Big O |
|---|---|
| time | O(C + Wmax) |
| space | O(C + Wmax) |

A fresh tiling search per case would cost far more than this single table pass. Precompute once, then answer every width by direct lookup.
