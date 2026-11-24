## Problem

Read the number of test cases, then read each case as a list of posters. Each poster covers every section from its left number to its right number. Posters hang in the given order and later posters cover earlier ones. Print, for each case, how many posters still show at least one section.

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded in the statement |
| Posters per case | 1 to 40,000 |
| Section numbers | 1 to 10,000,000 |
| Time limit | 7,000 ms |
| Memory limit | 1,536 MB |

The poster count sets the work per case; section numbers are far too large for a direct array.

## Idea

Work backwards from the last poster. A poster stays visible when it covers a section that no later poster covers.

We map the wall to a small sorted list of section numbers. A union-find array jumps to the next uncovered position and marks each covered position in roughly constant time. Scanning every section directly would cost up to 10,000,000 steps per poster.

Cost per poster: two binary searches and roughly constant work per marked position.

## Why It Works

When we reach poster i, every later poster is already marked. An uncovered section inside [li, ri] can only belong to poster i. One check decides visibility, and marking the range stops earlier posters from reusing those sections.

Each endpoint x contributes x - 1, x, and x + 1 to the compressed list. When two endpoints a and b are not adjacent, a + 1 lies strictly between them and represents the whole gap. Without those points, the poster [20, 30] would seem covered by [10, 20] and [30, 40].

i = lowerBound(li) points at the first compressed section at or after li.
j = lowerBound(ri) points at the first compressed section at or after ri.
findNext(p) returns the smallest unmarked index at or after p.
nextFree[p] = findNext(p + 1) removes p from the free set.
A poster is visible exactly when findNext(i) <= j.

Each compressed position is removed once, so all marking in one case takes nearly linear time.

The generator walks the sample in reverse and records each visible poster.

```
posters checked in reverse: 5 4 3 2 1
visible poster numbers: 1 2 4 5
answer: 4
```

Poster 3 loses every section to poster 5, so four posters remain.

## Code

The program reads the whole input once and parses integers by hand.

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

The read loop ends at end of input, so blank lines cause no trouble. The scanner skips non-digits and builds values one digit at a time. One pass over the input bytes covers all parsing.

Output accumulates in one string and flushes after 256 KiB.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush threshold is a compile-time constant. One stream write per block replaces one write per answer. The cost is one write for each 256 KiB of output.

Two helpers drive the reverse sweep.

```nim
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

proc lowerBound(value: int): int =
  var i = 0
  var j = compressedValues.len
  while i < j:
    var k = (i + j) div 2
    if compressedValues[k] < value:
      i = k + 1
    else:
```

findNext compresses its path, so repeated lookups stay short. lowerBound runs in logarithmic time over the sorted compressed list. The sentinel at index uniqueCount ends every free run.

The main loop handles one test case at a time.

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

The poster loop runs from posterCount - 1 down to 0. Adding neighbours of each endpoint keeps a representative inside every gap. Each covered position is linked once, so the while loop never revisits it.

## Complexity

Here n is the poster count in one case and t is the test case count.

| Phase | Time | Space |
| --- | --- | --- |
| Read input | O(input bytes) | O(input bytes) |
| Build and sort compressed list | O(n log n) | O(n) |
| Reverse sweep | O(n) near linear | O(n) |
| Write output | O(t) | O(block size) |

Total time is O(n log n) per case and total space is O(n) per case.

Scanning each poster's full section range would take O(n * 10,000,000) time per case.
