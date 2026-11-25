# PERMUT1 — Permutations (SPOJ)
<https://www.spoj.com/problems/PERMUT1/>

## Problem

An inversion is a pair of entries out of order: aᵢ > aⱼ with i < j. Count how many permutations of n numbers have exactly k inversions.

You receive several n-k pairs. The counts can be large, so print the exact integer, not a floating-point estimate.

Input: the first integer is d, the number of data sets. Each following line gives n and k. Output: one line per data set with the number of n-permutations having k inversions.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Data sets d | 1 to 10 |
| Permutation size n | 1 to 12 |
| Inversion count k | 0 to 98 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The sample asks for four-element permutations with one inversion:

```
1
4 1
```

```
3
```

The three answers are 2134, 1324, and 1243.

## Idea

Insert the largest number last and count how many smaller numbers it passes. Picture adding one new book to a sorted shelf: sliding it past t books creates exactly t new out-of-order pairs.

The program uses dynamic programming. Entry `dp[j][inv]` counts permutations of j numbers with inv inversions. Inserting the new largest value j lets it pass `added` smaller values, where added ranges from 0 to j − 1. So `dp[j][inv]` is the sum of `dp[j − 1][inv − added]` over that range.

Counts can exceed machine integers, so each value is a big integer stored as base-10⁹ limbs. Addition walks limbs with a carry; printing goes from the most significant limb down.

The table costs O(maxN × maxK × maxN) big-integer additions once, then each query is O(1). Listing all n! permutations costs factorial time.

Takeaway: one insertion recurrence and a limb-based big integer answer every query at once.

## Why It Works

Four facts prove the recurrence.

1. Insert the largest value j into any permutation of the other j − 1 values. If it ends up past `added` smaller values, it creates exactly `added` new inversions.
2. The value `added` ranges from 0 to j − 1. Every final permutation has one insertion history, so summing over added counts each permutation once.
3. The seed `dp[0][0] = 1` is the empty permutation. For every j, `dp[j][0] = 1`, the fully sorted order.
4. Base-10⁹ limbs keep each limb below 2³¹, so limb sums with a carry fit in int64. Printing the top limb first, then nine-digit groups, reconstructs the exact value.

These are the parts of one DP row:

| Term | Meaning |
| --- | --- |
| `dp[j][inv]` | permutations of j numbers with inv inversions |
| `added` | smaller values passed by the newly inserted largest value |
| `upperAdded` | min(inv, j − 1), the largest possible added count |
| `total` | running sum of big integers for one cell |
| `limbBase` | 10⁹, the value of one stored limb |

A script prints the small DP table built by the recurrence:

```
n\k     0     1     2     3     4     5     6
 0      1     0     0     0     0     0     0
 1      1     0     0     0     0     0     0
 2      1     1     0     0     0     0     0
 3      1     2     2     1     0     0     0
 4      1     3     5     6     5     3     1

dp[4][1] = dp[3][1]+dp[3][0] = 2 + 1 = 3
```

The last line matches the sample. Values stay exact because every step uses integer limbs.

## Code

**Input.** The whole stream goes into one buffer, and big integers get a limb type.

```nim
const flushBlockBytes = 1 shl 18
const limbBase = 1000000000
const firstDigitValue = 48

type BigInt = seq[int64]

var inputData = ""
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  result = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + int(data[i]) - firstDigitValue
    i += 1
```

`BigInt` is a sequence of base-10⁹ limbs, least significant first. The scanner walks one shared buffer. Cost is one pass over the input bytes.

**Big integers.** Addition carries across limbs; printing pads every lower limb to nine digits.

```nim
proc addBig(left, right: BigInt): BigInt =
  let maxLen = max(left.len, right.len)
  result = newSeq[int64](maxLen + 1)
  var carry: int64 = 0
  var i = 0
  while i < maxLen:
    var partSum: int64 = carry
    if i < left.len: partSum += left[i]
    if i < right.len: partSum += right[i]
    if partSum >= limbBase:
      partSum -= limbBase
      carry = 1
    else:
      carry = 0
    result[i] = partSum
    i += 1
  result[maxLen] = carry
  if carry == 0: result.setLen(maxLen)

proc appendBig(output: var string, value: BigInt) =
  if value.len == 0:
    output.add char(firstDigitValue)
    return
  var i = value.len - 1
  output.add $value[i]
  while i > 0:
    i -= 1
    var j = limbBase div 10
    while j > 0:
      output.add char(firstDigitValue + (value[i] div j) mod 10)
      j = j div 10
```

The loop bound is the longer operand. At most one carry propagates from each limb, so the sum stays exact. The empty case prints `0`. Each operation costs O(number of limbs).

**Driver.** The program sizes the table from the largest query, then fills and answers it.

```nim
var i = 0
var datasetCount = nextInt(inputData, i)
var queryN = newSeq[int](datasetCount)
var queryK = newSeq[int](datasetCount)
var maxN = 0
var maxK = 0
for j in 0..<datasetCount:
  let currentN = nextInt(inputData, i)
  let currentK = nextInt(inputData, i)
  queryN[j] = currentN
  queryK[j] = currentK
  if currentN > maxN: maxN = currentN
  if currentK > maxK: maxK = currentK

var dp = newSeq[seq[BigInt]](maxN + 1)
for j in 0..maxN:
  dp[j] = newSeq[BigInt](maxK + 1)
dp[0][0] = @[1'i64]
for j in 1..maxN:
  dp[j][0] = @[1'i64]
  for invCount in 1..maxK:
    var total: BigInt = @[]
    let upperAdded = min(invCount, j - 1)
    for added in 0..upperAdded:
      total = addBig(total, dp[j - 1][invCount - added])
    dp[j][invCount] = total

var outputBuffer = ""
for j in 0..<datasetCount:
  appendBig(outputBuffer, dp[queryN[j]][queryK[j]])
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

`upperAdded = min(invCount, j − 1)` avoids negative indices and useless terms. The table is built once for the largest n and k in the input. Each query then reads one cell; the final write flushes the tail.

## Complexity

Table building carries the cost.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Table build | O(maxN × maxK × min(maxN, maxK)) limb additions | O(maxN × maxK) big integers |
| Query answer | O(limbs of answer) | O(1) |
| Output | O(datasets) | O(block size) |

The build dominates once, at roughly 12 × 98 × 12 additions here.

| Measure | Big O |
| --- | --- |
| Precomputation | O(maxN × maxK × min(maxN, maxK)) |
| Time per query | O(number of output limbs) |
| Working space | O(maxN × maxK) |

Enumerating permutations takes O(n!) time, while the DP reaches the same counts through repeated sums.
