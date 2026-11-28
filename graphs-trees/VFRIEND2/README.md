# VFRIEND2 — Generated Dog Wishes (SPOJ)

<https://www.spoj.com/problems/VFRIEND2/>

## Problem

Decide whether a generated list of friend counts comes from a simple undirected graph. The list is produced by a linear generator, so the input stays small even for huge lists.

Line 1 holds the test count `T`. Each test gives five integers `N a b c m`. The sequence starts at `x0 = 0` and uses `xi+1 = (a*xi + b) mod m`. Wish `wi` equals `xi + c`. Print `HAPPY` or `SAD` on its own line per test.

| item | bound |
|---|---|
| tests T | positive, input bounded |
| dogs N | 0 to 10000000 |
| a, b, c | 0 to 10000000 |
| modulus m | 1 to 10000000 |
| judge limit | 1000 ms, 1536 MB |

A valid list is graphical. Its sum is even and every wish stays below N.

Sample input:

```
3
3 2 1 0 2
5 1 1 0 5
6 1 1 1 3
```

Sample output:

```
HAPPY
SAD
HAPPY
```

Those three lines are the exact expected output.

## Idea

Treat each wish as a handshake request, and handshakes come in pairs. The Erdős–Gallai theorem checks those requests with N simple inequalities after sorting.

The generator produces each wish in one step, and bucket counts sort the values without comparisons. A shrinking pointer then supplies the remaining contribution for each inequality. Generating and counting cost O(N + maxWish), which avoids storing a huge adjacency list.

One sorted sweep settles a test with ten million dogs.

## Why It Works

1. The generator yields `x0` first, then each later value from the recurrence.
2. Every friendship adds two to the wish sum, so an odd sum fails.
3. A dog has at most N-1 friends, so a wish of N or more fails.
4. Bucket counts place wishes from largest to smallest in linear time.
5. For position k, the first k dogs hold at most k(k-1) friendships among themselves.
6. Later dogs add at most min(wi, k) friendships to that group.
7. The Erdős–Gallai theorem makes those bounds exact for every k.

| term | meaning |
|---|---|
| `stateValue` | current generator value, kept in int64 |
| `degreeCounts` | bucket for each generated wish value |
| `sortedWishes` | wishes ordered from largest to smallest |
| `prefixSums` | cumulative sums of the sorted wishes |
| `largeCount` | number of wishes larger than the current position |

The labels above match the identifiers in the code.

The first sample test has N=3 and generates 0 1 1 from x0 = 0.

| position k | first k sum | largeCount | remaining contribution | allowance | result |
|---|---|---|---|---|---|
| 1 | 1 | 0 | 1 | 1 | pass |
| 2 | 2 | 0 | 0 | 2 | pass |
| 3 | 2 | 0 | 0 | 6 | pass |

All three rows pass, so the answer is HAPPY.

## Code

**Input and scanner.** The reader stores all input, then parses the five generator values.

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

**Generation.** The generator emits x0 first and counts every wish into its bucket.

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
  let multiplier = nextInt(inputData, scanPos)
  let increment = nextInt(inputData, scanPos)
  let offsetValue = nextInt(inputData, scanPos)
  let modulus = nextInt(inputData, scanPos)
  var impossible = false
  var wishTotal: int64 = 0
  var maxWish = -1
  var degreeCounts = newSeq[int](0)
  if dogCount > 0:
    degreeCounts = newSeq[int](dogCount)
    var stateValue: int64 = 0
    for dogIndex in 0 .. dogCount - 1:
      let currentWish = int(stateValue) + offsetValue
      if currentWish >= dogCount:
        impossible = true
        break
      degreeCounts[currentWish] += 1
      wishTotal = wishTotal + int64(currentWish)
      if currentWish > maxWish:
        maxWish = currentWish
      stateValue = (int64(multiplier) * stateValue + int64(increment)) mod int64(modulus)
  if not impossible and wishTotal mod 2 != 0:
    impossible = true
```

The product uses int64 before the modulus.
An oversized wish stops generation early.
The odd-sum guard runs after the full sum.

**Inequality sweep.** Buckets produce a sorted list, and a shrinking pointer checks each position.

```nim
  if not impossible and dogCount > 0:
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

Buckets run from the largest wish down to zero.
The pointer only moves down, so the sweep stays linear.
The last line flushes the buffered answers.

## Complexity

Each test generates N wishes, buckets them, then sweeps N positions.

| phase | time | space |
|---|---|---|
| generation | one pass over N wishes | one bucket per wish value |
| counting sort | N plus maxWish buckets | sorted wish array |
| inequality sweep | one pass over N positions | prefix sum array |

The table shows a separate cost for each phase.

| measure | Big O |
|---|---|
| time per test | O(N + maxWish) |
| space per test | O(N + maxWish) |

Building every possible graph would take far longer than this sweep.

Counting buckets keep both time and space linear in the generated list.
