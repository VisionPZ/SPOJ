# AGGRCOW — Aggressive Cows (SPOJ)
<https://www.spoj.com/problems/AGGRCOW/>

## Problem

A farmer must place aggressive cows in the widest possible stalls along a long barn.
He wants the largest gap that still fits every cow without a fight.

The first line gives the case count. Each case gives N stalls and C cows, then N stall positions. Print the largest achievable minimum distance between two cows.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Stalls N | 2 to 100000 |
| Cows C | 2 to N |
| Stall position | 0 to 1000000000 |
| Judge time | 2 s |
| Judge memory | 1536 MB |

The large stall count favors a sorted scan over any placement search.

The sample input and its expected output follow byte for byte.

```
1
5 3
1
2
8
4
9
```

```
3
```


## Idea

Guess a distance and walk the sorted stalls, like checking whether a row of chairs fits a spacing rule.
The program sorts the stall positions, then applies binary search (repeated guessing over an ordered range). A greedy scan places each cow in the earliest stall that respects the guessed gap.
That scan costs one pass over N stalls. Sorting costs O(N log N), and the binary search adds O(log range) passes.
Trying every set of C stalls is combinatorial and far slower.
Sort once, then test distances with a linear greedy scan.

## Why It Works

1. Sorting puts stalls in increasing order, so an earliest-fit greedy scan maximizes the cow count for any gap.
2. If greedy fits C cows at gap d, every smaller gap also fits. Monotonicity allows binary search on the answer.
3. `canPlace` returns early as soon as C cows are placed.
4. The upper bound uses last stall minus first stall plus one, so the search never misses a valid gap.
5. The greedy scan never looks back, which gives its linear cost.

Three terms carry the proof.

| Term | Meaning |
| --- | --- |
| gap | candidate minimum distance between cows |
| feasible | a gap that fits at least C cows |
| monotone | once a gap fails, larger gaps also fail |

They explain why a binary search replaces enumeration.

A script check of the sample sorts [1,2,8,4,9] into [1,2,4,8,9].
At gap 4, greedy places cows at 1 and 8 only, so the test fails.
At gap 3, greedy places cows at 1, 4, and 8, so the test succeeds.
Binary search therefore reports 3.

## Code

**Integer scanner.**
```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scanner skips separators and folds digits into a value. It walks one input buffer by index. No token objects are allocated.

**Feasibility test.**
```nim
proc canPlace(stalls: seq[int], cowCount, gap: int): bool =
  var placedCount = 1
  var lastIndex = 0
  for i in 1..<stalls.len:
    if stalls[i] - stalls[lastIndex] >= gap:
      placedCount += 1
      lastIndex = i
      if placedCount >= cowCount: return true
  return cowCount <= 1
```

The loop starts with a cow in the first stall. It places the next cow only when the distance reaches the gap. An early return stops the scan once C cows fit.

**Binary search driver.**
```nim
let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let stallCount = nextInt(inputData, scanPos)
  let cowCount = nextInt(inputData, scanPos)
  stalls.setLen(stallCount)
  for i in 0..<stallCount:
    stalls[i] = nextInt(inputData, scanPos)
  stalls.sort(system.cmp[int])
  var lowGap = 0
  var highGap = stalls[stallCount - 1] - stalls[0] + 1
  while lowGap < highGap:
    let midGap = (lowGap + highGap + 1) div 2
    if canPlace(stalls, cowCount, midGap):
      lowGap = midGap
    else:
      highGap = midGap - 1
  appendOutput($(lowGap))
  outputBuffer.add '\n'
```

The driver sorts stalls before searching. The midpoint uses a rounded-up division to avoid an infinite loop. One answer is appended per case to the shared buffer.


## Complexity

The sort dominates small ranges, and the search adds a few linear scans.

| Phase | Time | Space |
| --- | --- | --- |
| read and sort | O(N log N) | one stall array |
| one gap test | O(N) | constant |
| binary search | O(N log range) | constant |

Each gap test stays linear because the scan never backtracks.

Big O uses stall count N and position range R.

| Measure | Big O |
| --- | --- |
| time | O(N log N + N log R) |
| space | O(N) |

Enumerating cow subsets would be exponential, so the monotone test wins.
