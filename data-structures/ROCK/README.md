# ROCK — Sweet and Sour Rock (SPOJ)

<https://www.spoj.com/problems/ROCK/>

## Problem

A stick consists of sweet and sour one-centimeter segments. Break it into pieces, each with more sweet than sour segments, to maximize the total length sold.

Input: `t` cases. Each starts with `N`, the stick length in centimetres, followed by a string of `N` characters where `1` means sweet and `0` means sour. Output: one integer per case, the maximum total length that can be sold.

The bounds from the statement:

| Item | Bound |
|---|---|
| Stick length `N` | 1 ≤ N ≤ 200 |
| Segment symbols | `0` sour, `1` sweet |
| Judge limit | 7000 ms, 1536 MB |

Every piece must have a strictly positive sweet-minus-sour score.

The sample input and output:

```
2
15
100110001010001
16
0010111101100000
```

```
9
13
```

## Idea

Score sweet as +1 and sour as −1, then a piece sells when its score is positive. Imagine walking along the stick with a running tally; any stretch ending above where it started can be sold.

The program computes prefix scores. A piece from `j + 1` to `i` sells when `P[i] > P[j]`, and its length is `i - j`. For each score it keeps the best value of `dp[j] - j`. A Fenwick tree (an array that answers prefix maximum queries) finds the best `j` with a smaller score in log time.

Each step costs O(log N), so a case costs O(N log N). Trying every pair of cut points costs O(N²). Both are small at `N = 200`, but the indexed form scales.

Prefix scores turn each candidate piece into one prefix-maximum query.

## Why It Works

Four facts carry the DP.

1. Each sweet segment adds +1 and each sour segment adds −1. A piece from `j + 1` to `i` is sellable exactly when `P[i] − P[j] > 0`.
2. The piece length is `i - j`. The DP uses `dp[j] - j` at every earlier score below `P[i]`.
3. The Fenwick tree stores `dp[j] − j` at index `P[j] + N + 1`. A prefix maximum up to the current score minus one returns the best eligible `j`.
4. The offset `N + 1` keeps negative scores at positive indices. A sentinel with score 0 and value 0 seeds the tree.

The values the DP keeps:

| Term | Meaning |
|---|---|
| `prefixScore` | running +1/−1 tally after a segment |
| `scoreIndex` | `prefixScore + stickLength + 1`, a positive array index |
| `fenwickPrefixMax` | best stored value at scores below the current one |
| `bestSold` | maximum sellable length found so far |

The offset makes negative tally values safe array indices.

A script-traced example with the first sample stick, `100110001010001`:

```
i     1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
P     1   0  -1   0   1   0  -1  -2  -1  -2  -1  -2  -3  -4  -3
cand  1   -   -   2   5   4   -   -   6   -   8   -   -   -   9
best  1   1   1   2   5   5   5   5   6   6   8   8   8   8   9

answer = 9 (the second sample stick gives 13)
```

A dash means no earlier score was lower, so no piece ends at that position.

## Code

**Constants and scanner.** The input is read once, and integers are scanned by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const negInfinite = -1000000000
const maxStickLength = 200
const treeCapacity = 2 * maxStickLength + 3

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

`negInfinite` initializes empty tree slots. `treeCapacity = 2N + 3` covers the full score range for `N ≤ 200`.

**Output helper.** Answer lines collect in one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The 256 KiB threshold keeps writes rare. `setLen 0` reuses the allocation after each flush.

**Fenwick tree.** Updates raise stored maxima, and queries return prefix maxima.

```nim
var fenwick: array[treeCapacity, int]
var fenwickSize = 0

proc fenwickUpdate(index: int, value: int) =
  var j = index
  while j <= fenwickSize:
    if value > fenwick[j]:
      fenwick[j] = value
    j += j and (-j)

proc fenwickPrefixMax(index: int): int =
  result = negInfinite
  var j = index
  while j > 0:
    if fenwick[j] > result:
      result = fenwick[j]
    j -= j and (-j)
```

`fenwickUpdate` climbs by the low bit and keeps the larger value. `fenwickPrefixMax` descends by the low bit and returns the largest stored value. Both cost O(log N).

**Case loop.** Each segment updates the score, queries the best partner, and stores the new DP value.

```nim
let caseCount = nextInt(inputData, scanPos)
for k in 0..<caseCount:
  let stickLength = nextInt(inputData, scanPos)
  while scanPos < inputData.len and inputData[scanPos] != '0' and inputData[scanPos] != '1':
    scanPos += 1
  fenwickSize = 2 * stickLength + 2
  for j in 0..<treeCapacity:
    fenwick[j] = negInfinite
  fenwickUpdate(stickLength + 1, 0)
  var prefixScore = 0
  var bestSold = 0
  for i in 1..stickLength:
    if inputData[scanPos] == '1':
      prefixScore += 1
    else:
      prefixScore -= 1
    scanPos += 1
    let scoreIndex = prefixScore + stickLength + 1
    let candidate = i + fenwickPrefixMax(scoreIndex - 1)
    if candidate > bestSold:
      bestSold = candidate
    fenwickUpdate(scoreIndex, bestSold - i)
  appendOutput($(bestSold))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scanner skips characters until it finds the `0`/`1` string. The sentinel update at score zero seeds the tree. `scoreIndex − 1` excludes equal scores, so the piece score stays positive.

## Complexity

Each case scans the stick once with a log-time query per segment.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Fenwick reset | O(N) | O(N) |
| Segment scan | O(N log N) | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(N log N) | O(N) |

With `N ≤ 200`, the tree fits in a fixed array.

| Measure | Big O |
|---|---|
| Time | O(N log N) per case |
| Space | O(N) for the Fenwick tree and buffers |

Testing every pair of cut points costs O(N²) instead.

Checking all cut pairs gives the same answer in O(N²) time. The Fenwick tree finds the best partner in O(log N) per segment.
