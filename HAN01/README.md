# HAN01 — Ha-noi! (SPOJ)

<https://www.spoj.com/problems/HAN01/>

## Problem

Each case gives an optimal Tower of Hanoi run. All n disks start on peg 1, the goal is peg 2, and k moves have already happened. Print where every disk sits after those k moves.

Input: one integer t, then t lines holding n and k. Output: three lines per case, one for peg 1, peg 2 and peg 3. Each line starts with the peg number and a colon, then lists its disks from largest to smallest with `|` between them. An empty peg prints only its number and colon.

The bounds from the statement:

| Item | Bound |
|---|---|
| Disk count n | 3 through 60 |
| Move count k | 1 through 2^n − 1, at most 1,152,921,504,606,846,975 |
| Test cases t | not fixed by the statement |
| Output bytes per case at n = 60 | 180 |
| Judge limit | 2 s, 1536 MB |

The largest k drives the design, since replaying that many moves is impossible.

The sample input and output, byte for byte:

```
3
3 6
32 889397450
31 16543
```

```
1: 1
2: 3|2
3:
1: 32|31|28|25|18|17|14|3
2: 30|29|26|13|12|11|10|9|6|5|2
3: 27|24|23|22|21|20|19|16|15|8|7|4|1
1: 31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|7|6
2: 15|8|5|4|3|2|1
3: 14|13|12|11|10|9
```

## Idea

Read each disk's own timetable instead of replaying the puzzle. Picture a bus timetable: a disk reaches its next peg at fixed intervals, so counting intervals tells you where it stands.

The algorithm is a closed-form move count plus a three-peg cycle. Disk d first moves at step 2^(d−1) and then every 2^d steps. Count those steps to get `moveCount`, then walk `moveCount` places around that disk's peg cycle. Each disk costs one shift, one division and one modulo, so one case costs O(n) time.

Replaying the moves costs O(k), and k reaches 2^60 − 1. That replay cannot finish inside two seconds.

A disk's timetable replaces the whole move history.

## Why It Works

1. The optimal run of d disks takes 2^d − 1 moves. The largest disk rests while the smaller d − 1 disks shuttle, then moves once. So disk d first moves at step 2^(d−1), then every 2^d steps.
2. Counting completed moves is arithmetic. When k is below 2^(d−1), `moveCount` is zero. Otherwise it equals (k − 2^(d−1)) div 2^d + 1.
3. Each disk visits the three pegs in a fixed cycle. An even n − d gives the order 1, 2, 3. An odd n − d gives 1, 3, 2.
4. Printed disks run from largest to smallest. The loop counts disk numbers downward and writes a separator after the first disk on a peg.

The terms below turn k into a peg number:

| Term | Meaning |
|---|---|
| 2^(d−1) | first step on which disk d moves |
| 2^d | step gap between two moves of disk d |
| `moveCount` | completed moves of disk d after k steps |
| `cycleIndex` | `moveCount mod 3`, the position in the peg cycle |
| n − d parity | selects 1, 2, 3 when even, or 1, 3, 2 when odd |

The parity handles direction, and the modulo handles position.

A script traces case (4, 6) below:

```
disk first gap moves index forward peg
1    1     2   3     0     no      1
2    2     4   2     2     yes     3
3    4     8   1     1     no      3
4    8    16  0     0     yes     1

1: 4|1
2:
3: 3|2
```

Disks 2 and 3 both land on peg 3, so the last printed line reads 3: 3|2.

## Code

**Constants and reader.** The scanner walks the input buffer by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxDiskCount = 60

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value
```

`firstDigitValue` converts a digit byte into its value. The scanner builds no token object. The int64 value holds 2^60 − 1.

**Buffers.** Input lands in one string, and output leaves in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var diskLabels: array[maxDiskCount + 1, string]
for diskNumber in 1 .. maxDiskCount:
  diskLabels[diskNumber] = $diskNumber

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Disk labels are built once, so the hot loop never formats a number. A write happens only when the buffer reaches `flushBlockBytes`.

**Disk positions.** One loop computes every disk's peg.

```nim
var scanPos = 0
let caseCount = int(nextInt64(inputData, scanPos))
for caseIndex in 0 ..< caseCount:
  let diskCount = int(nextInt64(inputData, scanPos))
  let stepCount = nextInt64(inputData, scanPos)
  var diskPeg: array[maxDiskCount + 1, int]
  for diskNumber in 1 .. diskCount:
    let firstMoveStep = 1'i64 shl (diskNumber - 1)
    var moveCount: int64 = 0
    if stepCount >= firstMoveStep:
      moveCount = (stepCount - firstMoveStep) div (1'i64 shl diskNumber) + 1
    let cycleIndex = int(moveCount mod 3)
    let turnIsForward = (diskCount - diskNumber) mod 2 == 0
    if cycleIndex == 0:
      diskPeg[diskNumber] = 1
    elif turnIsForward:
      diskPeg[diskNumber] = cycleIndex + 1
    else:
      diskPeg[diskNumber] = 4 - cycleIndex
```

The shift gives the first step of disk d, and the division gives its move count. The parity branch picks the forward or reverse cycle. The same 61-slot array serves every case.

**Peg lines.** The writer emits three lines and flushes the tail.

```nim
  for pegNumber in 1 .. 3:
    appendOutput($pegNumber)
    appendOutput(":")
    var firstDiskOnPeg = true
    for diskNumber in countdown(diskCount, 1):
      if diskPeg[diskNumber] == pegNumber:
        if firstDiskOnPeg:
          appendOutput(" ")
          firstDiskOnPeg = false
        else:
          appendOutput("|")
        appendOutput(diskLabels[diskNumber])
    appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

`countdown` prints disks from largest to smallest. The flag suppresses the space on an empty peg. The final write covers the tail block.

## Complexity

Costs split into four phases:

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Disk positions | one shift, one division, one modulo per disk | 61 peg slots |
| Peg lines | one append per printed disk | 128 KiB output buffer |
| Final write | one write for the tail | block buffer |

Output bytes dominate at large t, while the peg work stays linear in n.

The asymptotic bounds follow from n at most 60:

| Measure | Big O |
|---|---|
| Time | O(t · n + output bytes) |
| Space | O(n + `flushBlockBytes`) |

Replaying k moves costs O(k) per case and reaches 2^60 steps. This method uses at most 60 disk updates per case.
