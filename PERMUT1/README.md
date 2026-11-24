## Problem

An inversion of a permutation is a pair of positions where the earlier value is larger. Read `d` datasets, each holding integers `n` and `k`. Print the number of `n`-element permutations with exactly `k` inversions. Each answer occupies one line.

The judge fixes these bounds:

| quantity | limit |
| --- | --- |
| datasets `d` | 1 .. 10 |
| `n` in the statement | 1 .. 12 |
| `n` in judge data | up to 20 |
| `k` | 0 .. 98 |
| time limit | 3000 ms |
| memory limit | 1536 MB |

The larger `n` matters because `20!` exceeds 32 bits but stays inside 64 bits.

## Idea

Add the largest element last, so element `i` creates `x` new inversions for each `x` from zero through `i - 1`. A table fills from short permutations to long ones. Counts use base-one-billion limbs, because they can exceed 64 bits.

Cost: at most `min(j, i-1) + 1` limb additions per cell, and one table lookup per dataset instead of enumerating permutations.

## Why It Works

When element `i` joins a shorter permutation, it is larger than every element there. The elements placed after it become its inversions. That number `x` ranges from zero to `i - 1`.

Two different values of `x` lead to different final permutations. So the counts for all choices of `x` add up without overlap.

The recurrence is:

`count(i, j) = sum(count(i - 1, j - x))` for `x` from 0 to `min(j, i - 1)`.

Each term has a fixed role:

- `i` is the current permutation length.
- `j` is the inversion count wanted.
- `x` is the number of shorter elements placed after the largest one.
- `count(i - 1, j - x)` counts shorter permutations that supply the remaining inversions.

An empty permutation has one arrangement with zero inversions. A sorted permutation of any positive length also has one arrangement with zero inversions. Those two facts seed the table.

A script computed the counts for lengths one through four.

| length | counts by inversion number |
| --- | --- |
| 1 | 1 |
| 2 | 1 1 |
| 3 | 1 2 2 1 |
| 4 | 1 3 5 6 5 3 1 |

The last row sums to 24, which is four factorial. For length four and one inversion, the recurrence gives `count(3, 1) + count(3, 0) = 2 + 1 = 3`.

## Code

The program reads the whole input once, then scans characters by index.

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
```

The line loop ends at EOF, so it runs once per input line. The added newline keeps adjacent numbers apart. The cost is one append per line.

```nim
proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  result = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + int(data[i]) - firstDigitValue
    i += 1
```

The skip loop crosses separators and the digit loop crosses each number. Non-digits never reach the value, so blank lines cause no error. The cost is one pass over the input buffer.

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
```

The loop runs for `max(left.len, right.len)` limbs. The final trim drops a zero carry limb, which would print a leading zero. The cost is one add per limb.

```nim
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

The outer loop runs once per limb below the top. The inner loop writes nine digits and pads lower limbs with zeros. The cost is one pass over the value's digits.

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
```

The loop runs exactly `datasetCount` times. It records the largest `n` and `k`, so the table stays small. The cost is one scan of the parsed numbers.

```nim
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
```

The length loop runs `maxN` times and the inversion loop runs `maxK` times. An empty sequence denotes zero, so no special case exists. The cost is the sum of the inner loop bounds.

```nim
var outputBuffer = ""
for j in 0..<datasetCount:
  appendBig(outputBuffer, dp[queryN[j]][queryK[j]])
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The loop runs once per dataset and flushes at `flushBlockBytes`. The final write flushes the tail shorter than one block. The cost is one lookup and one limb conversion per dataset.

## Complexity

Reading costs O(input bytes) time and O(input bytes) space. The table holds `(maxN + 1) * (maxK + 1)` cells of at most three limbs at these bounds. Filling costs O(`maxN * maxK * min(maxN, maxK)`) limb additions. Output costs O(datasets times digits) time inside one buffered string.

Total time is O(`input bytes + maxN * maxK * min(maxN, maxK) + output bytes`). Total space is O(`input bytes + maxN * maxK * digits + flushBlockBytes`).

A naive method enumerates every permutation and counts its inversions. That costs O(`n! * n^2`) per dataset, while this table answers each dataset with one lookup.
