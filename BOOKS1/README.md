# BOOKS1 — Copying Books (SPOJ)
<https://www.spoj.com/problems/BOOKS1/>

## Problem

Before printing, scribes copied books by hand. Split m books among k scribes so each gets a continuous block, and make the busiest scribe's work as small as possible. Print the page counts with slashes at the split points.

Input starts with a case count. Each case gives m and k, then m page counts on one line. Output one line per case, with spaces between books and ` / ` between scribes' blocks.

The statement and judge table give these bounds:

| Item | Bound |
| --- | --- |
| Cases | about 200 |
| Books and scribes | 1 ≤ k ≤ m ≤ 500 |
| Pages per book | positive, below 10,000,000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

Page totals reach 5 times 10^9, so the search uses 64-bit integers.

The sample input and output:

```
2
9 3
100 200 300 400 500 600 700 800 900
5 4
100 100 100 100 100
```

```
100 200 300 400 500 / 600 700 / 800 900
100 / 100 / 100 / 100 100
```

The first case needs a maximum load of 1700 pages.

## Idea

Binary search the largest block sum, called the load. For a trial load, pack books greedily from left to right and count the scribes used. If that count fits the budget, try a smaller load; otherwise raise it. Think of judging a row of boxes by one weight limit, then lowering the limit until the boxes no longer fit.

Once the optimal load is known, place the slashes from right to left so early scribes carry the least work they can.

The search costs O(m log totalPages) per case, plus one O(m) pass to place the slashes. Enumerating all split points would choose k - 1 cuts among m - 1 gaps, which is exponential.

Takeaway: search the answer, then greedily lay out the cuts.

## Why It Works

1. Feasibility is monotone: if a load works, every larger load also works.
2. The greedy pack uses the fewest scribes for a fixed load, so its count gives the correct test.
3. The search starts between the heaviest book and the total pages, which bracket the answer.
4. The right-to-left pass fills the last scribe first, so earlier scribes take the smallest possible prefix.
5. `partFirstBook` records the first book of each scribe, which the output pass uses to place slashes.

These terms drive the search.

| Term | Meaning |
| --- | --- |
| `loadLow = heaviestBook` | no block can hold less than the largest book |
| `loadHigh = totalPages` | one scriber can hold every book |
| `scribesUsed <= scribeCount` | the trial load is feasible, so search lower |
| `optimalLoad` | the smallest feasible load found |

Each guess halves the remaining range.

A script traced the first sample case, with nine books and three scribes:

| Guess | Feasible? | Branch |
| --- | --- | --- |
| 2700 | yes | lower the high bound |
| 1350 | no | raise the low bound |
| 1700 | yes | lower the high bound |
| 1699 | no | raise the low bound |

The bounds meet at 1700, matching the printed first line.

## Code

**Input and scanner.**
```nim
const flushBlockBytes = 1 shl 17

var inputData: string
var lineReadBuffer: string
while readLine(stdin, lineReadBuffer):
  inputData.add lineReadBuffer
  inputData.add '\n'

var i = 0

proc nextInt(): int64 =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i = i + 1
  var scannedValue: int64 = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    scannedValue = scannedValue * 10 + int64(int(inputData[i]) - 48)
    i = i + 1
  return scannedValue

var caseCount = int(nextInt())
```
The line loop gathers all input, and `nextInt` returns an int64. `caseCount` drives the outer loop. `flushBlockBytes` caps each output block.

**Load search.**
```nim
for _ in 1 .. caseCount:
  var bookCount = int(nextInt())
  var scribeCount = int(nextInt())
  var bookPages = newSeq[int64](bookCount)
  var heaviestBook: int64 = 0
  var totalPages: int64 = 0
  for j in 0 .. bookCount - 1:
    bookPages[j] = nextInt()
    if bookPages[j] > heaviestBook: heaviestBook = bookPages[j]
    totalPages = totalPages + bookPages[j]
  var loadLow = heaviestBook
  var loadHigh = totalPages
  while loadLow < loadHigh:
    var loadGuess = (loadLow + loadHigh) div 2
    var scribesUsed = 1
    var runningSum: int64 = 0
    for j in 0 .. bookCount - 1:
      if runningSum + bookPages[j] > loadGuess:
        scribesUsed = scribesUsed + 1
        runningSum = bookPages[j]
      else:
        runningSum = runningSum + bookPages[j]
    if scribesUsed <= scribeCount:
      loadHigh = loadGuess
    else:
      loadLow = loadGuess + 1
  var optimalLoad = loadLow
```
The loop halves the range between `loadLow` and `loadHigh`. `scribesUsed` counts blocks for a guess. `optimalLoad` holds the smallest feasible value.

**Slash placement and output.**
```nim
  var partFirstBook = newSeq[int](scribeCount)
  var booksRemaining = bookCount
  for j in countdown(scribeCount - 1, 0):
    var takenCount = 1
    var takenSum = bookPages[booksRemaining - 1]
    while booksRemaining - takenCount > j and
        takenSum + bookPages[booksRemaining - takenCount - 1] <= optimalLoad:
      takenSum = takenSum + bookPages[booksRemaining - takenCount - 1]
      takenCount = takenCount + 1
    partFirstBook[j] = booksRemaining - takenCount
    booksRemaining = partFirstBook[j]
  var currentPart = 0
  for j in 0 .. bookCount - 1:
    if j > 0:
      if currentPart + 1 < scribeCount and j == partFirstBook[currentPart + 1]:
        outputBuffer.add " / "
        currentPart = currentPart + 1
      else:
        outputBuffer.add ' '
    outputBuffer.add $bookPages[j]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```
A right-to-left pass fills `partFirstBook` for each scribe. The output pass inserts ` / ` when `j` reaches the next scribe's first book. The final write flushes the buffer tail.

## Complexity

Book count sets the work per case.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Load search | O(m log totalPages) | O(m) |
| Slash placement | O(m) | k integers |
| Output | one write per block | flushBlockBytes |
| Total per case | O(m log totalPages) | O(m) |

Logarithmic search keeps the page tests few.

| Measure | Big O |
| --- | --- |
| Time per case | O(m log totalPages) |
| Space per case | O(m) |

Trying every split set would be exponential, while binary search settles the same assignment in a few dozen passes.
