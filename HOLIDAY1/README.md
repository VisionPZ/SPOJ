## Problem

Each holiday occurs on day zero and then every fixed number of days. A party happens on any day when at least one remaining holiday occurs. Remove exactly k holidays so the shortest gap between two consecutive parties is as long as possible. Print the 1-based numbers of the removed holidays in increasing order, one line per test case.

| Quantity | Bound |
| --- | --- |
| Test cases | t ≤ 200 |
| Holidays | k < n ≤ 30 |
| Period | ti ≤ 10^18 |
| Time limit | 6006 ms |
| Memory limit | 1536 MB |

The small holiday count allows subset search. The large periods rule out simulating days.

## Idea

All parties repeat with the least common multiple of the kept periods. Two party days can differ by the greatest common divisor of the periods that produce them. The shortest gap equals the smallest gcd of two kept periods. A single kept holiday gives its own period as the gap.

Treat each candidate gcd as a graph threshold. An edge joins two holidays when their gcd reaches that level. Keep n - k holidays whose every pair has an edge. That group is a clique.

Binary search over the sorted pairwise gcds finds the largest level with such a clique. Simulating days is impossible because periods reach 10^18. Brute force over removal sets grows too fast.

Cost per holiday: one gcd per pair and one bounded clique test per search level.

## Why It Works

Every kept holiday occurs on day zero, so each party day is a multiple of a kept period. The difference of two multiples is a multiple of the gcd of their periods. The smallest positive difference over all pairs is the smallest pairwise gcd. No party day lies between two days that differ by this amount, so those days are consecutive.

A level g keeps only pairs with gcd at least g. This gives a shortest gap of at least g. A shortest gap of g also forces every pair to have gcd at least g. The best gap is therefore the largest feasible level.

Edge condition: gcdVal(periods[i], periods[j]) >= level. Clique size: need = vertexCount - removeCount. Color bound: need > colorCap[i] rejects a branch.

The greedy color sort splits candidates into groups of mutually non-adjacent holidays. A clique takes at most one holiday from each group. The number of groups then bounds the search inside a branch.

The generator computes this example from the sample:

```
periods       : 6 13 10 15 7
holidays kept : 3 of 5
gcd levels    : 1 2 3 5
level 1 : clique of 3
level 2 : clique of 3
level 3 : none
level 5 : none
best level    : 2
kept holidays : 1 3 4
removed       : 2 5
shortest gap  : 2 days
```

Level 2 is the largest level with a clique of three, so the program removes holidays 2 and 5.

## Code

The program reads all input once and parses digits by hand. The scanner skips separators, so blank lines do not change the parse. The int64 value holds periods up to 10^18. Cost: one pass over the input buffer.

```nim
import algorithm
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
var inputData = ""
var line = ""
while readLine(stdin, line):
  inputData.add line
  inputData.add '\n'
proc nextNum(pos: var int): int64 =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9'): pos += 1
  result = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    result = result * 10 + int64(int(inputData[pos]) - firstDigitValue)
    pos += 1
```

Euclid's rule replaces a pair by a smaller pair on each step. The remainder reaches zero in a logarithmic number of steps. Cost: one gcd computation per pair of holidays.

```nim
proc gcdVal(a, b: int64): int64 =
  var x = a
  var y = b
  while y != 0:
    let r = x mod y
    x = y
    y = r
  x
```

The color sort visits each candidate once per color class. Each class holds mutually non-adjacent holidays, so `colorCap[i]` limits the clique inside the remaining pool. Cost: bounded by the number of color classes, not by all subsets.

```nim
var vertexCount = 0
var periods: seq[int64]
var adjacency: array[30, int]
var removeBits = 0
var orderList: array[30, int]
var colorCap: array[30, int]
proc colorSort(candidates: int): int =
  var uncolored = candidates
  var colorNum = 0
  var count = 0
  while uncolored != 0:
    colorNum += 1
    var classMask = 0
    var rest = uncolored
    while rest != 0:
      let lowBit = rest and (-rest)
      var v = 0
      var shifted = lowBit
      while shifted > 1:
        shifted = shifted shr 1
        v += 1
      rest = rest xor lowBit
      if (classMask and adjacency[v]) == 0:
        classMask = classMask or lowBit
        uncolored = uncolored xor lowBit
        orderList[count] = v
        colorCap[count] = colorNum
        count += 1
  count
proc cliqueExists(need: int, candidates: int): bool =
  if need == 0: return true
  if candidates == 0: return false
  let count = colorSort(candidates)
  var pool = candidates
  for i in countdown(count - 1, 0):
    if need > colorCap[i]: return false
    let v = orderList[i]
    if cliqueExists(need - 1, pool and adjacency[v]): return true
    pool = pool xor (1 shl v)
  false
```

One helper rebuilds `adjacency` for a level, so the two callers share the same edge rule. The binary search ends after a logarithmic number of levels. Cost: one gcd per pair at each level.

```nim
proc buildAdjacency(level: int64) =
  for i in 0 .. vertexCount - 1:
    adjacency[i] = 0
    for j in 0 .. vertexCount - 1:
      if i != j and gcdVal(periods[i], periods[j]) >= level:
        adjacency[i] = adjacency[i] or (1 shl j)
var scanPos = 0
let caseCount = int(nextNum(scanPos))
var outputText = ""
for caseIdx in 0 ..< caseCount:
  vertexCount = int(nextNum(scanPos))
  let removeCount = int(nextNum(scanPos))
  periods = @[]
  periods.setLen vertexCount
  for i in 0 .. vertexCount - 1: periods[i] = nextNum(scanPos)
  var need = vertexCount - removeCount
  removeBits = 0
  if need == 1:
    var keepIndex = 0
    for i in 1 .. vertexCount - 1:
      if periods[i] >= periods[keepIndex]: keepIndex = i
    removeBits = ((1 shl vertexCount) - 1) and not (1 shl keepIndex)
  else:
    var gcdList: seq[int64] = @[]
    for i in 0 .. vertexCount - 1:
      for j in i + 1 .. vertexCount - 1: gcdList.add gcdVal(periods[i], periods[j])
    gcdList.sort(system.cmp[int64])
    var lo = 0
    var hi = gcdList.len - 1
    var bestVal = gcdList[0]
    while lo <= hi:
      let mid = (lo + hi) div 2
      let level = gcdList[mid]
      buildAdjacency(level)
      if cliqueExists(need, (1 shl vertexCount) - 1):
        bestVal = level
        lo = mid + 1
      else:
        hi = mid - 1
```

The greedy scan visits holidays from left to right. It removes a holiday when a clique of `need` holidays still fits. Otherwise it keeps the holiday and narrows `allowed` to its neighbours. Cost: one clique test per holiday.

```nim
    buildAdjacency(bestVal)
    var candidates = (1 shl vertexCount) - 1
    var allowed = candidates
    for i in 0 .. vertexCount - 1:
      if (candidates and (1 shl i)) == 0: continue
      if cliqueExists(need, (candidates and not (1 shl i)) and allowed):
        removeBits = removeBits or (1 shl i)
        candidates = candidates and not (1 shl i)
      else:
        candidates = candidates and not (1 shl i)
        allowed = allowed and adjacency[i]
        need -= 1
```

The final scan visits `vertexCount` holidays. The buffer flushes every `flushBlockBytes` bytes, so large cases do not grow memory. Cost: one string append per removed holiday.

```nim
  var showSpace = false
  for i in 0 .. vertexCount - 1:
    if (removeBits and (1 shl i)) != 0:
      if showSpace: outputText.add ' '
      outputText.add $(i + 1)
      showSpace = true
  outputText.add '\n'
  if outputText.len >= flushBlockBytes:
    stdout.write outputText
    outputText.setLen 0
stdout.write outputText
```

## Complexity

Input parsing reads each byte once. The gcd table costs n^2 pair computations per case. Binary search runs through at most 435 distinct levels. Each level tests a clique on at most 30 vertices with a color bound. The greedy scan adds one clique test per holiday. Space holds the input string, a 30-entry adjacency table, and small arrays.

Total time per case is O(n^2 log D) gcd work plus bounded clique tests, where D is the number of distinct pairwise gcds. Total space is O(n) plus the input buffer.

Simulating days runs up to the least common multiple of the periods, which is astronomical near 10^18. Trying every removal set costs C(n, k) subsets, about 155 million at n = 30.
