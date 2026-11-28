# MMINPER — Minimum Permutation (SPOJ)

<https://www.spoj.com/problems/MMINPER/>

## Problem

Given a size n and an inversion count m, write the smallest permutation of 1 through n whose inversion count equals m. Smaller means the first position where two permutations differ holds the smaller number.

Each input line contains n and m. A line with -1 -1 ends the input. Print one permutation per case, with single spaces between numbers.

| Item | Bound |
|---|---|
| Permutation size n | 1 to 50000 |
| Inversion count m | 0 to n(n-1)/2 |
| Input lines | until -1 -1 |
| Judge limit | 1000 ms, 1536 MB |

The output can hold 50000 numbers, so the write path needs block buffering.

Sample input:

```
5 9
7 3
-1 -1
```

Sample output:

```
4 5 3 2 1
1 2 3 4 7 6 5
```

## Idea

Choosing each position works like spending a budget one coin at a time, always taking the smallest coin that leaves enough for later positions.

A greedy scan fixes the answer. When r numbers remain, putting the k-th smallest remaining number first spends k-1 inversions. The last r-1 numbers can still produce at most (r-1)(r-2)/2 inversions. Pick the smallest k that keeps the remaining budget within that limit. A Fenwick tree finds the k-th unused value in O(log n) steps. Trying all permutations would take factorial time.

## Why It Works

1. The k-th smallest remaining number sits above exactly k-1 smaller unused numbers, so it adds k-1 inversions.
2. The remaining r-1 positions hold at most (r-1)(r-2)/2 inversions.
3. The smallest valid k gives the lexicographically smallest prefix with a feasible budget.
4. Repeating the choice at every position keeps the whole permutation minimal.
5. A Fenwick tree stores one flag per unused value and supports rank lookup after each removal.

| Term | Meaning |
|---|---|
| `tailCapacity` | maximum inversions left after the current position |
| `shiftCount` | inversions spent by the chosen number |
| `fenwickTree` | counts of unused values by position |
| `topBit` | highest power of two used for rank lookup |

The table names every value the greedy step needs.

A script trace for n = 5 and m = 9:

```
remaining 5, capacity 6, shift 3 -> chosen 4, budget 6
remaining 4, capacity 3, shift 3 -> chosen 5, budget 3
remaining 3, capacity 1, shift 2 -> chosen 3, budget 1
remaining 2, capacity 0, shift 1 -> chosen 2, budget 0
remaining 1, capacity 0, shift 0 -> chosen 1
```

The trace prints 4 5 3 2 1, which matches the first sample line.

## Code

**Input and rank helpers.** The scanner reads signed pairs, and the tree selects by rank.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] != '-' and (data[pos] < '0' or data[pos] > '9')):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc selectByRank(tree: seq[int], treeSize: int, topBit: int, rankValue: int): int =
  var position = 0
  var remainingRank = rankValue
  var stepValue = topBit
  while stepValue > 0:
    let candidate = position + stepValue
    if candidate <= treeSize and tree[candidate] < remainingRank:
      position = candidate
      remainingRank -= tree[candidate]
    stepValue = stepValue shr 1
  return position + 1

proc removeValue(tree: var seq[int], treeSize: int, position: int) =
  var cursor = position
  while cursor <= treeSize:
    tree[cursor] -= 1
    cursor = cursor + (cursor and (-cursor))
```

The minus branch reads the -1 -1 terminator.
Rank lookup walks bit by bit in O(log n).
Each removal climbs the tree through low bits.

**Greedy construction.** Each position spends the smallest feasible inversion budget.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let permutationSize = nextInt(inputData, scanPos)
  let inversionInput = nextInt(inputData, scanPos)
  if permutationSize < 0 and inversionInput < 0:
    break
  var inversionTarget = int64(inversionInput)
  var fenwickTree = newSeq[int](permutationSize + 1)
  for indexValue in 1 .. permutationSize:
    fenwickTree[indexValue] = 1
  for indexValue in 1 .. permutationSize:
    let parentIndex = indexValue + (indexValue and (-indexValue))
    if parentIndex <= permutationSize:
      fenwickTree[parentIndex] += fenwickTree[indexValue]
  var topBit = 1
  while (topBit shl 1) <= permutationSize:
    topBit = topBit shl 1
  var remainingCount = permutationSize
  while remainingCount > 0:
    let tailCapacity = int64(remainingCount - 1) * int64(remainingCount - 2) div 2
    var shiftCount = inversionTarget - tailCapacity
    if shiftCount < 0:
      shiftCount = 0
    let chosenValue = selectByRank(fenwickTree, permutationSize, topBit, int(shiftCount) + 1)
    appendOutput($chosenValue)
    if remainingCount > 1:
      appendOutput " "
    inversionTarget -= shiftCount
    removeValue(fenwickTree, permutationSize, chosenValue)
    remainingCount -= 1
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The tree builds in linear time from low-bit sums.
Budget arithmetic uses int64 for n = 50000.
The buffer flushes after roughly 128 KB of output.

## Complexity

Each test case performs one greedy pass over the permutation.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Tree build | n low-bit updates | n counters |
| Greedy scan | n rank lookups and removals | n counters |
| Output | buffered writes | block buffer |

The table shows that rank lookup sets the per-position cost.

| Measure | Big O |
|---|---|
| Time | O(n log n) per case |
| Space | O(n) |

Checking every permutation would take O(n!) time, while the greedy pass takes O(n log n).
