# UOFTCD — A Frightening Evening (SPOJ)

<https://www.spoj.com/problems/UOFTCD/>

## Problem

Find the least time Bob holds Alice's hand during a movie, using one cover to cancel a single fear spike. Fear starts at zero, rises or falls at key moments, and Alice leaves once fear reaches the higher threshold.

Line 1 holds the movie count `N`. Each movie starts with a line `D M H L`: duration, moment count, hand threshold, and leave threshold. The next `M` lines hold `Ti Fi`, the moment time and fear change. Print one minimum number of held minutes per movie.

| item | bound |
|---|---|
| movies N | 1 to 100 |
| duration D | 1 to 1000000000 minutes |
| moments M | 0 to 100 |
| fear change Fi | -1000000 to 1000000 |
| hand threshold H | 1 to 1000000000 |
| leave threshold L | H+1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Fear never goes below zero. Covering a moment leaves fear unchanged and holding continues across it.

Sample input:

```
2
90 5 5 50
12 8
14 -4
40 6
45 11
73 -50
105 3 5 20
33 15
39 -1
52 5
```

Sample output:

```
30
19
```

Those two lines are the exact expected output.

## Idea

Think of fear as a thermometer: Bob holds her hand only while the reading sits between two marks. Covering one moment removes one push on the mercury, and we try every single moment in turn.

The solution replays the movie for each of the M+1 choices and stops a replay as soon as Alice leaves. Each replay costs O(M), so a movie costs O(M^2). Replaying minute by minute would take O(D) instead and fail for long movies.

Checking every cover choice with a short replay settles each movie.

## Why It Works

1. Fear stays constant between key moments.
2. A negative fear change is clamped to zero.
3. Bob holds her hand while fear is at least H and below L.
4. Fear at or above L makes Alice leave at that moment, so holding stops there.
5. A covered moment does not change fear, so holding continues through it.
6. Only one cover is allowed, leaving M+1 choices to compare.
7. The smallest replay cost is the required minimum.

| term | meaning |
|---|---|
| `momentTimes` | times of the key moments |
| `momentForces` | fear changes at those moments |
| `handThreshold` | H, the lower holding mark |
| `leaveThreshold` | L, the point where Alice leaves |
| `frightLevel` | current fear after the last applied moment |
| `totalHeld` | minutes held during one replay |
| `bestCost` | smallest cost over all cover choices |

The labels above match the identifiers in the code.

The first sample movie has D=90, H=5, and L=50.

| cover choice | held minutes |
|---|---|
| none | 35 |
| moment 1 | 33 |
| moment 2 | 61 |
| moment 3 | 30 |
| moment 4 | 35 |
| moment 5 | 52 |

Covering moment 3 wins, so the answer is 30.

## Code

**Input and scanner.** The reader stores all lines, and the scanner handles negative fear changes.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value
```

One newline ends each stored line.
The minus branch reads negative fear changes.
Digits are accumulated one at a time.

**Replay.** One pass applies the moments and adds held minutes between them.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc holdingCost(momentTimes: seq[int64], momentForces: seq[int64], movieLength: int64, handThreshold: int64, leaveThreshold: int64, skippedMoment: int): int64 =
  var frightLevel: int64 = 0
  var totalHeld: int64 = 0
  for momentIndex in 0 .. momentTimes.len - 1:
    if momentIndex != skippedMoment:
      frightLevel = frightLevel + momentForces[momentIndex]
      if frightLevel < 0:
        frightLevel = 0
    if frightLevel >= leaveThreshold:
      return totalHeld
    if frightLevel >= handThreshold:
      let nextTime = if momentIndex + 1 < momentTimes.len: momentTimes[momentIndex + 1] else: movieLength
      totalHeld = totalHeld + (nextTime - momentTimes[momentIndex])
  return totalHeld
```

The skipped moment never changes fear.
Leaving stops the replay at once.
The last interval ends at the movie duration.

**Choice loop.** Every cover choice is tried, and the smallest cost is written.

```nim
let movieCount = nextInt(inputData, scanPos)
for movieIndex in 0 .. movieCount - 1:
  let movieLength = nextInt(inputData, scanPos)
  let momentCount = nextInt(inputData, scanPos)
  let handThreshold = nextInt(inputData, scanPos)
  let leaveThreshold = nextInt(inputData, scanPos)
  var momentTimes = newSeq[int64](momentCount)
  var momentForces = newSeq[int64](momentCount)
  for momentIndex in 0 .. momentCount - 1:
    momentTimes[momentIndex] = int64(nextInt(inputData, scanPos))
    momentForces[momentIndex] = int64(nextInt(inputData, scanPos))
  var bestCost = holdingCost(momentTimes, momentForces, int64(movieLength), int64(handThreshold), int64(leaveThreshold), -1)
  for skipIndex in 0 .. momentCount - 1:
    let candidateCost = holdingCost(momentTimes, momentForces, int64(movieLength), int64(handThreshold), int64(leaveThreshold), skipIndex)
    if candidateCost < bestCost:
      bestCost = candidateCost
  appendOutput($bestCost)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

A skip index of -1 means no cover.
Times and costs use int64 for long movies.
The final line flushes the buffered answers.

## Complexity

Each movie replays at most M+1 times, and each replay visits at most M moments.

| phase | time | space |
|---|---|---|
| input scan | one pass over M moments | two moment arrays |
| cover search | M+1 replays of M moments | a few scalar values |
| output | one line per movie | block buffer |

The table shows a separate cost for each phase.

| measure | Big O |
|---|---|
| time per movie | O(M^2) |
| space per movie | O(M) |

Walking every minute would cost O(D) per movie and fail on long movies.

Early exit keeps each replay short when Alice leaves.
