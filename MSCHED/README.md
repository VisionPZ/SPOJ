# MSCHED — Milk Scheduling (SPOJ)

<https://www.spoj.com/problems/MSCHED/>

## Problem

Each cow gives a fixed amount of milk but must be milked before its deadline, and milking takes one time unit. Choose which cows to milk so the total milk is as large as possible.

Input starts with the cow count N, then N lines holding a gain and a deadline. Output one line with the maximum total gain.

| item | bound |
|---|---|
| cow count N | 1 to 10000 |
| gain per cow | 1 to 1000 |
| deadline | 1 to 10000 |
| judge limit | 200 ms, 1536 MB |

Time starts at zero, so a deadline d allows at most d cows before it.

Sample input:

```
4
10 3
7 5
8 1
2 1
```

Sample output:

```
25
```

Milking the cows with gains 8, 10 and 7 yields 25.

## Idea

Treat time slots as parking spaces and send the highest-paying cow to the latest space before its deadline, like valet parking the biggest clients closest to the exit. Sort cows by decreasing gain and assign each to the latest free slot at or before its deadline. A disjoint-set union finds that slot in almost constant time. A dynamic program over cows and time would cost O(N * D). One sort and one pass give the answer.

## Why It Works

1. Slot numbers are time units from 1 up to the largest deadline.
2. A cow with deadline d can occupy any slot from 1 through d.
3. Processing larger gains first means a later cow never needs to evict an earlier one.
4. Assigning the latest free slot leaves earlier slots open for tighter deadlines.
5. The parent array links each filled slot to the next free slot below it.
6. Path compression keeps each slot lookup nearly constant in cost.

The main terms:

| term | meaning |
|---|---|
| `gain` | milk produced by one cow |
| `deadline` | latest slot that cow may use |
| `parentSlots` | disjoint-set links from filled slots to free slots |
| `findFreeSlot` | routine returning the latest free slot |
| `totalMilk` | accumulated answer |

The parent array replaces a scan over all earlier slots.

A script trace of the sample:

```
gain/deadline: [(10, 3), (7, 5), (8, 1), (2, 1)]
sorted by deadline: [(8, 1), (2, 1), (10, 3), (7, 5)]
chosen gains: [10, 8, 7]
total milk: 25
```

The cow with gain 2 loses, because two cows already claim the single slot at deadline 1.

## Code

**Input, scanner, and helpers.** Cows are sorted by gain, and the union routine finds free slots.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

type Cow = object
  gain: int
  deadline: int

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

proc findFreeSlot(parentSlots: var seq[int], requestedSlot: int): int =
  var root = requestedSlot
  while parentSlots[root] != root:
    root = parentSlots[root]
  var current = requestedSlot
  while parentSlots[current] != current:
    let nextSlot = parentSlots[current]
    parentSlots[current] = root
    current = nextSlot
  return root

proc compareGain(leftCow, rightCow: Cow): int =
  if leftCow.gain > rightCow.gain:
    return -1
  if leftCow.gain < rightCow.gain:
    return 1
  return 0
```

The comparator places larger gains first.
The union walk compresses the path it visits.
Slot zero means no slot remains.

**Greedy assignment.** Each cow takes the latest slot it can reach.

```nim
let cowCount = nextInt(inputData, scanPos)
var cows = newSeq[Cow](cowCount)
var latestDeadline = 0
for cowIndex in 0 .. cowCount - 1:
  cows[cowIndex].gain = nextInt(inputData, scanPos)
  cows[cowIndex].deadline = nextInt(inputData, scanPos)
  if cows[cowIndex].deadline > latestDeadline:
    latestDeadline = cows[cowIndex].deadline
cows.sort(compareGain)
var parentSlots = newSeq[int](latestDeadline + 1)
for slotIndex in 0 .. latestDeadline:
  parentSlots[slotIndex] = slotIndex
var totalMilk: int64 = 0
for cow in cows:
  let chosenSlot = findFreeSlot(parentSlots, cow.deadline)
  if chosenSlot > 0:
    totalMilk += int64(cow.gain)
    parentSlots[chosenSlot] = findFreeSlot(parentSlots, chosenSlot - 1)
appendOutput($(totalMilk))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The parent array starts with each slot pointing to itself.
A used slot points to the free slot immediately below it.
The total fits in a 64-bit integer.

## Complexity

Sorting dominates the setup, and each slot lookup is nearly constant.

| phase | time | space |
|---|---|---|
| input read | one pass over cow lines | one input string |
| sort | O(N log N) comparisons | cow records |
| assignment | O(N) union lookups | parent array |
| output | one line | block buffer |

The parent array has one entry per possible slot.

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(D), where D is the largest deadline |

A dynamic program over cows and slots would cost O(N * D) time.
The greedy order removes that extra factor of N.
