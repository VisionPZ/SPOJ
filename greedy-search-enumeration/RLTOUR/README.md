# RLTOUR — Robert Langdon & Florence (SPOJ)

<https://www.spoj.com/problems/RLTOUR/>

## Problem

A line of Russian dolls has heights H and, for each position, the number of earlier dolls that can contain the doll there. Rebuild a line of the given heights that reproduces those counts. A valid arrangement always exists.

Input starts with the case count T. Each case gives N, then N heights, then N containment counts in position order.

Output the heights in order, separated by spaces, one line per case.

| item | bound |
|---|---|
| cases T | 1 to 500 |
| dolls N | 1 to 500 |
| height H[i] | 1 to 1000000000 |
| judge limit | 2000 ms, 1536 MB |

Small N lets each case rebuild the line directly.

Sample input:

```
2
3
12 13 14
0 0 2
3
12 14 13
0 1 0
```

Sample output:

```
13 14 12
13 12 14
```

## Idea

Work backward from the end of the line, like rebuilding a stack one box at a time.

For a doll at position i, its count plus one counts dolls up to i with height at least its own. Those dolls are the ones not yet placed when the scan runs right to left. Sorting the heights descending makes those counts increase strictly from taller to shorter, so the target picks one height group.

A scan over each height group at every position costs quadratic time, but the bound keeps it small.

The right-to-left target makes each placement forced once heights repeat.

## Why It Works

1. A doll fits inside an earlier doll exactly when that earlier height is at least its own.
2. The count at position i therefore counts earlier dolls whose height is at least H at that position.
3. Adding the doll itself gives a target of count plus one among dolls at positions i and earlier.
4. Right to left, the unplaced heights are exactly the heights at positions i and earlier.
5. For a remaining height value v, the number of remaining dolls of height at least v strictly increases as v gets smaller.
6. Only one height group can match the target, so the scan picks a forced value.
7. Repeating the step for every position rebuilds a line that matches every count.

| term | meaning |
|---|---|
| `sortedHeights` | given heights ordered from tallest to shortest |
| `containersBefore` | count of earlier dolls that contain each position |
| `placedFlags` | marks dolls already assigned to the right |
| `targetCount` | count plus one for the current position |
| `runningCount` | unplaced dolls at least as tall as the current group |
| `chosenIndex` | sorted position supplying the current doll |
| `arrangement` | rebuilt heights in line order |

The table names the values used for one placement.

A script-traced run on the first sample case shows the forced choices:

```
heights sorted: [14, 13, 12]  counts: [0, 0, 2]
position 2: target 3 -> height 12
position 1: target 1 -> height 14
position 0: target 1 -> height 13
reconstructed: [13, 14, 12]
checked counts: [0, 0, 2]
```

Each target points at one height group, and the rebuilt line reproduces the counts.

Equal heights form one group, so picking any unused doll in that group works.
The insertion sort runs once per case, before any placement.

## Code

**Input and scanner.** The reader loads the height and count arrays for every case.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The hand scanner reads both arrays in input order.
The output buffer collects the whole case before a block flush.
Parsing costs one pass over the input characters.

**Right-to-left rebuild.** The scan sorts heights, then assigns one doll per position.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let dollCount = nextInt(inputData, scanPos)
  var sortedHeights = newSeq[int](dollCount)
  for dollIndex in 0 .. dollCount - 1:
    sortedHeights[dollIndex] = nextInt(inputData, scanPos)
  var containersBefore = newSeq[int](dollCount)
  for dollIndex in 0 .. dollCount - 1:
    containersBefore[dollIndex] = nextInt(inputData, scanPos)
  for sortIndex in 1 .. dollCount - 1:
    let currentHeight = sortedHeights[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0:
      if sortedHeights[previousIndex] >= currentHeight:
        break
      sortedHeights[previousIndex + 1] = sortedHeights[previousIndex]
      previousIndex -= 1
    sortedHeights[previousIndex + 1] = currentHeight
  var placedFlags = newSeq[bool](dollCount)
  var arrangement = newSeq[int](dollCount)
  var position = dollCount - 1
  while position >= 0:
    let targetCount = containersBefore[position] + 1
    var runningCount = 0
    var chosenIndex = -1
    var groupStart = 0
    while groupStart < dollCount:
      let heightValue = sortedHeights[groupStart]
      var groupEnd = groupStart
      while groupEnd < dollCount and sortedHeights[groupEnd] == heightValue:
        if not placedFlags[groupEnd]:
          runningCount += 1
        groupEnd += 1
      if chosenIndex < 0 and runningCount == targetCount:
        var candidateIndex = groupStart
        while candidateIndex < groupEnd:
          if not placedFlags[candidateIndex]:
            chosenIndex = candidateIndex
            break
          candidateIndex += 1
      groupStart = groupEnd
    placedFlags[chosenIndex] = true
    arrangement[position] = sortedHeights[chosenIndex]
    position -= 1
  for dollIndex in 0 .. dollCount - 1:
    if dollIndex > 0:
      appendOutput(" ")
    appendOutput($arrangement[dollIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The insertion sort orders heights from tallest down.
The group loop counts only dolls still unplaced at the right.
The outer loop visits each position once, from right to left.

## Complexity

Each case sorts the heights once and scans all height groups per position.

| phase | time | space |
|---|---|---|
| input read | one pass over both arrays | one input string |
| height sort | insertion sort on N heights | one sorted array |
| rebuild | one group scan per position | placed flags and output line |

The two arrays of N values dominate space use.

| measure | Big O |
|---|---|
| time | O(N squared) per case |
| space | O(N) |

Testing every permutation would be factorial in N.
The group scan stays quadratic and fits the bound of 500 dolls.
