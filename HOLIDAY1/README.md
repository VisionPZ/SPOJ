# HOLIDAY1 — Getting Rid of the Holidays (Act I) (SPOJ)

<https://www.spoj.com/problems/HOLIDAY1/>

## Problem

A company throws a party whenever a holiday returns. Remove some holidays, and the remaining parties spread apart.

Read `t` cases. Each case gives `n`, the count `k` to remove, and `n` periods. Holiday `i` starts on day zero and returns every period `i` days.

Print the removed holiday numbers in increasing order, one line per case.

The bounds set the size of the search:

| Quantity | Bound |
| --- | --- |
| Test cases `t` | up to 200 |
| Holidays `n` | `k < n <= 30` |
| Period `t_i` | up to 10^18 |
| Time limit | 6006 ms |
| Memory limit | 1536 MB |

The holiday count stays small, but the periods rule out day-by-day simulation.

The sample case:

```
1
5 2
6 13 10 15 7
```

```
2 5
```

## Idea

Picture metronomes ticking from the same starting beat. The closest pair of periods sets the shortest gap between parties.

Every party day is a multiple of a kept period. The difference of two multiples is a multiple of the gcd (greatest common divisor) of their periods. The shortest gap therefore equals the smallest pairwise gcd among the kept holidays.

Treat each gcd as a graph threshold. An edge joins two holidays when their gcd reaches that level. Binary search over sorted pairwise gcds finds the largest level with a clique (a set where every pair connects) of the needed size.

Each level costs one gcd per pair and one bounded clique test.

Simulating days runs to the least common multiple of the periods. At periods near 10^18, that count is astronomical. A gcd threshold plus a clique check replaces the impossible calendar.

## Why It Works

Four facts prove the method exact.

1. All kept holidays occur on day zero, so each party day is a multiple of a kept period.
2. The difference of two multiples is a multiple of the gcd of the two periods. The smallest positive difference over all pairs is the smallest pairwise gcd.
3. A level `g` keeps pairs with gcd at least `g`. A set whose every pair reaches `g` has a shortest gap of at least `g`.
4. A greedy color sort splits candidates into groups of mutually non-adjacent holidays. A clique takes at most one holiday from each group, so the group count bounds every search branch.

The main values and their roles:

| Term | Meaning |
| --- | --- |
| `gcdVal` | Euclid rule returning the gcd of two periods |
| `adjacency` | bit mask of holidays connected to a given holiday |
| `colorCap` | group index limiting a holiday's place in a clique |
| `need` | number of holidays the clique must still hold |
| `bestVal` | largest gcd level with a feasible clique |
| `removeBits` | bit mask of holidays chosen for removal |

These masks keep every clique test inside a 30-bit word.

A script traces the sample case and prints these values:

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

Level 2 is the highest level with a clique of three. The program keeps holidays 1, 3, and 4, and removes 2 and 5.

## Code

**Input and scanner.** One read loop loads the stream, and a hand scanner skips separators.

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

The read loop runs once per input line and stops at end of stream. The scanner skips non-digits, so blank lines cause no trouble. The `int64` result holds periods up to 10^18.

Parsing costs one pass over the buffer.

**GCD.** Euclid's rule replaces a pair with a smaller pair at each step.

```nim
proc gcdVal(left, right: int64): int64 =
  var first = left
  var second = right
  while second != 0:
    let rem = first mod second
    first = second
    second = rem
  first
```

The loop ends when the remainder reaches zero. It takes a logarithmic number of steps. The program computes one gcd for each holiday pair and for each search level.

**Clique search.** `colorSort` groups non-adjacent holidays, and `cliqueExists` builds a clique inside the remaining pool.

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
      var node = 0
      var shifted = lowBit
      while shifted > 1:
        shifted = shifted shr 1
        node += 1
      rest = rest xor lowBit
      if (classMask and adjacency[node]) == 0:
        classMask = classMask or lowBit
        uncolored = uncolored xor lowBit
        orderList[count] = node
        colorCap[count] = colorNum
        count += 1
  count
proc cliqueExists(need: int, candidates: int): bool =
  if need == 0: return true
  if candidates == 0: return false
  let count = colorSort(candidates)
  var pool = candidates
  for idx in countdown(count - 1, 0):
    if need > colorCap[idx]: return false
    let node = orderList[idx]
    if cliqueExists(need - 1, pool and adjacency[node]): return true
    pool = pool xor (1 shl node)
  false
```

Each color class holds mutually non-adjacent holidays. The `colorCap` test rejects a branch before it explores the whole class. The recursion visits at most `2^30` masks in theory, but the color bound prunes it sharply.

**Adjacency.** One helper rebuilds the edge mask for a gcd level.

```nim
proc buildAdjacency(level: int64) =
  for row in 0 ..< vertexCount:
    adjacency[row] = 0
    for col in 0 ..< vertexCount:
      if row != col and gcdVal(periods[row], periods[col]) >= level:
        adjacency[row] = adjacency[row] or (1 shl col)
```

The double loop visits every ordered pair once. The `row != col` guard keeps a holiday away from its own mask. The block costs one gcd per ordered pair.

**Binary search.** Sorted pairwise gcds give a small set of levels to test.

```nim
var scanPos = 0
let caseCount = int(nextNum(scanPos))
var outputBuffer = ""
for caseIdx in 0 ..< caseCount:
  vertexCount = int(nextNum(scanPos))
  let removeCount = int(nextNum(scanPos))
  periods = @[]
  periods.setLen vertexCount
  for i in 0 ..< vertexCount: periods[i] = nextNum(scanPos)
  var need = vertexCount - removeCount
  removeBits = 0
  if need == 1:
    var keepIndex = 0
    for idx in 1 ..< vertexCount:
      if periods[idx] >= periods[keepIndex]: keepIndex = idx
    removeBits = ((1 shl vertexCount) - 1) and not (1 shl keepIndex)
  else:
    var gcdList: seq[int64] = @[]
    for row in 0 ..< vertexCount:
      for col in row + 1 ..< vertexCount: gcdList.add gcdVal(periods[row], periods[col])
    gcdList.sort(system.cmp[int64])
    var lowIdx = 0
    var highIdx = gcdList.len - 1
    var bestVal = gcdList[0]
    while lowIdx <= highIdx:
      let midIdx = (lowIdx + highIdx) div 2
      let level = gcdList[midIdx]
      buildAdjacency(level)
      if cliqueExists(need, (1 shl vertexCount) - 1):
        bestVal = level
        lowIdx = midIdx + 1
      else:
        highIdx = midIdx - 1
```

The `need == 1` branch keeps the largest period without a clique test. The gcd list holds at most 435 values. The search ends after a logarithmic number of levels.

**Greedy removal.** A left-to-right scan chooses the holidays to drop.

```nim
    buildAdjacency(bestVal)
    var candidates = (1 shl vertexCount) - 1
    var allowed = candidates
    for node in 0 ..< vertexCount:
      if (candidates and (1 shl node)) == 0: continue
      if cliqueExists(need, (candidates and not (1 shl node)) and allowed):
        removeBits = removeBits or (1 shl node)
        candidates = candidates and not (1 shl node)
      else:
        candidates = candidates and not (1 shl node)
        allowed = allowed and adjacency[node]
        need -= 1
```

Removing a holiday succeeds when a clique of `need` holidays still fits. Otherwise the scan keeps it and narrows `allowed` to its neighbours. The block runs one clique test per holiday.

**Output.** The final scan writes removed numbers in increasing order.

```nim
  var showSpace = false
  for node in 0 ..< vertexCount:
    if (removeBits and (1 shl node)) != 0:
      if showSpace: outputBuffer.add ' '
      outputBuffer.add $(node + 1)
      showSpace = true
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The loop visits holidays from left to right, so the output stays sorted. The buffer flushes every 256 KiB and caps memory. One line costs one string append per removed holiday.

## Complexity

The gcd table dominates the work, while every clique test stays inside one word.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Pairwise gcd list | O(n^2) per case | O(n^2) gcd values |
| Binary search levels | O(log D) clique tests | O(n) masks |
| Greedy removal | O(n) clique tests | O(n) masks |

Here `D` is the count of distinct pairwise gcds, at most 435.

| Measure | Big O |
| --- | --- |
| Time | O(n^2 log D) gcd work plus bounded clique tests |
| Space | O(n) per case plus input and output buffers |

Simulating days runs to the least common multiple of the periods, which explodes near 10^18.
