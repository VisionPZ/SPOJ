<https://www.spoj.com/problems/DRAGONCU/>

## Problem

Report where a robot stands after `n` seconds of walking the dragon curve. The robot starts at the origin facing east, walks one unit each second, and turns left or right after each unit according to the paperfolding string `s30`.

Input holds one non-negative integer `n` per line, ending with -1. There are fewer than 5000 queries, and `n` is at most `10^9`. Output holds one `(x,y)` pair per query.

| item | bound |
|---|---|
| query n | 0 to `10^9` |
| query count | fewer than 5000 |
| terminating value | -1 |
| judge limit | 1000 ms, 1536 MB |

The sample input:

```
1
2
3
2048
1000000000
-1
```

The sample output:

```
(1,0)
(1,1)
(0,1)
(-32,32)
(9648,-31504)
```

## Idea

Folding a strip of paper twice gives a pattern whose second half mirrors the first, like a reflection in a mirror. The dragon curve has the same split: `s_m = s_{m-1} + '1' + reverseComplement(s_{m-1})`. So a prefix of `2^m + r` steps is the endpoint of the first `2^m` steps plus a rotated copy of a smaller mirrored walk. Recursion splits only `m` times, so one query costs about 30 steps instead of a billion.

## Why It Works

1. The string length grows as `2^(m+1) - 1`, so `s30` covers every query up to `10^9` steps.
2. After `2^m` steps the robot always faces west, for every `m >= 1`.
3. The endpoint after `2^m` steps is `fullX[m], fullY[m]`, which equals `(1+i)^m` in complex form.
4. The turn string splits into a forward half, one left turn, and a mirrored half.
5. Walking the mirrored half from a rotated start is the same walk scaled by a 90-degree rotation, so a smaller recursive call returns its displacement.
6. The forward walk subtracts that mirrored displacement; the mirrored walk adds it.

| term | meaning |
|---|---|
| `level` | index `m` of the power-of-two block `2^m` |
| `steps` | number of seconds still to simulate |
| `forwardWalk` | displacement of a normal prefix |
| `mirrorWalk` | displacement of a reverse-complement prefix |
| `fullX`, `fullY` | endpoint of `2^m` steps, precomputed once |

The table names both walk flavours and the precomputed endpoints.

A worked trace at `n = 3`:

| step | action | position |
|---|---|---|
| 0 | start facing east | (0,0) |
| 1 | walk east, then turn left | (1,0) |
| 2 | walk north, then turn left | (1,1) |
| 3 | walk west | (0,1) |

The trace ends at `(0,1)`, matching the third sample line.

## Code

**Input and scanner.** All lines enter one buffer, and `nextInt` handles the -1 sentinel.

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
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

The minus branch reads the terminating value.
Token parsing ignores how many queries appear on each line.

**Buffered output.** One string collects coordinate lines and flushes them in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` keeps writes rare even with thousands of queries.
The buffer reaches `flushBlockBytes` before any write happens.

**Power-of-two endpoints.** Each endpoint is the previous one multiplied by `(1+i)`.

```nim
var fullX = newSeq[int](31)
var fullY = newSeq[int](31)
fullX[0] = 1
fullY[0] = 0
fullX[1] = 1
fullY[1] = 1
for levelIndex in 2 .. 30:
  fullX[levelIndex] = fullX[levelIndex - 1] - fullY[levelIndex - 1]
  fullY[levelIndex] = fullX[levelIndex - 1] + fullY[levelIndex - 1]
```

The loop fills 31 entries once, before any query.
The table removes an exponential number of repeated endpoint computations.

**Two recursive walks.** Each call splits at the largest power of two and recurses into the mirrored half.

```nim
proc mirrorWalk(level: int, steps: int): tuple[x: int, y: int]

proc forwardWalk(level: int, steps: int): tuple[x: int, y: int] =
  if steps == 0:
    return (0, 0)
  if level == 0:
    return (steps, 0)
  if level == 1:
    if steps == 1:
      return (1, 0)
    return (1, 1)
  let half = 1 shl (level - 1)
  if steps <= half:
    return forwardWalk(level - 1, steps)
  let rest = mirrorWalk(level - 1, steps - half)
  return (fullX[level - 1] - rest.x, fullY[level - 1] - rest.y)

proc mirrorWalk(level: int, steps: int): tuple[x: int, y: int] =
  if steps == 0:
    return (0, 0)
  if level == 0:
    return (steps, 0)
  if level == 1:
    if steps == 1:
      return (1, 0)
    return (1, -1)
  let half = 1 shl (level - 1)
  if steps <= half:
    return forwardWalk(level - 1, steps)
  let rest = mirrorWalk(level - 1, steps - half)
  return (fullX[level - 1] + rest.x, fullY[level - 1] + rest.y)
```

The two base cases at `level == 1` encode the first fold.
Each recursive call lowers `level`, so the depth stays at most 30.

**Query loop.** Each second count becomes one formatted coordinate line.

```nim
var seconds = nextInt(inputData, scanPos)
while seconds != -1:
  let location = forwardWalk(30, seconds)
  appendOutput("(" & $location.x & "," & $location.y & ")\n")
  seconds = nextInt(inputData, scanPos)

stdout.write outputBuffer
outputBuffer.setLen 0
```

Level 30 covers all legal queries because `2^30` exceeds `10^9`.
The final write flushes whatever the block buffer still holds.

## Complexity

Every query descends through at most 30 levels and does constant work per level.

| phase | time | space |
|---|---|---|
| input read | one pass over query tokens | one input string |
| endpoint table | 29 multiplications | two arrays of 31 values |
| query evaluation | one recursive walk per query | recursion stack of depth 30 |
| output | one append per query | block buffer |

The phase table shows that queries dominate when their count is large.

| measure | Big O |
|---|---|
| time per query | O(log n) |
| space | O(log n) for the stack |

Simulating every turn costs O(n) per query and cannot handle `10^9` seconds. The fold recursion reaches the same answer in about 30 steps.
