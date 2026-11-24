## Problem

Read several cases. Each case gives book page counts and a number of scribes. Print the page counts split into that many continuous groups, with a slash between groups.

The statement and judge table give these bounds.

| item | bound |
|---|---|
| cases | about 200 |
| books and scribes | 1 <= k <= m <= 500 |
| pages per book | positive, less than 10 000 000 |
| judge limit | 5000 ms, 1536 MB |

Page totals reach 5 * 10^9, so the search uses 64-bit integers.

## Idea

Binary search the largest group sum, called the load. For a trial load, pack books greedily from left to right and count the scribes used. If that count fits the budget, try a smaller load, otherwise raise it.

Cost per case: O(m log totalPages) page tests, plus one O(m) pass to place the slashes.

## Why It Works

Feasibility is monotone. If a load works, every larger load also works.

The greedy pack uses the fewest scribes for a fixed load, so its count gives the correct test. The search starts between the heaviest book and the total pages.

The right-to-left pass gives early scribers the least work they can take, which matches the tie rule.

These terms drive the search.

| term | meaning |
|---|---|
| `loadLow = heaviestBook` | no group can hold less than the largest book |
| `loadHigh = totalPages` | one scriber can hold every book |
| `scribesUsed <= scribeCount` | the trial load is feasible, so search lower |

Each guess halves the remaining load range.

This trace uses the first sample case, with nine books and three scribes.

| low | high | guess | scribes used | branch |
|---|---|---|---|---|
| 900 | 4500 | 2700 | 2 | lower high |
| 900 | 2700 | 1800 | 3 | lower high |
| 900 | 1800 | 1350 | 5 | raise low |
| 1351 | 1800 | 1575 | 4 | raise low |
| 1576 | 1800 | 1688 | 4 | raise low |
| 1689 | 1800 | 1744 | 3 | lower high |
| 1689 | 1744 | 1716 | 3 | lower high |
| 1689 | 1716 | 1702 | 3 | lower high |
| 1689 | 1702 | 1695 | 4 | raise low |
| 1696 | 1702 | 1699 | 4 | raise low |
| 1700 | 1702 | 1701 | 3 | lower high |
| 1700 | 1701 | 1700 | 3 | lower high |

The search settles on a load of 1700 pages.

The program then fills scribes from the last one back.

| scriber | first book | books taken | group sum |
|---|---|---|---|
| 2 | 8 | 2 | 1700 |
| 1 | 6 | 2 | 1300 |
| 0 | 1 | 5 | 1500 |

The answer line joins the groups: 100 200 300 400 500 / 600 700 / 800 900.

## Code

**Setup and input.**

```nim
const flushBlockBytes = 1 shl 17

var inputData: string
var lineReadBuffer: string
while readLine(stdin, lineReadBuffer):
  inputData.add lineReadBuffer
  inputData.add '\n'

var i = 0
```

`flushBlockBytes` is 128 KiB. The read loop runs to EOF and appends each line. Cost: one pass over the input bytes.

**Digit scanner.**

```nim
proc nextInt(): int64 =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i = i + 1
  var scannedValue: int64 = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    scannedValue = scannedValue * 10 + int64(int(inputData[i]) - 48)
    i = i + 1
  return scannedValue
```

The scanner skips non-digit bytes and builds the value by index. `int64` holds sums that exceed 32 bits. Cost: one pass over each number's digits.

**Case header.**

```nim
var caseCount = int(nextInt())
var outputBuffer: string

for _ in 1 .. caseCount:
  var bookCount = int(nextInt())
  var scribeCount = int(nextInt())
  var bookPages = newSeq[int64](bookCount)
  var heaviestBook: int64 = 0
  var totalPages: int64 = 0
```

`bookCount` and `scribeCount` open each case. `bookPages` holds the page counts, and the two totals start at zero. Cost: three allocations per case.

**Page read.**

```nim
  for j in 0 .. bookCount - 1:
    bookPages[j] = nextInt()
    if bookPages[j] > heaviestBook: heaviestBook = bookPages[j]
    totalPages = totalPages + bookPages[j]
```

`j` runs from 0 to `bookCount - 1`. `heaviestBook` and `totalPages` set the two search bounds. Cost: one read per book.

**Load search.**

```nim
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

The loop runs while `loadLow < loadHigh`. The test `runningSum + bookPages[j] > loadGuess` starts a new scriber. `scribesUsed <= scribeCount` picks the lower half of the range. Cost: O(m) page tests per guess.

**Slash placement.**

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
```

`countdown(scribeCount - 1, 0)` fills scribes from the last one back. `partFirstBook` records the first book of each part. The while loop stops before it would leave a scriber empty. Cost: O(m) over all scribes.

**Answer line.**

```nim
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

`j` runs over every book. The test `currentPart + 1 < scribeCount` avoids reading past the last part. The buffer flushes every 128 KiB. Cost: one line per case.

## Complexity

Costs by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| one case, load search | O(m log totalPages) | m page counts |
| one case, slash placement | O(m) | k part starts |
| output | one write per 128 KiB block | 128 KiB |

The binary search dominates the run.

Big O terms:

| measure | form |
|---|---|
| time | O(m log P) per case, for page total P |
| space | O(m + k) per case |

Both measures stay small at m <= 500.

Placing k - 1 slashes by brute force costs O(m^k) time. A dynamic program over parts and books costs O(k m^2) time and O(k m) space.
