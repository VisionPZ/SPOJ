# PONDORO — Pondoro (SPOJ)
<https://www.spoj.com/problems/PONDORO/>

## Problem

A world is a string of n spots marked R for rain or . for dry. A mouth of length L drinks from a run of L spots and gains one litre per rainy spot. Among the given mouth lengths, choose one that can drink the most water, breaking ties toward the shortest length. Report that length.

The first line gives n and m. The second line gives the world string. The third line gives m distinct mouth lengths. Print one integer, the chosen length.

| Constraint | Value |
| --- | --- |
| World length n | at most 100000 |
| Mouth count m | at most 100000 |
| Mouth lengths | distinct positive integers |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

A mouth may stand anywhere, so only the best contiguous window matters.

The first sample pair follows byte for byte.

```
12 3
R..RR.RR..RR
4 5 6
```

```
5
```

Lengths 5 and 6 both reach four rainy spots, so length 5 wins the tie.

## Idea

Longer mouths are like wider nets: a wider net never catches fewer rain spots, so the widest mouth already shows the best possible catch. The program finds the best window for the longest mouth, then finds the shortest window span that reaches that same rainy-spot count. A sliding window gives the count in O(n), and a pass over rain positions gives the span in O(n). Trying every mouth against every window costs O(n times m), which is far too large. Read the best count from the widest mouth, then pick the shortest offered length that still reaches it.

## Why It Works

1. Let f(L) be the maximum rainy spots in any window of length L.
2. Extending a window adds at most one rainy spot, so f never decreases as L grows.
3. The best f over the given lengths therefore occurs at the longest mouth.
4. A sliding window computes that one value with constant work per move.
5. If k rainy spots are needed, the shortest window holding them spans consecutive rainy positions.
6. The smallest such span is the least L with f(L) at least k.
7. The answer is then the shortest offered length at least that span.

The table names the values carried between steps.

| Term | Meaning |
| --- | --- |
| `bestCount` | f of the longest mouth, the best water total available |
| `rainPositions` | sorted indices of all rainy spots |
| `minimalRequired` | shortest window length reaching bestCount rainy spots |
| `bestMouth` | shortest offered length that reaches minimalRequired |

One sliding pass and one span pass replace all mouth-window pairs.

A script check of the first sample lists the four-spot spans.

| First R index | Last R index | Span length |
| --- | --- | --- |
| 0 | 6 | 7 |
| 3 | 7 | 5 |
| 4 | 10 | 7 |
| 6 | 11 | 6 |

The smallest span is 5, and the offered lengths all reach it except 4. The answer is 5. With no rain, bestCount is zero and minimalRequired stays zero, so the shortest offered mouth wins.

## Code

**Input and world reader.** The scanner reads the header, the string, then the mouth lengths.

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

proc nextWorldString(data: string, pos: var int): string =
  while pos < data.len and data[pos] != 'R' and data[pos] != '.':
    pos += 1
  var world = ""
  while pos < data.len and (data[pos] == 'R' or data[pos] == '.'):
    world.add data[pos]
    pos += 1
  return world

```

The string reader starts at the first R or dot. It stops at the following whitespace.

**Buffered output.** The answer is written through one shared string.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A single flush emits the chosen length. No write occurs during the scans.

**Widest-mouth window.** A sliding window counts rainy spots for the longest mouth.

```nim
let worldLength = nextInt(inputData, scanPos)
let mouthCount = nextInt(inputData, scanPos)
let world = nextWorldString(inputData, scanPos)
var mouthLengths = newSeq[int](mouthCount)
var longestMouth = 0
for mouthIndex in 0 .. mouthCount - 1:
  mouthLengths[mouthIndex] = nextInt(inputData, scanPos)
  if mouthLengths[mouthIndex] > longestMouth:
    longestMouth = mouthLengths[mouthIndex]
var rainingCount = 0
for index in 0 .. longestMouth - 1:
  if world[index] == 'R':
    rainingCount += 1
var bestCount = rainingCount
var startIndex = 1
while startIndex + longestMouth <= worldLength:
  if world[startIndex - 1] == 'R':
    rainingCount -= 1
  if world[startIndex + longestMouth - 1] == 'R':
    rainingCount += 1
  if rainingCount > bestCount:
    bestCount = rainingCount
  startIndex += 1
```

The first window is counted directly. Each later move drops one spot and adds one spot.

**Required span and tie break.** Consecutive rainy positions give the shortest span, then the smallest qualifying mouth is selected.

```nim
var rainPositions = newSeq[int]()
for index in 0 .. worldLength - 1:
  if world[index] == 'R':
    rainPositions.add index
var minimalRequired = 0
if bestCount > 0:
  minimalRequired = worldLength + 1
  var firstRain = 0
  while firstRain + bestCount <= rainPositions.len:
    let span = rainPositions[firstRain + bestCount - 1] - rainPositions[firstRain] + 1
    if span < minimalRequired:
      minimalRequired = span
    firstRain += 1
var bestMouth = longestMouth
for mouthIndex in 0 .. mouthCount - 1:
  if mouthLengths[mouthIndex] >= minimalRequired and mouthLengths[mouthIndex] < bestMouth:
    bestMouth = mouthLengths[mouthIndex]
appendOutput($bestMouth)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each group of bestCount rainy spots gives one candidate span. The final loop applies the shortest-length tie break.

## Complexity

Two linear passes replace the full grid of mouth and window combinations.

| Phase | Time | Space |
| --- | --- | --- |
| read input | one pass over n and m values | string and length array |
| sliding window | one pass over n spots | three integers |
| span and tie break | O(n + m) | rain position array |
| output | one line | block buffer |

No pass nests inside another, so the total is linear in the input size.

| Measure | Big O |
| --- | --- |
| time | O(n + m) |
| space | O(n + m) |

Checking every mouth against every window costs O(n times m), while the monotone water count and one span pass cost O(n + m). The longest mouth fixes the target, and the shortest qualifying mouth wins the tie.
