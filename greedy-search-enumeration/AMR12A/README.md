# AMR12A — The Black Riders (SPOJ)

<https://www.spoj.com/problems/AMR12A/>

## Problem

Hobbits must reach holes before riders arrive. Each hole holds two hobbits, but the second place opens only C time units after the first hobbit arrives. Given every travel time, find the earliest moment when at least K hobbits are safe.

Input starts with `T`, the test count. Each case gives N, M, K, and C, followed by N rows of M travel times. Print the minimum time for each case.

| item | bound |
|---|---|
| test cases T | 1 to 6 |
| hobbits N | 1 to 100 |
| holes M | 1 to 100 |
| needed K | 1 to min(N, 2M) |
| dig time C | 1 to 9999999 |
| travel time | 1 to 9999999 |
| judge limit | 1000 ms, 1536 MB |

The sample from the statement:

```
2
3 3 2 10
9 11 13
2 10 14
12 15 12
4 3 3 8
1 10 100
1 10 100
100 100 6
12 10 10
```

```
10
9
```

## Idea

Treat each hole as two seats that must be reserved by a deadline, like booking a train compartment where the lower berth must be occupied first. The second seat opens C minutes after the first, so a candidate deadline turns every hole into two fixed slots. A bipartite matching then decides whether enough seats exist.

The algorithm binary searches the deadline and runs an augmenting-path matching for each guess. Each check visits at most 2M slots per hobbit. Testing all possible deadlines one by one would be far slower.

## Why It Works

1. A hobbit reaching a hole at time `t` finishes digging at `t + C`.
2. By deadline `D`, a hole's first slot accepts travel times at most `D`, and its second slot accepts times at most `D - C`.
3. If two hobbits can share a hole, the faster one can take the first slot, so the two-slot rule loses no valid plan.
4. Feasibility grows with `D`, which lets a binary search find the smallest working deadline.
5. An augmenting path increases the matching size by one, so reaching K matches proves K hobbits are safe.

| term | meaning |
|---|---|
| `travelTimes` | travel time from each hobbit to each hole |
| `diggingTime` | extra time needed to open a hole's second slot |
| `slotOwner` | hobbit currently matched to each hole slot |
| `visitedSlots` | slots seen during one augmenting search |
| `canUseSlot` | deadline test for one hobbit and one slot |
| `tryAssign` | augmenting-path search from one hobbit |

The table names the travel matrix and the matching arrays.

A script trace of the sample follows.

| case | deadline | matching plan | answer |
|---|---|---|---|
| first | 10 | hobbit 1 to hole 1, hobbit 2 to hole 2 | 10 |
| second | 9 | hobbits 1 and 2 to hole 1, hobbit 3 to hole 3 | 9 |

Both plans are feasible at the printed time and not at any smaller one.

## Code

**Input and matching helpers.** The scanner loads travel times; each hole contributes two slots.

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

var travelTimes: seq[int] = @[]
var holeCount = 0
var diggingTime = 0
var slotOwner: seq[int] = @[]
var visitedSlots: seq[bool] = @[]

proc canUseSlot(hobbitIndex: int, slotIndex: int, deadline: int): bool =
  if slotIndex < 0 or slotIndex >= 2 * holeCount:
    return false
  let holeIndex = slotIndex div 2
  let travelTime = travelTimes[hobbitIndex * holeCount + holeIndex]
  if slotIndex mod 2 == 0:
    return travelTime <= deadline
  return travelTime + diggingTime <= deadline

proc tryAssign(hobbitIndex: int, deadline: int): bool =
  for slotIndex in 0 .. 2 * holeCount - 1:
    if visitedSlots[slotIndex] or not canUseSlot(hobbitIndex, slotIndex, deadline):
      continue
    visitedSlots[slotIndex] = true
    if slotOwner[slotIndex] == -1 or tryAssign(slotOwner[slotIndex], deadline):
      slotOwner[slotIndex] = hobbitIndex
      return true
  return false
```

Two consecutive slot indexes belong to each hole.
The second slot subtracts the digging time from the deadline.
An augmenting path reassigns an earlier hobbit when needed.

**Binary search driver.** Each case searches the smallest feasible deadline.

```nim
proc enoughHobbits(deadline: int, hobbitCount: int, neededCount: int): bool =
  for slotIndex in 0 .. 2 * holeCount - 1:
    slotOwner[slotIndex] = -1
  var assignedCount = 0
  for hobbitIndex in 0 .. hobbitCount - 1:
    for slotIndex in 0 .. 2 * holeCount - 1:
      visitedSlots[slotIndex] = false
    if tryAssign(hobbitIndex, deadline):
      assignedCount += 1
      if assignedCount >= neededCount:
        return true
  return false

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let hobbitCount = nextInt(inputData, scanPos)
  holeCount = nextInt(inputData, scanPos)
  let neededCount = nextInt(inputData, scanPos)
  diggingTime = nextInt(inputData, scanPos)
  travelTimes = newSeq[int](hobbitCount * holeCount)
  var longestTravel = 0
  for hobbitIndex in 0 .. hobbitCount - 1:
    for holeIndex in 0 .. holeCount - 1:
      let travelTime = nextInt(inputData, scanPos)
      travelTimes[hobbitIndex * holeCount + holeIndex] = travelTime
      if travelTime > longestTravel:
        longestTravel = travelTime
  slotOwner = newSeq[int](2 * holeCount)
  visitedSlots = newSeq[bool](2 * holeCount)
  var lowBound = 0
  var highBound = longestTravel + diggingTime + 1
  while lowBound + 1 < highBound:
    let middle = (lowBound + highBound) div 2
    if enoughHobbits(middle, hobbitCount, neededCount):
      highBound = middle
    else:
      lowBound = middle
  appendOutput($highBound)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The upper bound is always feasible because every slot opens by then.
Visited slots reset for each hobbit so a search starts clean.
The first feasible midpoint becomes the final answer.

## Complexity

Matching work dominates each binary search step.

| phase | time | space |
|---|---|---|
| input read | one pass over `N*M` travel times | one travel matrix |
| feasibility check | augmenting paths over 2M slots | two slot arrays |
| binary search | logarithm of the travel range | constant |
| output | one line per case | block buffer |

The number of hobbits and holes drives each check.

| measure | Big O |
|---|---|
| time | `O(log(maxTravel + C) * N^2 * M)` worst case |
| space | `O(NM + M)` |

Trying every candidate time would repeat matching far more often. Binary search keeps the number of checks small.
