<https://www.spoj.com/problems/IZHONYT/>

## Problem

Wagons arrive in random order and leave in label order through parallel tracks. Input gives `N`, `M` and the wagon labels; output the chosen track per input wagon, then the track per departure label.
| item | bound |
|---|---|
| wagons N | 1 to 800000 |
| tracks M | 1 to 100000, at most N |
| wagon labels | a permutation of 1 to N |
| judge limit | 1000 ms, 1536 MB |

A solution always exists. Each track is a queue, so labels on one track increase in input order.

Sample input:

```
6 3
2 5 1 4 6 3
```

Sample output:

```
1 1 2 2 1 3
2 1 3 2 1 1
```

## Idea

Keep one number per track: the last wagon assigned there. Use the smallest track whose last wagon is smaller than the arriving wagon, like placing a card on the first pile that accepts it. Binary search finds that track because last wagons decrease with track number.

Each wagon needs one search and one update. A fresh track opens only when every existing track is blocked. Testing all assignments instead grows exponentially.

The decreasing order of track tails makes a fast search possible.

## Why It Works

1. A track works only when its last wagon label is below the arriving label.
2. A new track starts with the arriving label, which is below every blocked tail.
3. So the last wagon values stay strictly decreasing as track numbers grow.
4. The smallest usable track number gives the lexicographically smallest prefix.
5. Choosing the largest usable tail keeps tails as small as possible for later wagons.
6. The number of tracks used equals the longest decreasing subsequence length.

| term | meaning |
|---|---|
| `lastWagons` | last wagon label assigned to each track |
| `usedTracks` | number of tracks opened so far |
| `inputTracks` | track chosen for each input wagon |
| `labelTracks` | track chosen for each wagon label |

For the sample, wagon `2` opens track one and wagon `5` joins it. Wagon `1` opens track two, wagon `4` joins track two, wagon `6` returns to track one, and wagon `3` opens track three.

Every wagon appears once, so the second output line is a permutation lookup.

## Code

**Reader and buffer.** One scanner loads the wagon sequence.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The hand scanner skips all spacing.
The buffer flushes at a fixed byte threshold.
No per-number write reaches stdout.

**Greedy assignment.** A binary search picks the smallest usable track.

```nim
let wagonCount = nextInt(inputData, scanPos)
let trackLimit = nextInt(inputData, scanPos)
var lastWagons = newSeq[int](trackLimit)
var usedTracks = 0
var inputTracks = newSeq[int](wagonCount)
var labelTracks = newSeq[int](wagonCount + 1)
for wagonIndex in 0 .. wagonCount - 1:
  let wagonLabel = nextInt(inputData, scanPos)
  var lowTrack = 0
  var highTrack = usedTracks
  while lowTrack < highTrack:
    let middleTrack = (lowTrack + highTrack) div 2
    if lastWagons[middleTrack] < wagonLabel:
      highTrack = middleTrack
    else:
      lowTrack = middleTrack + 1
  if lowTrack == usedTracks:
    lastWagons[lowTrack] = wagonLabel
    usedTracks += 1
  else:
    lastWagons[lowTrack] = wagonLabel
  let trackNumber = lowTrack + 1
  inputTracks[wagonIndex] = trackNumber
  labelTracks[wagonLabel] = trackNumber
```

The predicate flips once because tails decrease.
A new track opens when no existing tail fits.
Two arrays record the choice by position and by label.

**Two output lines.** Assignment order and departure order are printed separately.

```nim
for wagonIndex in 0 .. wagonCount - 1:
  appendOutput($inputTracks[wagonIndex])
  if wagonIndex == wagonCount - 1:
    outputBuffer.add '\n'
  else:
    outputBuffer.add ' '
for wagonLabel in 1 .. wagonCount:
  appendOutput($labelTracks[wagonLabel])
  if wagonLabel == wagonCount:
    outputBuffer.add '\n'
  else:
    outputBuffer.add ' '
stdout.write outputBuffer
outputBuffer.setLen 0
```

Spaces separate values inside each line.
Each line ends with a newline.
One final flush emits the buffered text.

## Complexity

The track tails stay sorted as the train is scanned.

| phase | time | space |
|---|---|---|
| input read | one pass over N labels | one input string |
| assignment | one binary search per wagon | two mapping arrays |
| output | two lines of N numbers | block buffer |

| measure | Big O |
|---|---|
| time | O(N log M) |
| space | O(N + M) |

Checking every assignment of wagons to tracks would be exponential in N.

The sorted tails keep each wagon cheap even at full size.
