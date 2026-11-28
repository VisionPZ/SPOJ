# DECORATE — Decorate the wall (SPOJ)

<https://www.spoj.com/problems/DECORATE/>

## Problem

Find the lowest, then leftmost, free spot for a new rectangle on a wall that already holds non-overlapping paintings. Report the lower-left corner, or `Fail!` when no spot fits.

The first line gives the number of test cases. Each case gives `n`, `w`, `h`, then `n` lines `x1 y1 x2 y2`, then one line `w' h'`. The pair `x1 y1` is the lower-left corner and `x2 y2` is the upper-right corner of an old painting. Print `x y` for the new corner, or `Fail!`.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases | not bounded by the statement |
| Old paintings `n` | 0 to 200 |
| Wall width `w`, height `h` | 1 to 1 000 000 |
| New painting `w'`, `h'` | 1 to `w`, 1 to `h` |
| Judge limit | 1 s, 1536 MB |

Only 200 old paintings matter, so a short candidate list replaces a scan of a million coordinates.

The sample case:

```
2
1 10 9
5 4 10 9
9 5
2 10 10
5 5 10 10
0 0 4 3
3 4
```

```
Fail!
4 0
```

The first case fails; the second places the painting at `4 0`.

## Idea

Slide the new painting down and left until an edge stops it, then test only the stopping places. This resembles a book pushed along a crowded shelf: it halts at a neighbor's edge, never in mid-air.

The algorithm is candidate coordinates plus a sweep over forbidden intervals. Fix a y value and each old painting bans an x span. Sorting those spans by left end answers every candidate x with one moving pointer.

Each candidate y costs one pass over at most 200 paintings and one pass over at most 201 candidate x values. Testing every grid point would cost about 10^12 spots times 200 paintings per case.

A few hundred candidate spots replace a million-by-million grid.

## Why It Works

Four facts prove that the best spot lies in the candidate set.

1. Lower the new painting from a best spot by a tiny amount. That move must create an overlap, and the blocking painting's top edge is the chosen y. So y is 0 or some `topEdge`.
2. Move left from a best spot by a tiny amount. The same argument makes x equal 0 or some `rightEdge`.
3. At a fixed y, only paintings whose vertical span meets the new rectangle can block x. Each bans the span between `activeLeft` and `activeRight`.
4. Sweep candidate x left to right. A running maximum of right ends tells whether a spot is free, since touching an edge is allowed.

The main terms:

| Term | Meaning |
|---|---|
| `maxPlaceY` | largest legal y, equal to `wallHeight - newHeight` |
| `topEdge` | upper y of an old painting, a candidate when at most `maxPlaceY` |
| `activeLeft` | left end of a forbidden x span, taken from `leftEdge` and `newWidth` |
| `activeRight` | right end of a forbidden x span, equal to `rightEdge` |
| `maxBlockedRight` | farthest `activeRight` among spans already passed |

The table converts overlap into two sorted lists and one running maximum.

A script-traced example from the second sample case:

```
wall 10x10, new 3x4
maxPlaceX 7, maxPlaceY 6
y candidates [0, 3]
x candidates [0, 4]
y=0
  forbidden x intervals [(-3, 4)]
  x=0 maxBlockedRight 4 -> blocked
  x=4 maxBlockedRight 4 -> free
answer 4 0
```

At y = 0 the old painting bans x = 0, so the sweep picks x = 4 and matches the sample.

## Code

**Constants.** The digit base, the flush size, and the painting ceiling.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxPaintings = 200
```

The ceiling matches the statement bound of 200. The flush size is 128 KiB. Both values stay fixed across all cases.

**Integer reader.** Digits are scanned by index, so no token object is built.

```nim
proc nextInt(inputData: string, scanPosition: var int): int =
  while scanPosition < inputData.len and (inputData[scanPosition] < '0' or inputData[scanPosition] > '9'):
    scanPosition += 1
  var value = 0
  while scanPosition < inputData.len and inputData[scanPosition] >= '0' and inputData[scanPosition] <= '9':
    value = value * 10 + int(inputData[scanPosition]) - firstDigitValue
    scanPosition += 1
  return value
```

The scan position is a `var` parameter, so it survives across calls. Non-digits are skipped, which handles blank lines. Every value in this problem is non-negative, so no sign branch is needed.

**Candidate list helpers.** Small insertion sorts keep the candidate lists in order.

```nim
proc sortAscending(values: var seq[int]) =
  for i in 1 .. values.len - 1:
    let key = values[i]
    var j = i - 1
    while j >= 0 and values[j] > key:
      values[j + 1] = values[j]
      j -= 1
    values[j + 1] = key

proc removeDuplicates(values: var seq[int]) =
  if values.len == 0: return
  var writePos = 1
  for i in 1 .. values.len - 1:
    if values[i] != values[writePos - 1]:
      values[writePos] = values[i]
      writePos += 1
  values.setLen writePos
```

The loop runs over at most 201 values. `setLen` drops repeated coordinates without a second list. The empty-list guard keeps a case with no paintings safe.

**Bulk input and output.** One buffer holds the input, one buffer holds the answers.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Line reads append into one string, so odd spacing cannot desync the reader. `appendOutput` never writes per case; it flushes only at the block size.

**Painting arrays.** Flat arrays hold the four edges and the two working orders.

```nim
var leftEdge: array[maxPaintings, int]
var bottomEdge: array[maxPaintings, int]
var rightEdge: array[maxPaintings, int]
var topEdge: array[maxPaintings, int]
var leftOrder: array[maxPaintings, int]
var activeLeft: array[maxPaintings, int]
var activeRight: array[maxPaintings, int]
```

The arrays are allocated once, before the case loop. Each case overwrites the first `paintingCount` slots. No hash set or per-case object is needed.

**Candidate build.** The legal corners come from painting edges.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let paintingCount = nextInt(inputData, scanPos)
  let wallWidth = nextInt(inputData, scanPos)
  let wallHeight = nextInt(inputData, scanPos)
  for paintingIndex in 0 .. paintingCount - 1:
    leftEdge[paintingIndex] = nextInt(inputData, scanPos)
    bottomEdge[paintingIndex] = nextInt(inputData, scanPos)
    rightEdge[paintingIndex] = nextInt(inputData, scanPos)
    topEdge[paintingIndex] = nextInt(inputData, scanPos)
  let newWidth = nextInt(inputData, scanPos)
  let newHeight = nextInt(inputData, scanPos)
  let maxPlaceX = wallWidth - newWidth
  let maxPlaceY = wallHeight - newHeight

  var xCandidates: seq[int]
  var yCandidates: seq[int]
  xCandidates.add 0
  yCandidates.add 0
  for paintingIndex in 0 .. paintingCount - 1:
    if rightEdge[paintingIndex] <= maxPlaceX: xCandidates.add rightEdge[paintingIndex]
    if topEdge[paintingIndex] <= maxPlaceY: yCandidates.add topEdge[paintingIndex]
  sortAscending(xCandidates)
  sortAscending(yCandidates)
  removeDuplicates(xCandidates)
  removeDuplicates(yCandidates)
```

Edges beyond the legal maximum are dropped, since they cannot be corners. Sorting by coordinate gives the tie-break order for free. Each list holds at most one more than `paintingCount` values.

**Left order.** Paintings are sorted once by left edge for the whole case.

```nim
  for paintingIndex in 0 .. paintingCount - 1:
    leftOrder[paintingIndex] = paintingIndex
  for i in 1 .. paintingCount - 1:
    let key = leftOrder[i]
    var j = i - 1
    while j >= 0 and leftEdge[leftOrder[j]] > leftEdge[key]:
      leftOrder[j + 1] = leftOrder[j]
      j -= 1
    leftOrder[j + 1] = key
```

The order is built once per case, not once per candidate y. Since `newWidth` is fixed, subtracting it preserves the order. The sort costs at most 200 insertion steps.

**Placement sweep.** Each candidate y is tested with one left-to-right pointer.

```nim
  var placed = false
  for candidateY in yCandidates:
    var activeCount = 0
    for k in 0 .. paintingCount - 1:
      let paintingIndex = leftOrder[k]
      if candidateY < topEdge[paintingIndex] and candidateY + newHeight > bottomEdge[paintingIndex]:
        activeLeft[activeCount] = leftEdge[paintingIndex] - newWidth
        activeRight[activeCount] = rightEdge[paintingIndex]
        activeCount += 1
    var maxBlockedRight = -1
    var activePos = 0
    for candidateX in xCandidates:
      while activePos < activeCount and activeLeft[activePos] < candidateX:
        if activeRight[activePos] > maxBlockedRight: maxBlockedRight = activeRight[activePos]
        activePos += 1
      if candidateX >= maxBlockedRight:
        appendOutput($candidateX & " " & $candidateY & "\n")
        placed = true
        break
    if placed: break
  if not placed:
    appendOutput("Fail!\n")
```

The active test uses strict inequalities, so touching an edge stays legal. `maxBlockedRight` starts at -1, which frees x = 0. Equality with a right edge counts as free for the same reason.

**Final flush.** The tail of the output buffer is written after the last case.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

This write covers any bytes below the block size. It is harmless when the buffer is empty.

## Complexity

The cost follows the painting count, not the wall size.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all input bytes | input bytes |
| Candidate lists | two sorts of at most 201 values | two lists of 201 |
| Per case | at most 201 y values, each with 200 paintings and 201 x values | seven arrays of 200 |
| Output | one write per 128 KiB block | one 128 KiB block |

The per-case work depends on the old paintings, never on `w` or `h`.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(t n^2) for t cases with n at most 200, plus bytes read and written |
| Space | O(n) for arrays and candidate lists |

A grid scan costs O(w h n) per case and can exceed 10^14 checks. This method stays O(n^2) whatever the wall size.
