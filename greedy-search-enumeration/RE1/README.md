# RE1 — Reverse Engineering (SPOJ)

<https://www.spoj.com/problems/RE1/>

## Problem

Count the arrangements of distinct numbers whose sorting cost equals a target swap count. Sorting cost is the fewest adjacent swaps needed to reach ascending order, which equals the number of inverted pairs.

Input starts with T, the number of cases, where T < 200000. Each case gives N and K, with 1 ≤ N ≤ 100 and 0 ≤ K ≤ 10000. Print one labeled line per case with its case number and answer, where the answer counts arrangements of N with exactly K inversions, modulo 1000000007.

| item | bound |
|---|---|
| cases T | under 200000 |
| numbers N | 1 to 100 |
| target K | 0 to 10000 |
| judge limit | 1000 ms, 1536 MB |

The 101 by 10001 answer grid drives one shared precomputation.

The sample case has three queries and three replies.

```
3
3 1
10 45
100 56
```

```
Case 1: 2
Case 2: 1
Case 3: 904490303
```

The answer for 100 numbers and 56 inversions is 904490303.

## Idea

The trick is to count arrangements by their inversion count, like tallying how many pairs trade places in a single-file line. An inversion vector assigns each position a small counter, and those counters add up to K.

The algorithm builds a table with the sliding-window inversion recurrence. Row n holds counts for n numbers, and each cell is a running sum of the row above. Each case then costs one table lookup, while listing every arrangement would cost N factorial work.

Precompute once, then answer each case in constant time.

## Why It Works

1. Distinct numbers have N factorial relative orders, each matching one permutation of ranks.
2. One adjacent swap removes exactly one inverted pair, so the minimum swap count is the inversion count.
3. Inserting the largest number into a permutation of n-1 numbers creates i new inversions for i in 0 to n-1.
4. Hence the count for n at K is the sum of counts for n-1 at K-i over that range.
5. Subtracting the outgoing term keeps that sum as a sliding window, so the table is exact.

| term | meaning |
|---|---|
| `swapTable` | counts indexed by number count and inversion count |
| `tableStride` | number of columns in one table row |
| `windowTotal` | running sum of the previous row over the current window |
| `numberCount` | current row index, the amount of numbers |

The terms give every table cell from two additions and one subtraction.

The generator cross-checks the table against enumerated permutations for small N.

```
brute_count(3, 0) = 1
brute_count(3, 1) = 2
brute_count(3, 2) = 2
brute_count(3, 3) = 1
```

Two arrangements of three numbers have one inversion, matching Case 1.

## Code

**Input and table build.** The reader loads all tokens, then fills the table row by row.

```nim
const flushBlockBytes = 1 shl 17
const modulus = 1000000007
const maxNumberCount = 100
const maxSwapCount = 10000
const tableStride = maxSwapCount + 1

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
```

The scanner skips spaces and line breaks between tokens.

`appendOutput` flushes one large block, not one line per case.

The table build costs one million sliding-window steps.

**Table recurrence.** Each cell uses the previous row and one outgoing subtraction.

```nim
var swapTable = newSeq[int]((maxNumberCount + 1) * tableStride)
swapTable[0] = 1
for numberCount in 1 .. maxNumberCount:
  var windowTotal = 0
  let previousRow = (numberCount - 1) * tableStride
  let currentRow = numberCount * tableStride
  for inversionCount in 0 .. maxSwapCount:
    windowTotal += swapTable[previousRow + inversionCount]
    if windowTotal >= modulus:
      windowTotal -= modulus
    if inversionCount >= numberCount:
      windowTotal -= swapTable[previousRow + inversionCount - numberCount]
      if windowTotal < 0:
        windowTotal += modulus
    swapTable[currentRow + inversionCount] = windowTotal
```

Row zero has one arrangement with zero inversions.

The guard keeps the window inside the modulus without a division.

Values beyond 4950 inversions stay zero for 100 numbers.

**Case answers.** Every case reads two numbers and writes one labeled line.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let numberCount = nextInt(inputData, scanPos)
  let swapLimit = nextInt(inputData, scanPos)
  var arrangementCount = 0
  if numberCount >= 1 and numberCount <= maxNumberCount and swapLimit <= maxSwapCount:
    arrangementCount = swapTable[numberCount * tableStride + swapLimit]
  appendOutput("Case " & $caseIndex & ": " & $arrangementCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The bound check keeps an oversized K from leaving the table.

The final write clears any buffered tail after the case loop.

## Complexity

One precomputation serves all cases, and each case is one lookup.

| phase | time | space |
|---|---|---|
| input read | one pass over case tokens | one input string |
| table build | 100 rows of 10001 cells | 101 table rows |
| case answers | one lookup per case | one output block |

Each case adds only a constant amount of work after the build.

| measure | Big O |
|---|---|
| time | O(100 * 10000 + T) |
| space | O(100 * 10000) |

Enumerating every permutation would cost N factorial time per case, so the shared table is the decisive gain.
