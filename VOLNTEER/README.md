# VOLNTEER — Annual Day (SPOJ)
<https://www.spoj.com/problems/VOLNTEER/>

## Problem

Choose exactly k students to maximize a group score. The score is the sum of absolute goodness values, negated when the group has an odd number of students with negative scores.

Input starts with N and k. One line follows with N goodness scores, each between -1000000000 and 1000000000.

Output is one line with the largest possible group score.

The input bounds are:

| item | bound |
|---|---|
| students N | 1 to 100000 |
| chosen k | 1 to N |
| score magnitude | up to 1000000000 |
| judge limit | 2000 ms, 1536 MB |

A negative score counts as naughty. Zero counts as ordinary.

Sample input:

```
10 1
1 2 3 4 5 6 7 8 -9 9
```

Sample output:

```
9
```

## Idea

Pick magnitudes from two piles, largest first when the naughty count is even and smallest first when it is odd, like choosing balls to keep a tally positive or negative.

The algorithm sorts positive and negative magnitudes separately, builds prefix sums, and tries every feasible naughty count. Sorting costs O(N log N) and the sweep costs O(k).

Checking all subsets would cost exponential time. A fixed naughty count has a clear best choice, so only k counts need checking.

## Why It Works

1. The sign of a group score depends only on the parity of the naughty count r.
2. With even r, the score is a sum of magnitudes, so larger magnitudes win.
3. With odd r, the score is the negation of that sum, so smaller magnitudes win.
4. For a fixed r, taking the r largest negative magnitudes and the k-r best positive magnitudes is optimal.
5. The odd case takes the r smallest negative magnitudes and the k-r smallest positive magnitudes.
6. Scanning every feasible r covers all legal groups and keeps the maximum.

The main terms are:

| term | meaning |
|---|---|
| `positiveAbs` | magnitudes of ordinary students |
| `negativeAbs` | magnitudes of naughty students |
| `positivePrefix` | prefix sums of sorted ordinary magnitudes |
| `negativePrefix` | prefix sums of sorted naughty magnitudes |
| `negativeChosen` | number of naughty students in the current group |

A short script over the second sample gives these candidates:

| naughty count | chosen magnitudes | parity | score |
|---|---|---|---|
| 0 | 9, 7, 6 | even | 22 |
| 1 | 1, 2, 8 | odd | -11 |
| 2 | 9, 7, 8 | even | 26 |

The largest candidate is 26, which matches the second sample.
Sums use int64 because k magnitudes can reach 10^14.

## Code

**Input and scanning.** Negative signs are kept while the two piles are filled.

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
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts a leading minus sign.
Negative scores go into the naughty pile.
Zero scores go into the ordinary pile.

**Sorting and prefixes.** Each pile is sorted from largest magnitude down.

```nim
let studentCount = nextInt(inputData, scanPos)
let chosenCount = nextInt(inputData, scanPos)
var positiveAbs = newSeq[int]()
var negativeAbs = newSeq[int]()
for studentIndex in 0 .. studentCount - 1:
  let score = nextInt(inputData, scanPos)
  if score < 0:
    negativeAbs.add(-score)
  else:
    positiveAbs.add(score)

proc descending(left, right: int): int =
  return right - left

positiveAbs.sort(descending)
negativeAbs.sort(descending)

var positivePrefix = newSeq[int64](positiveAbs.len + 1)
for index in 0 .. positiveAbs.len - 1:
  positivePrefix[index + 1] = positivePrefix[index] + int64(positiveAbs[index])
var negativePrefix = newSeq[int64](negativeAbs.len + 1)
for index in 0 .. negativeAbs.len - 1:
  negativePrefix[index + 1] = negativePrefix[index] + int64(negativeAbs[index])
```

Prefix entries give both ends of each sorted pile.
The last entry minus an earlier entry gives a smallest-magnitude sum.
Both piles share one comparison procedure.

**Feasibility sweep.** Every naughty count yields one candidate score.

```nim
var bestScore: int64 = -9000000000000000000
var negativeChosen = 0
let highestNegative = if negativeAbs.len < chosenCount: negativeAbs.len else: chosenCount
while negativeChosen <= highestNegative:
  let positiveChosen = chosenCount - negativeChosen
  if positiveChosen <= positiveAbs.len:
    var totalAbs: int64 = 0
    if negativeChosen mod 2 == 0:
      totalAbs = positivePrefix[positiveChosen] + negativePrefix[negativeChosen]
    else:
      let smallestPositives = positivePrefix[positiveAbs.len] - positivePrefix[positiveAbs.len - positiveChosen]
      let smallestNegatives = negativePrefix[negativeAbs.len] - negativePrefix[negativeAbs.len - negativeChosen]
      totalAbs = smallestPositives + smallestNegatives
    let signedScore = if negativeChosen mod 2 == 0: totalAbs else: -totalAbs
    if signedScore > bestScore:
      bestScore = signedScore
  negativeChosen += 1
```

Even counts use the largest magnitudes.
Odd counts use the smallest magnitudes.
Infeasible counts are skipped before scoring.

**Final write.** The best score is emitted once.

```nim
appendOutput($bestScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The answer is a signed decimal string.
The buffered write happens once.
No output is produced during the sweep.

## Complexity

Sorting dominates the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over N scores | one input string |
| sorting | two sorts over the piles | two magnitude arrays |
| prefix build | one pass over N values | two prefix arrays |
| count sweep | up to k candidates | constant extra space |
| output | one line | block buffer |

The sweep stays linear in k after sorting.

| measure | Big O |
|---|---|
| time | O(N log N + k) |
| space | O(N) |

Trying every subset would take exponential time.
Two sorted piles and one sweep settle every parity case, and that ends the work.
