# POWERCAR — Car with powers (SPOJ)

<https://www.spoj.com/problems/POWERCAR/>

## Problem

A car races along a track of length `n` from `S` to `E`. Moving one step on the track costs 1 time. A wall blocks the next step, and a bullet removes it for 0 time before the step. Off-track travel costs 2 per step and cannot re-enter a wall. Find the fastest finish.

Input: `t`, then for each case `n bullets` and the track string. Output: the minimum time, or `Impossible`.

| item | bound |
|---|---|
| test cases `t` | 1 to 100 |
| track length `n` | 2 to 1000 |
| bullets | 0 to 1000 |
| track symbols | `S`, `E`, `0`, `#` |
| judge limit | 2000 ms, 1536 MB |

Sample input:

```
10
7 3
S00000E
2 2
SE
4 1
S00E
8 1
S0000##E
8 3
S0#00#0E
7 2
S0#0##E
10 4
S00#0#0##E
5 2
S000E
7 1
S0##00E
9 0
S0000##0E
```

Sample output:

```
6
1
3
13
7
12
9
4
12
15
```

## Idea

Treat each position as a row in a table, like filling a trip log from start to finish. Each row keeps the best time for every number of bullets spent, both on and off the track. All moves go forward, so one left-to-right pass settles every row.

A wall step spends one bullet and still costs the usual 1 time for the move. The off-track lane costs 2 per step. Entering or leaving that lane also costs 2. A wall cannot be entered from the lane, so a bypass always passes the wall and rejoins beyond it.

Dijkstra over `(position, lane, bullets)` explores states in priority order and pays a heap cost per relaxation. The table pass visits each state once with plain integer additions.

The takeaway: index time by position and bullets, then sweep positions once.

## Why It Works

1. Every legal move either keeps the position or increases it by one, so the state graph has no backward edges.
2. On-track step to an open cell costs 1 and spends no bullet.
3. On-track step to a wall costs 1 after spending a bullet, since firing itself is free.
4. Switching between track and lane at position `i` costs 2 in either direction.
5. Re-entering the track at `i` needs an open cell there, so a wall needs one more lane step.
6. Processing positions in order sees every predecessor of a state before that state.

| term | meaning |
|---|---|
| `onTrackCosts` | best time at a position, lane, and bullet count |
| `offTrackCosts` | best time in the lane at that position and bullet count |
| `maxShots` | bullets capped by the number of walls |
| `stride` | number of bullet states stored per position |

Worked example from sample case 4, track `S0000##E` with one bullet:

| segment | action | time |
|---|---|---|
| `0` to `4` | four open steps | 4 |
| `4` to `5` | shoot wall 5, then step | 1 |
| `5` to `7` | lane: leave, pass wall 6, rejoin at 7 | 8 |
| total |  | 13 |

The lane segment costs `2 + 2 + 2 + 2`: leave track 5, step to lane 6, step to lane 7, rejoin at 7. Rejoining at 6 is illegal because 6 is a wall.

Only walls need bullets, so `maxShots` caps the table width at the wall count.

## Code

**Input and scanner.** The digit scanner reads the header, and a character reader copies the track.

```nim
const flushBlockBytes = 1 shl 17
const infiniteCost = 1 shl 28
const trackCost = 1
const offTrackCost = 2

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

proc nextTrack(data: string, pos: var int, trackLength: int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  for position in 0 .. trackLength - 1:
    result.add data[pos]
    pos += 1
```

The track reader skips the line break before copying symbols.

**Buffered output.** Results go through one shared buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Every case emits one line.

**Cost tables.** Two reusable arrays hold all states for one case.

```nim
var onTrackCosts = newSeq[int](0)
var offTrackCosts = newSeq[int](0)
```

Reusing them avoids a fresh allocation for each test case.

**Position sweep.** Same-position switches come first, then forward moves.

```nim
proc solveRace(track: string, bulletLimit: int): string =
  let trackLength = track.len
  var wallCount = 0
  for symbol in track:
    if symbol == '#': wallCount += 1
  let maxShots = min(bulletLimit, wallCount)
  let stride = maxShots + 1
  let stateCapacity = trackLength * stride
  onTrackCosts.setLen(stateCapacity)
  offTrackCosts.setLen(stateCapacity)
  for stateIndex in 0 .. stateCapacity - 1:
    onTrackCosts[stateIndex] = infiniteCost
    offTrackCosts[stateIndex] = infiniteCost
  onTrackCosts[0] = 0
  for position in 0 .. trackLength - 1:
    let currentBase = position * stride
    if track[position] != '#':
      for shotCount in 0 .. maxShots:
        let candidate = offTrackCosts[currentBase + shotCount] + offTrackCost
        if candidate < onTrackCosts[currentBase + shotCount]:
          onTrackCosts[currentBase + shotCount] = candidate
    for shotCount in 0 .. maxShots:
      let candidate = onTrackCosts[currentBase + shotCount] + offTrackCost
      if candidate < offTrackCosts[currentBase + shotCount]:
        offTrackCosts[currentBase + shotCount] = candidate
    if position == trackLength - 1: break
    let nextBase = currentBase + stride
    for shotCount in 0 .. maxShots:
      let onCandidate = onTrackCosts[currentBase + shotCount] + trackCost
      if track[position + 1] == '#':
        if shotCount < maxShots and onCandidate < onTrackCosts[nextBase + shotCount + 1]:
          onTrackCosts[nextBase + shotCount + 1] = onCandidate
      elif onCandidate < onTrackCosts[nextBase + shotCount]:
        onTrackCosts[nextBase + shotCount] = onCandidate
      let offCandidate = offTrackCosts[currentBase + shotCount] + offTrackCost
      if offCandidate < offTrackCosts[nextBase + shotCount]:
        offTrackCosts[nextBase + shotCount] = offCandidate
```

A lane-to-track switch at a wall is skipped by the open-cell guard.

**Finish.** The smallest cost at `E` wins.

```nim
  var bestTime = infiniteCost
  let finalBase = (trackLength - 1) * stride
  for shotCount in 0 .. maxShots:
    if onTrackCosts[finalBase + shotCount] < bestTime:
      bestTime = onTrackCosts[finalBase + shotCount]
  if bestTime >= infiniteCost:
    return "Impossible"
  return $bestTime

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let trackLength = nextInt(inputData, scanPos)
  let bulletLimit = nextInt(inputData, scanPos)
  let track = nextTrack(inputData, scanPos, trackLength)
  appendOutput(solveRace(track, bulletLimit))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

An infinite best means no state reached the finish.

## Complexity

| phase | time per case | space |
|---|---|---|
| wall count | `n` symbol reads | constant |
| table reset | `n * maxShots` writes | two arrays |
| position sweep | `n * maxShots` updates | two arrays |
| finish scan | `maxShots` reads | constant |

| measure | Big O |
|---|---|
| time per case | O(n * min(bullets, walls)) |
| total time | O(t * n * bullets) |
| space | O(n * bullets) |

Dijkstra visits the same states but pays a heap cost on every relaxation. The sweep reaches each state in order with no priority queue.
