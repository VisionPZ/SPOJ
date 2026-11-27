# IMGPROJ — Image Projections (SPOJ)

<https://www.spoj.com/problems/IMGPROJ/>

## Problem

Each image has N columns and M rows of pixel intensities. For every diagonal x + y - 1 = d, add the intensities on that diagonal, then encode the resulting vector as maximal runs.

Input starts with the image count. Each image starts with `N M`, followed by M encoded rows. Each row holds pairs `length intensity`, and the lengths in a row sum to N. A blank line may appear before each image.

Output one line per image. Each line holds pairs `length intensity` in diagonal order, with single spaces and no equal neighboring intensities.

| item | bound |
|---|---|
| images | at most 10 |
| width N | below 1000000000 |
| height M | below 1000 |
| total input | at most 4 MB |
| judge limit | 4623 ms, 1536 MB |

The width bound rules out storing a full row.

Sample input:

```
2

3 3
1 1 1 2 1 3
1 1 1 2 1 3
1 3 1 2 1 1

3 2
3 1
3 1
```

Sample output:

```
1 1 1 3 1 8 1 5 1 1
1 1 2 2 1 1
```

## Idea

A run adds one value to a whole stretch of diagonals, like writing the same number into a consecutive group of ledger lines. Record only where each contribution starts and stops.

The algorithm is a difference-event sweep. Each run creates a plus event and a minus event. Sorting events and walking them in order yields every diagonal sum without expanding the wide rows.

A naive pass would fill N columns for every row. The sweep touches only the given runs.

## Why It Works

1. Column x in row y belongs to diagonal x + y - 1, using zero-based indexes.
2. A run spanning columns c through c + L - 1 adds its intensity to L consecutive diagonals.
3. A plus event at the first diagonal and a minus event immediately after the last encode that add.
4. Between two neighboring event positions, the running sum stays constant.
5. Merging equal neighboring sums gives maximal runs.

| term | meaning |
|---|---|
| `DiagonalEvent` | a position and the change in diagonal sum there |
| `currentValue` | sum active between the last and next event |
| `pendingLength` | length of the run being accumulated |
| `lastPosition` | one past the final diagonal index |

A worked example for the first sample image:

```
row 0 runs: 1, 2, 3 on columns 0, 1, 2
row 1 runs: 1, 2, 3 on columns 0, 1, 2
row 2 runs: 3, 2, 1 on columns 0, 1, 2
diagonal sums: 1, 3, 8, 5, 1
encoded output: (1,1) (1,3) (1,8) (1,5) (1,1)
```

The five diagonal sums match the five run pairs in the sample output.

## Code

**Input, scanner, and buffer.** The whole input is read once; the scanner skips blank lines.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

type DiagonalEvent = object
  position: int64
  delta: int64

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

The event type holds a diagonal index and a signed change.
Blank lines never reach the integer scanner.
Output text waits in one buffer until the block limit is reached.

**Run emission.** Equal neighboring sums are folded into one output run.

```nim
proc emitRun(length: int64, value: int64, pendingLength: var int64,
             pendingValue: var int64, havePending: var bool, firstPair: var bool) =
  if length <= 0:
    return
  if havePending and value == pendingValue:
    pendingLength += length
    return
  if havePending:
    if not firstPair:
      appendOutput(" ")
    appendOutput($pendingLength)
    appendOutput(" ")
    appendOutput($pendingValue)
    firstPair = false
  pendingLength = length
  pendingValue = value
  havePending = true
```

Zero-length gaps produce no output pair.
A run with a new value closes the previous run first.
The first-pair flag controls spacing without a trailing space.

**Event sweep.** Sorted events turn all runs into diagonal sums in one pass.

```nim
let imageCount = nextInt(inputData, scanPos)

for imageIndex in 0 .. imageCount - 1:
  let imageWidth = int64(nextInt(inputData, scanPos))
  let imageHeight = int64(nextInt(inputData, scanPos))
  var events = newSeq[DiagonalEvent]()
  for rowIndex in 0 .. imageHeight - 1:
    var columnIndex: int64 = 0
    while columnIndex < imageWidth:
      let runLength = int64(nextInt(inputData, scanPos))
      let runIntensity = int64(nextInt(inputData, scanPos))
      events.add DiagonalEvent(position: rowIndex + columnIndex,
                               delta: runIntensity)
      events.add DiagonalEvent(position: rowIndex + columnIndex + runLength,
                               delta: -runIntensity)
      columnIndex += runLength
  events.sort(proc(left, right: DiagonalEvent): int =
    if left.position < right.position: -1
    elif left.position > right.position: 1
    else: 0)
```

Each encoded run yields exactly two events.
The explicit comparator works on both supported compilers.
Sorting cost depends on the number of runs, not on N.

**Diagonal walk.** The sweep applies changes and writes one line per image.

```nim
  var pendingLength: int64 = 0
  var pendingValue: int64 = 0
  var havePending = false
  var firstPair = true
  var currentPosition: int64 = 0
  var currentValue: int64 = 0
  var eventIndex = 0
  while eventIndex < events.len:
    let eventPosition = events[eventIndex].position
    if eventPosition > currentPosition:
      emitRun(eventPosition - currentPosition, currentValue,
              pendingLength, pendingValue, havePending, firstPair)
    while eventIndex < events.len and events[eventIndex].position == eventPosition:
      currentValue += events[eventIndex].delta
      eventIndex += 1
    currentPosition = eventPosition

  let lastPosition = imageWidth + imageHeight - 1
  if currentPosition < lastPosition:
    emitRun(lastPosition - currentPosition, currentValue,
            pendingLength, pendingValue, havePending, firstPair)
  if havePending:
    if not firstPair:
      appendOutput(" ")
    appendOutput($pendingLength)
    appendOutput(" ")
    appendOutput($pendingValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Events at the same position are summed before the next run.
The final gap covers diagonals after the last run ends.
The last flush writes all remaining characters at once.

## Complexity

Each encoded run creates two events, and sorting dominates.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| event build | one step per run | two events per run |
| sort | one sort of all events | event array |
| sweep | one pass over events | run state |
| output | one line per image | block buffer |

The event array size tracks the input size, not the image width.

| measure | Big O |
|---|---|
| time | O(E log E) for E events |
| space | O(E) |

Expanding every wide row would cost O(N M) per image, which exceeds the input size by far.
