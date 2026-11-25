# DOSA — Lalith Dosa (SPOJ)

<https://www.spoj.com/problems/DOSA/>

## Problem

Change the fewest prices so a sequence becomes strictly increasing. Each changed price may be any positive integer.

The first line holds N, the number of prices. The second line holds N prices a_i with 0 < N ≤ 10^6 and 0 < a_i ≤ 10^9. Print one integer: the minimum number of prices to replace.

| item | bound |
|---|---|
| prices N | 1 to 10^6 |
| each price a_i | 1 to 10^9 |
| judge limit | 500 ms, 1536 MB |

The million-element input drives the choice of a near-linear algorithm.

Sample input:

```
6
1 7 10 2 20 22
```

Sample output:

```
1
```

## Idea

Keeping a price is like reserving a seat in a row: each earlier seat needs a smaller positive ticket number. Subtract the position from each price, then keep the longest run of values that never decreases. The difference between N and that run is the answer.

The algorithm is a longest non-decreasing subsequence computed with binary-search tails. Each price costs one binary search, so the work is O(N log N). A quadratic dynamic program would perform 10^12 comparisons for the largest input. Each visit touches one adjusted price and a short tails array.

## Why It Works

1. A kept price at position i must be at least i, because i − 1 positive integers must precede it.
2. Two kept prices at positions i < j need a_j − a_i ≥ j − i to leave room for integers between them.
3. Subtracting the position turns that rule into b_j ≥ b_i, where b_i = a_i − i.
4. Prices with b_i < 0 cannot be kept, so the search skips them.
5. The longest non-decreasing subsequence of the remaining b values is the largest keepable set.
6. Every other price is replaced, so the answer is N minus the subsequence length.

| term | meaning |
|---|---|
| `adjustedPrice` | price minus its 1-based position |
| `keptValues` | smallest possible tail of a subsequence of each length |
| `lowerIndex` | insertion slot found by binary search |
| `replacementCount` | number of prices that must change |

The tails array records only the best ending value for each subsequence length.

The script trace for the first sample gives:

```
adjusted: 0 5 7 -2 15 16
kept: 0 5 7 15 16
answer: 1
```

The kept set skips the price 2, and a single replacement fixes the sequence.

The second sample adjusts to `0 0 -1 -1 -1`. Only the two zeros can stay, so the answer is 3. Values below zero are skipped, which protects the rule that replacements must be positive.

## Code

**Input and scanning.** The reader loads stdin and the scanner walks the prices.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The whole input is read with two line reads when prices share one line.
The scanner skips spaces and newlines without allocating tokens.
Every price fits in an int before the position subtraction.

**Tails search.** Binary search places each usable adjusted price in the tails array.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dosaCount = nextInt(inputData, scanPos)
var keptValues = newSeq[int64](0)
for positionIndex in 0 .. dosaCount - 1:
  let priceValue = int64(nextInt(inputData, scanPos))
  let adjustedPrice = priceValue - int64(positionIndex + 1)
  if adjustedPrice < 0:
    continue
  var lowerIndex = 0
  var upperIndex = keptValues.len
  while lowerIndex < upperIndex:
    let middleIndex = (lowerIndex + upperIndex) div 2
    if keptValues[middleIndex] > adjustedPrice:
      upperIndex = middleIndex
    else:
      lowerIndex = middleIndex + 1
  if lowerIndex == keptValues.len:
    keptValues.add adjustedPrice
  else:
    keptValues[lowerIndex] = adjustedPrice
```

The strict comparison lets equal adjusted prices extend a subsequence.
Negative adjusted prices are skipped before the search.
Each price costs one binary search over at most N tails.

**Answer output.** The replacement count is written once.

```nim
let replacementCount = dosaCount - keptValues.len
appendOutput($replacementCount)
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The tails length is the longest keepable subsequence.
The buffer flushes in one block at the end.
One line is the entire output.

## Complexity

Each price takes one binary search and one update.

| phase | time | space |
|---|---|---|
| input read | one pass over the price line | one input string |
| tails search | O(log N) per price | up to N tails |
| output | one line | block buffer |

The tails array and input string are the only large allocations.

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

A quadratic subsequence dynamic program would need O(N^2) work and cannot finish for N = 10^6.
