# CANDY2 — Candy II (SPOJ)

<https://www.spoj.com/problems/CANDY2/>

## Problem

Pick one bag for each candy flavor so the fewest candies move. Moving one candy into its flavor bag costs one second. Candies already in the correct bag cost nothing.

Input starts with N, the bag count. The next N lines give chocolate, strawberry and banana counts for each bag. Bags are numbered from 0 to N-1. Output three lines: the chocolate bag, the strawberry bag and the banana bag. Any optimal choice is accepted; ties use the smallest bag numbers here.

| item | bound |
|---|---|
| bags N | up to 5000 |
| candies per bag | non-negative integers |
| moves | one second per candy |
| judge limit | 1000 ms, 1536 MB |

Three distinct bags are chosen, one per flavor.

Sample input:

```
5
10 10 10
40 39 40
10 20 30
30 20 10
1 2 27
```

Sample output:

```
3
1
2
```

## Idea

The total moves equal all candies minus the candies already sitting in their chosen bags, like keeping the fullest three shelves. So minimizing moves means maximizing the sum of three entries taken from different rows and different columns. Each bag only needs to be checked as a candidate for a flavor when it ranks near the top for that flavor. The algorithm keeps the top three candidates per flavor and tests 27 triples. A full search over all bag triples would cost O(N^3). Takeaway: pick the best few candidates per column, then combine them.

## Why It Works

1. Let the totals be C, S and B for the three flavors over all bags.
2. If bag i holds chocolate, then C minus its chocolate count moves must be carried into it.
3. The full move count is C + S + B minus the three retained counts.
4. Therefore the minimum moves come from the maximum retained sum.
5. For one flavor, the chosen bag ranks in the top three: at most two other bags are unavailable, so a better bag would replace it.

| term | meaning |
|---|---|
| `chocolateCounts` | chocolate candies in each bag |
| `strawberryCounts` | strawberry candies in each bag |
| `bananaCounts` | banana candies in each bag |
| `bestSum` | largest retained sum found |
| `keptCandies` | retained sum of one triple |

The table defines the values used by the candidate scan.

In the sample the totals are 91, 91 and 117. The triple (3, 1, 2) retains 30 + 39 + 30, which is 99. The moves are 299 minus 99, which is 200.

The sample answer leaves exactly 200 candies to move.

## Code

**Input and scanning.** The hand reader loads the bag counts into three arrays.

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

let bagCount = nextInt(inputData, scanPos)
var chocolateCounts = newSeq[int64](bagCount)
var strawberryCounts = newSeq[int64](bagCount)
var bananaCounts = newSeq[int64](bagCount)
for bagIndex in 0 .. bagCount - 1:
  chocolateCounts[bagIndex] = int64(nextInt(inputData, scanPos))
  strawberryCounts[bagIndex] = int64(nextInt(inputData, scanPos))
  bananaCounts[bagIndex] = int64(nextInt(inputData, scanPos))
```

Each bag contributes three counts.
Values use int64 because totals can exceed 32 bits.
Parsing ignores spaces and line breaks.

**Candidate selection.** Each flavor keeps its three best bags.

```nim
proc insertCandidate(candidates: var seq[int], bagIndex: int, counts: seq[int64]) =
  var slot = 0
  while slot < candidates.len:
    let otherBag = candidates[slot]
    if otherBag == -1:
      break
    if counts[bagIndex] > counts[otherBag]:
      break
    if counts[bagIndex] == counts[otherBag] and bagIndex < otherBag:
      break
    slot += 1
  if slot == candidates.len:
    return
  var moveIndex = candidates.len - 1
  while moveIndex > slot:
    candidates[moveIndex] = candidates[moveIndex - 1]
    moveIndex -= 1
  candidates[slot] = bagIndex

var chocolateTop = newSeq[int](3)
var strawberryTop = newSeq[int](3)
var bananaTop = newSeq[int](3)
for candidateIndex in 0 .. 2:
  chocolateTop[candidateIndex] = -1
  strawberryTop[candidateIndex] = -1
  bananaTop[candidateIndex] = -1
for bagIndex in 0 .. bagCount - 1:
  insertCandidate(chocolateTop, bagIndex, chocolateCounts)
  insertCandidate(strawberryTop, bagIndex, strawberryCounts)
  insertCandidate(bananaTop, bagIndex, bananaCounts)

proc sortCandidates(candidates: var seq[int]) =
  for rightIndex in 1 .. candidates.len - 1:
    let carriedBag = candidates[rightIndex]
    if carriedBag == -1:
      continue
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and (candidates[leftIndex] == -1 or candidates[leftIndex] > carriedBag):
      candidates[leftIndex + 1] = candidates[leftIndex]
      leftIndex -= 1
    candidates[leftIndex + 1] = carriedBag

sortCandidates(chocolateTop)
sortCandidates(strawberryTop)
sortCandidates(bananaTop)
```

Empty slots hold -1 so early bags are inserted.
Ties prefer the smaller bag index.
Each insertion costs at most three comparisons.

**Triple scan.** Twenty-seven triples are checked for distinct bags.

```nim
var bestSum: int64 = -1
var bestChocolateBag = -1
var bestStrawberryBag = -1
var bestBananaBag = -1
for chocolateSlot in 0 .. 2:
  let chocolateBag = chocolateTop[chocolateSlot]
  if chocolateBag < 0:
    continue
  for strawberrySlot in 0 .. 2:
    let strawberryBag = strawberryTop[strawberrySlot]
    if strawberryBag < 0 or strawberryBag == chocolateBag:
      continue
    for bananaSlot in 0 .. 2:
      let bananaBag = bananaTop[bananaSlot]
      if bananaBag < 0 or bananaBag == chocolateBag or bananaBag == strawberryBag:
        continue
      let keptCandies = chocolateCounts[chocolateBag] + strawberryCounts[strawberryBag] + bananaCounts[bananaBag]
      if keptCandies > bestSum:
        bestSum = keptCandies
        bestChocolateBag = chocolateBag
        bestStrawberryBag = strawberryBag
        bestBananaBag = bananaBag

appendOutput($bestChocolateBag)
outputBuffer.add '\n'
appendOutput($bestStrawberryBag)
outputBuffer.add '\n'
appendOutput($bestBananaBag)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Repeated bag indices are skipped.
The first maximum wins, which gives the smallest triple in candidate order.
Three lines are written through the block buffer.

## Complexity

Candidate collection is linear in the bag count.

| phase | time | space |
|---|---|---|
| input read | one pass over N triples | three arrays of N integers |
| candidate selection | three insertions per bag | three slots per flavor |
| triple scan | 27 constant checks | three chosen indices |

All phases share the same three input arrays.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

Checking every bag triple would cost O(N^3) time. The top-three rule reduces the scan to a constant number of cases.
