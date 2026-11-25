# FN16SWAP — Swap Space (SPOJ)

<https://www.spoj.com/problems/FN16SWAP/>

## Problem

Every drive is full, and reformatting changes its capacity. Find the smallest extra drive needed so all old data survives the conversion, whatever order you choose.

Input holds test cases until end of file. Each case starts with the drive count, then one line per drive with its old capacity and new capacity. Output one line per case with the required extra capacity in gigabytes.

| item | bound |
|---|---|
| drives per case | 1 to 1000000 |
| old and new capacity | 1 to 1000000000 |
| total data | up to 10^15 gigabytes |
| judge limit | 4000 ms, 1536 MB |

The drive count drives the design, so the order must be found by sorting rather than search.

The exact sample input is:

    4
    6 6
    1 7
    3 5
    3 5
    4
    2 2
    3 3
    5 1
    5 10

The exact sample output is:

    1
    5

## Idea

Create room before you consume it, like emptying small boxes before discarding large ones. Split drives into those that gain space and those that lose it. Do gaining drives in increasing old capacity, then losing drives in decreasing new capacity. Buy extra only when free space falls below the next drive's data.

The takeaway is that two sorted lists give the cheapest conversion order.

## Why It Works

1. Free space after some reformats equals extra capacity plus the gains of finished drives.
2. A gaining drive helps every later drive, so doing it earlier never hurts.
3. Among gaining drives, smaller old capacity comes first by an exchange argument.
4. A losing drive only reduces free space, so it belongs after all gaining drives.
5. Among losing drives, larger new capacity comes first by the same exchange argument.

| term | meaning |
|---|---|
| `growingDrives` | drives whose new capacity is at least the old one |
| `shrinkingDrives` | drives whose new capacity is smaller |
| `freeSpace` | space available before the next reformat |
| `extraCapacity` | total capacity bought so far |

The table shows that the two lists partition every drive exactly once.

A script trace of the first sample case follows:

    sorted growing drives: (1,7) (3,5) (3,5) (6,6)
    (1,7): free 0, buy 1, move 1 out, reformat to 7 -> free 7
    (3,5): free 7-3+5 = 9
    (3,5): free 9-3+5 = 11
    (6,6): free 11-6+6 = 11, extra stays 1

The trace explains why one gigabyte of extra space is enough.

## Code

**Input and scanning.** The reader loads cases and parses capacities.

```nim
import algorithm

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

proc hasMoreData(data: string, pos: var int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9'):
    probe += 1
  if probe < data.len:
    pos = probe
    return true
  return false
```

The scanner skips every separator between numbers.
A probe position detects the end of the last case.
Capacities are positive, so no sign handling is needed.

**Buffered output.** One string holds the answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 131072 bytes.
Only one final write follows the loop.
Each case contributes a single short line.

**Order and simulation.** Two comparators define the two sorted lists.

```nim
type DriveCapacities = tuple[oldCapacity: int64, newCapacity: int64]

proc byOldCapacity(first: DriveCapacities, second: DriveCapacities): int =
  if first.oldCapacity < second.oldCapacity:
    return -1
  elif first.oldCapacity > second.oldCapacity:
    return 1
  return 0

proc byNewCapacityDescending(first: DriveCapacities, second: DriveCapacities): int =
  if first.newCapacity > second.newCapacity:
    return -1
  elif first.newCapacity < second.newCapacity:
    return 1
  return 0
```

Growing drives sort by old capacity in ascending order.
Shrinking drives sort by new capacity in descending order.
Both comparators return three-way results for exact ordering.

**Greedy conversion.** Every drive is processed once in the chosen order.

```nim
while hasMoreData(inputData, scanPos):
  let driveCount = nextInt(inputData, scanPos)
  var growingDrives: seq[DriveCapacities] = @[]
  var shrinkingDrives: seq[DriveCapacities] = @[]
  for driveIndex in 0 .. driveCount - 1:
    let oldCapacity = int64(nextInt(inputData, scanPos))
    let newCapacity = int64(nextInt(inputData, scanPos))
    if newCapacity >= oldCapacity:
      growingDrives.add((oldCapacity, newCapacity))
    else:
      shrinkingDrives.add((oldCapacity, newCapacity))
  growingDrives.sort(byOldCapacity)
  shrinkingDrives.sort(byNewCapacityDescending)
  var freeSpace: int64 = 0
  var extraCapacity: int64 = 0
  for driveIndex in 0 .. growingDrives.len - 1:
    let drive = growingDrives[driveIndex]
    if freeSpace < drive.oldCapacity:
      extraCapacity += drive.oldCapacity - freeSpace
      freeSpace = 0
    else:
      freeSpace -= drive.oldCapacity
    freeSpace += drive.newCapacity
  for driveIndex in 0 .. shrinkingDrives.len - 1:
    let drive = shrinkingDrives[driveIndex]
    if freeSpace < drive.oldCapacity:
      extraCapacity += drive.oldCapacity - freeSpace
      freeSpace = 0
    else:
      freeSpace -= drive.oldCapacity
    freeSpace += drive.newCapacity
  appendOutput($extraCapacity)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The two loops share one space and one total.
Buying happens only when the next drive needs more room.
All arithmetic uses 64-bit integers for large sums.

## Complexity

Sorting the two lists dominates the run.

| phase | time | space |
|---|---|---|
| input read | one pass over all capacities | one input string |
| split and sort | two sorts over N drives | two arrays of pairs |
| conversion | one step per drive | constant extra space |
| output | one write per full block | block buffer |

The conversion step is linear after the sorts finish.

| measure | Big O |
|---|---|
| time | O(N log N) per case |
| space | O(N) |

Checking every conversion order would take factorial time.
The takeaway is that two sorted passes replace the whole search.
