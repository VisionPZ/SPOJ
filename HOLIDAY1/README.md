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

Edge condition: gcdValue(periods[i], periods[j]) >= level. Clique size: need = vertexCount - removeCount. Color bound: need > colorBound[i] rejects a branch.

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
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextNumber(pos: var int): int64 =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9'): pos += 1
  result = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    result = result * 10 + int64(int(inputData[pos]) - firstDigitValue)
    pos += 1
```

Euclid's rule replaces a pair by a smaller pair on each step. The remainder reaches zero in a logarithmic number of steps. Cost: one gcd computation per pair of holidays.

```nim
proc gcdValue(a, b: int64): int64 =
  var x = a
  var y = b
  while y != 0:
    let r = x mod y
    x = y
    y = r
  x
```

The color sort visits each candidate once per color class. Each class holds mutually non-adjacent holidays, so `colorBound[i]` limits the clique inside the remaining pool. Cost: bounded by the number of color classes, not by all subsets.

```nim
var vertexCount = 0
var adjacency: array[30, int]
var removedMask = 0
var colorOrder: array[30, int]
var colorBound: array[30, int]

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
        colorOrder[count] = v
        colorBound[count] = colorNum
        count += 1
  count
proc cliqueExists(need: int, candidates: int): bool =
  if need == 0: return true
  if candidates == 0: return false
  let count = colorSort(candidates)
  var pool = candidates
  for i in countdown(count - 1, 0):
    if need > colorBound[i]: return false
    let v = colorOrder[i]
    if cliqueExists(need - 1, pool and adjacency[v]): return true
    pool = pool xor (1 shl v)
  false
```

The binary search ends after a logarithmic number of levels. The `adjacency` table is rebuilt per level because edges depend on `level`. Cost: one gcd per pair at each level.

```nim
var scanPos = 0
let caseCount = int(nextNumber(scanPos))
var outputBuffer = ""
for caseIdx in 0 ..< caseCount:
  vertexCount = int(nextNumber(scanPos))
  let removeCount = int(nextNumber(scanPos))
  var periods: seq[int64] = @[]
  periods.setLen vertexCount
  for i in 0 .. vertexCount - 1: periods[i] = nextNumber(scanPos)
  let need = vertexCount - removeCount
  removedMask = 0
  if need == 1:
    var keepIndex = 0
    for i in 1 .. vertexCount - 1:
      if periods[i] >= periods[keepIndex]: keepIndex = i
    removedMask = ((1 shl vertexCount) - 1) and not (1 shl keepIndex)
  else:
    var pairGcds: seq[int64] = @[]
    for i in 0 .. vertexCount - 1:
      for j in i + 1 .. vertexCount - 1: pairGcds.add gcdValue(periods[i], periods[j])
    pairGcds.sort(system.cmp[int64])
    var lo = 0
    var hi = pairGcds.len - 1
    var bestLevel = pairGcds[0]
    while lo <= hi:
      let mid = (lo + hi) div 2
      let level = pairGcds[mid]
      for i in 0 .. vertexCount - 1:
        adjacency[i] = 0
        for j in 0 .. vertexCount - 1:
          if i != j and gcdValue(periods[i], periods[j]) >= level:
            adjacency[i] = adjacency[i] or (1 shl j)
      if cliqueExists(need, (1 shl vertexCount) - 1):
        bestLevel = level
        lo = mid + 1
      else:
        hi = mid - 1
```

The greedy scan visits holidays from left to right. It removes a holiday when a clique of `need` holidays still fits. Otherwise it keeps the holiday and narrows `allowed` to its neighbours. Cost: one clique test per holiday.

```nim
    for i in 0 .. vertexCount - 1:
      adjacency[i] = 0
      for j in 0 .. vertexCount - 1:
        if i != j and gcdValue(periods[i], periods[j]) >= bestLevel:
          adjacency[i] = adjacency[i] or (1 shl j)
    var candidates = (1 shl vertexCount) - 1
    var allowed = candidates
    var needed = need
    for i in 0 .. vertexCount - 1:
      if (candidates and (1 shl i)) == 0: continue
      if cliqueExists(needed, (candidates and not (1 shl i)) and allowed):
        removedMask = removedMask or (1 shl i)
        candidates = candidates and not (1 shl i)
      else:
        candidates = candidates and not (1 shl i)
        allowed = allowed and adjacency[i]
        needed -= 1
```

The final scan visits `vertexCount` holidays. The buffer flushes every `flushBlockBytes` bytes, so large cases do not grow memory. Cost: one string append per removed holiday.

```nim
  var showSpace = false
  for i in 0 .. vertexCount - 1:
    if (removedMask and (1 shl i)) != 0:
      if showSpace: outputBuffer.add ' '
      outputBuffer.add $(i + 1)
      showSpace = true
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

## Complexity

Input parsing reads each byte once. The gcd table costs n^2 pair computations per case. Binary search runs through at most 435 distinct levels. Each level tests a clique on at most 30 vertices with a color bound. The greedy scan adds one clique test per holiday. Space holds the input string, a 30-entry adjacency table, and small arrays.

Total time per case is O(n^2 log D) gcd work plus bounded clique tests, where D is the number of distinct pairwise gcds. Total space is O(n) plus the input buffer.

Simulating days runs up to the least common multiple of the periods, which is astronomical near 10^18. Trying every removal set costs C(n, k) subsets, about 155 million at n = 30.
