# VFRIENDS — Dog Friend Lists (SPOJ)

<https://www.spoj.com/problems/VFRIENDS/>

## Problem

Decide whether a list of friend counts can come from a simple undirected graph. Each dog names its exact number of friends, and friendship is symmetric with no self-loops.

Line 1 holds the test count `T`. Each next test starts with `N`, followed by `N` wishes `wi`. Print `HAPPY` or `SAD` on its own line for each test.

| item | bound |
|---|---|
| tests T | positive, input bounded |
| dogs N | 0 to 100000 |
| wish wi | 0 to 100000 |
| judge limit | 1000 ms, 1536 MB |

A valid list is called graphical. The sum of wishes must be even, and no wish can reach N.

Sample input:

```
3
3 0 1 1
5 0 1 2 3 4
6 1 1 2 2 3 3
```

Sample output:

```
HAPPY
SAD
HAPPY
```

Those three lines are the exact expected output.

## Idea

Treat the wishes like a seating chart: a table of N seats must give every guest the exact number of neighbors they request. The Erdős–Gallai theorem turns that chart into N cheap inequality checks.

The algorithm sorts wishes by descending value with a counting pass, builds prefix sums, and applies each inequality in one step. Sorting costs O(N + maxWish) here; a pairwise graph search would try far more combinations. The even-sum and max-wish guards reject obvious failures before the sweep.

One sorted sweep decides every test.

## Why It Works

1. Each friendship adds two to the sum of wishes, so the total must be even.
2. A dog can have at most N-1 friends, so any wish of N or more fails.
3. Sorting descending puts the largest wishes first, which matches the theorem.
4. For position k, the first k dogs can hold at most k(k-1) friendships among themselves.
5. The remaining dogs contribute at most min(wi, k) friendships to that group.
6. The theorem says the sequence is graphical exactly when every position passes.

| term | meaning |
|---|---|
| `wishTotal` | sum of all wishes, kept in int64 |
| `sortedWishes` | wishes ordered from largest to smallest |
| `prefixSums` | cumulative sums of the sorted wishes |
| `largeCount` | number of wishes larger than the current position |
| `allowance` | right side of the current inequality |

The labels above match the identifiers in the code.

For the second sample case the sorted wishes are 4 3 2 1 0 and the total is 10.

| position k | first k sum | largeCount | remaining contribution | allowance | result |
|---|---|---|---|---|---|
| 1 | 4 | 3 | 3 | 3 | fail |

The first row already fails, so the answer is SAD.

## Code

**Input and scanner.** The reader loads all input, then parses each test word by word.

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
```

One newline ends each stored line.
The scanner skips spaces and line breaks.
It builds each number one digit at a time.

**Counting sort.** Wish values are small, so bucket counts replace a comparison sort.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let dogCount = nextInt(inputData, scanPos)
  var wishes = newSeq[int](dogCount)
  var wishTotal: int64 = 0
  var maxWish = -1
  for dogIndex in 0 .. dogCount - 1:
    let currentWish = nextInt(inputData, scanPos)
    wishes[dogIndex] = currentWish
    wishTotal = wishTotal + int64(currentWish)
    if currentWish > maxWish:
      maxWish = currentWish
  var impossible = false
  if wishTotal mod 2 != 0:
    impossible = true
  if maxWish >= dogCount:
    impossible = true
  var degreeCounts = newSeq[int](maxWish + 1)
  for dogIndex in 0 .. dogCount - 1:
    degreeCounts[wishes[dogIndex]] += 1
  var sortedWishes = newSeq[int](dogCount)
  var writeIndex = 0
  var degreeValue = maxWish
  while degreeValue >= 0:
    var repeatCount = degreeCounts[degreeValue]
    while repeatCount > 0:
      sortedWishes[writeIndex] = degreeValue
      writeIndex += 1
      repeatCount -= 1
    degreeValue -= 1
```

The guards reject an odd sum or an oversized wish.
Buckets run from the largest wish down to zero.
Prefix sums are added next.

**Inequality sweep.** A shrinking pointer supplies the contribution of each remaining dog.

```nim
  var prefixSums = newSeq[int64](dogCount + 1)
  for dogIndex in 0 .. dogCount - 1:
    prefixSums[dogIndex + 1] = prefixSums[dogIndex] + int64(sortedWishes[dogIndex])
  var largeCount = dogCount
  for position in 1 .. dogCount:
    while largeCount > 0 and sortedWishes[largeCount - 1] <= position:
      largeCount -= 1
    let leftSum = prefixSums[position]
    var rightSum: int64 = 0
    if largeCount <= position:
      rightSum = wishTotal - prefixSums[position]
    else:
      rightSum = (wishTotal - prefixSums[largeCount]) + int64(position) * int64(largeCount - position)
    let allowance = int64(position) * int64(position - 1) + rightSum
    if leftSum > allowance:
      impossible = true
  if impossible:
    appendOutput("SAD\n")
  else:
    appendOutput("HAPPY\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The pointer only moves down, so the sweep stays linear.
Each comparison uses int64 to avoid overflow.
The last line flushes the buffered answers.

## Complexity

Each test reads N wishes, counts buckets, then sweeps N positions.

| phase | time | space |
|---|---|---|
| input scan | one pass over N wishes | one input string |
| counting sort | N plus maxWish buckets | sorted wish array |
| inequality sweep | one pass over N positions | prefix sum array |

The table shows a separate cost for each phase.

| measure | Big O |
|---|---|
| time per test | O(N + maxWish) |
| space per test | O(N + maxWish) |

Checking every possible graph would take far longer than this sweep.

Counting buckets keep both time and space linear in the input size.
