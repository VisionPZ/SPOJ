## Problem

Read the number of test cases, then read each case as a list of posters. Each poster covers every section from its left number to its right number. Posters hang in the given order and later posters cover earlier ones. Print, for each case, how many posters still show at least one section.

| Quantity | Bound |
| --- | --- |
| Test cases | no stated bound |
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

leftIndex = lowerBound(li) points at the first compressed section at or after li.
rightIndex = lowerBound(ri) points at the first compressed section at or after ri.
findNext(p) returns the smallest unmarked index at or after p.
nextFree[p] = findNext(p + 1) removes p from the free set.
A poster is visible exactly when findNext(leftIndex) <= rightIndex.

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

proc findNext(position: int): int =
  var root = position
  while nextFree[root] != root:
    root = nextFree[root]
  var cursor = position
  while nextFree[cursor] != cursor:
    var parent = nextFree[cursor]
    nextFree[cursor] = root
    cursor = parent
  return root

proc lowerBound(value: int): int =
  var low = 0
  var high = compressedValues.len
  while low < high:
    var middle = (low + high) div 2
    if compressedValues[middle] < value:
      low = middle + 1
    else:
```

findNext compresses its path, so repeated lookups stay short. lowerBound runs in logarithmic time over the sorted compressed list. The sentinel at index uniqueCount ends every free run.

The main loop handles one test case at a time.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let posterCount = nextInt(inputData, scanPos)
  var leftBounds = newSeq[int](posterCount)
  var rightBounds = newSeq[int](posterCount)
  compressedValues = newSeq[int](posterCount * 6)
  var compressedPos = 0
  for posterIndex in 0..<posterCount:
    let leftBound = nextInt(inputData, scanPos)
    let rightBound = nextInt(inputData, scanPos)
    leftBounds[posterIndex] = leftBound
    rightBounds[posterIndex] = rightBound
    compressedValues[compressedPos] = leftBound - 1
    compressedPos += 1
    compressedValues[compressedPos] = leftBound
    compressedPos += 1
    compressedValues[compressedPos] = leftBound + 1
    compressedPos += 1
    compressedValues[compressedPos] = rightBound - 1
    compressedPos += 1
    compressedValues[compressedPos] = rightBound
    compressedPos += 1
    compressedValues[compressedPos] = rightBound + 1
    compressedPos += 1
  sort(compressedValues, compareInts)
  var uniqueCount = 0
  for valueIndex in 0..<compressedValues.len:
    if valueIndex == 0 or compressedValues[valueIndex] != compressedValues[uniqueCount - 1]:
      compressedValues[uniqueCount] = compressedValues[valueIndex]
      uniqueCount += 1
  compressedValues.setLen(uniqueCount)
  nextFree = newSeq[int](uniqueCount + 1)
  for freeIndex in 0..uniqueCount:
    nextFree[freeIndex] = freeIndex
  var visibleCount = 0
  for posterIndex in countdown(posterCount - 1, 0):
    let leftIndex = lowerBound(leftBounds[posterIndex])
    let rightIndex = lowerBound(rightBounds[posterIndex])
    var current = findNext(leftIndex)
    if current <= rightIndex:
      visibleCount += 1
      while current <= rightIndex:
        nextFree[current] = findNext(current + 1)
        current = findNext(current)
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
