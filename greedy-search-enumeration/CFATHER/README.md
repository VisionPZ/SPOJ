# CFATHER — The Codefather (SPOJ)

<https://www.spoj.com/problems/CFATHER/>

## Problem

Move points between students so that student one ends with strictly more points than every other student. Each student either gives points or receives points, and no pair trades twice. Minimize the largest single transfer, or report that no plan works.

Input begins with `studentCount`. The next `studentCount` lines give one point total each, and student one is the first line. Output the minimum largest transfer as an integer, or the word impossible.

The bounds from the statement:

| Item | Bound |
|---|---|
| Students N | 1 to 5000 |
| Starting points P | 1 to 1000000 |
| Transfers per pair | at most one |
| Judge limit | 5000 ms, 1536 MB |

Only students above the target need to give, so the answer depends on two sorted lists of surpluses and spare capacity.

The sample input:

```
4
500
300
900
100
```

The sample output:

```
202
```

The largest transfer of 202 moves points from student three to students two and four.

## Idea

Think of donors pouring water into buckets, where each donor can pour at most one jug per bucket, like filling cups through a narrow spout shared by every pair.

The algorithm is binary search on the answer, with a Hall-type feasibility test at each guess. Sort the required losses from largest to smallest and the receiver capacities from smallest to largest. For a guess M, the k largest donors can send at most the sum of min(capacity, M times k), checked with prefix sums and a binary search. Each guess costs O(N log N). Checking every transfer amount one by one would cost up to a million passes. The takeaway is to turn the flow conditions into one monotone test and binary search it.

## Why It Works

1. Student one never joins a transfer, so the target for every other student is `targetPoints` equal to P1 minus one.
2. A student above the target must be a giver and must shed at least its surplus.
3. A student at or below the target can be a receiver with spare room equal to the target minus its points.
4. A giver cannot receive, so transfers only go from givers to receivers, at most M points per pair.
5. For any k givers, each receiver accepts at most min(capacity, M times k) points from that group.
6. The k largest losses are the hardest group, so checking those k groups proves the whole transportation plan exists.
7. Feasibility is monotone in M, so binary search finds the minimum.

The main terms:

| Term | Meaning |
|---|---|
| `losses` | surplus points each giver must shed |
| `capacities` | spare room each receiver can absorb |
| `lossPrefix` | running total of sorted losses |
| `capacityPrefix` | running total of sorted capacities |

The table shows that both sorted lists reduce a group test to two prefix lookups.

The generator trace for the sample uses these visible values:

```
target points:      500 - 1 = 499
losses:             [401]
capacities:         [199, 399]
guess 201:          min(199,201) + min(399,201) = 199 + 201 = 400  < 401 -> fail
guess 202:          min(199,202) + min(399,202) = 199 + 202 = 401  >= 401 -> pass
answer: 202
```

The trace reproduces the sample answer.

## Code

**Input and scanning.** The reader loads the header and every student total, then splits students into givers and receivers.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let studentCount = nextInt(inputData, scanPos)
var pointTotals = newSeq[int](studentCount)
for studentIndex in 0 .. studentCount - 1:
  pointTotals[studentIndex] = nextInt(inputData, scanPos)

let targetPoints = pointTotals[0] - 1
var losses = newSeq[int](studentCount)
var capacities = newSeq[int](studentCount)
var lossCount = 0
var capacityCount = 0
for studentIndex in 1 .. studentCount - 1:
  if pointTotals[studentIndex] > targetPoints:
    losses[lossCount] = pointTotals[studentIndex] - targetPoints
    lossCount += 1
  else:
    capacities[capacityCount] = targetPoints - pointTotals[studentIndex]
    capacityCount += 1
losses.setLen(lossCount)
capacities.setLen(capacityCount)
```

Student one is skipped by starting the loop at index one.
Zero loss and zero capacity are handled before any search.
Both temporary arrays are trimmed to their used lengths.

**Feasibility test.** Sorted lists and prefix sums make each guess cheap.

```nim
if lossCount == 0:
  appendOutput("0\n")
elif capacityCount == 0:
  appendOutput("impossible\n")
else:
  proc compareLosses(left: int, right: int): int =
    if left > right: return -1
    if left < right: return 1
    return 0

  proc compareCapacities(left: int, right: int): int =
    if left < right: return -1
    if left > right: return 1
    return 0

  losses.sort(compareLosses)
  capacities.sort(compareCapacities)
  var lossPrefix = newSeq[int64](lossCount + 1)
  for index in 0 .. lossCount - 1:
    lossPrefix[index + 1] = lossPrefix[index] + int64(losses[index])
  var capacityPrefix = newSeq[int64](capacityCount + 1)
  for index in 0 .. capacityCount - 1:
    capacityPrefix[index + 1] = capacityPrefix[index] + int64(capacities[index])

  proc canTransfer(maxTransfer: int): bool =
    for giverCount in 1 .. lossCount:
      let perReceiver = int64(maxTransfer) * int64(giverCount)
      var low = 0
      var high = capacityCount
      while low < high:
        let middle = (low + high) div 2
        if int64(capacities[middle]) <= perReceiver:
          low = middle + 1
        else:
          high = middle
      let available = capacityPrefix[low] + perReceiver * int64(capacityCount - low)
      if lossPrefix[giverCount] > available:
        return false
    return true
```

Losses are sorted descending, and capacities ascending.
A binary search finds where capacities exceed the per-receiver bound.
Products use int64 because five thousand times a million exceeds int32.

**Binary search and output.** The smallest feasible transfer becomes the answer.

```nim
  var lowBound = 0
  var highBound = losses[0]
  if not canTransfer(highBound):
    appendOutput("impossible\n")
  else:
    while lowBound < highBound:
      let middle = (lowBound + highBound) div 2
      if canTransfer(middle):
        highBound = middle
      else:
        lowBound = middle + 1
    appendOutput($lowBound & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The upper bound is the largest single loss, which always suffices when any plan exists.
Each halving step calls the same monotone test once.
The final line is written through the shared buffer.

## Complexity

Sorting once dominates the per-guess work, and the search needs logarithmically many guesses.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over N totals | point array |
| Sorting and prefixes | O(N log N) | two prefix arrays |
| Feasibility search | O(N log N log P) | constant scalars |
| Output | one line | block buffer |

The table shows that each guess scans all giver group sizes with one inner binary search.

| Measure | Big O |
|---|---|
| Time | O(N log N log P) |
| Space | O(N) |

Trying every transfer amount up to P would need a full pass per amount. Binary search cuts that to a few dozen feasibility tests.
