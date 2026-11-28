# MARBLES — Marbles (SPOJ)
<https://www.spoj.com/problems/MARBLES/>

## Problem

Given marbles to choose from several unlimited colors, count selections that use every color at least once. Marbles of one color are indistinguishable, and order does not matter.

The input starts with the case count. Each case gives `n` marbles and `k` colors. Print the number of distinct selections.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Cases | at most 100 |
| Marbles `n` | 1 to 1000000 |
| Colors `k` | 1 to `n` |
| Answer | fits in a signed 64-bit integer |
| Judge time | 1000 ms |
| Memory | 1536 MB |
| Source size | 10000 B |

The formula keeps the work short even at the largest `n`.

Sample input and output:

Input:

```
2
10 10
30 7
```

Output:

```
1
475020
```

## Idea

Place one marble of each color first, then count the remaining placements. Think of putting dividers into gaps between identical beads on a string.

The answer is the binomial coefficient (a count of unordered choices) `C(n - 1, k - 1)`. The program multiplies a running ratio for `min(k - 1, n - k)` steps. Each step costs one multiply and one integer divide. A Pascal triangle would need a row of a million entries per case.

Takeaway: symmetry turns a huge coefficient into a short product.

## Why It Works

Stars and bars gives the closed form for this count.

1. Put the `n` marbles in a row.
2. The `k - 1` dividers occupy gaps among `n - 1` positions.
3. Every divider placement gives one valid selection.
4. The count is `C(n - 1, k - 1)`.
5. `C(N, r)` equals `C(N, N - r)`, so the smaller side is cheaper.

The terms are:

| Term | Meaning |
| --- | --- |
| `n` | Number of marbles |
| `k` | Number of colors |
| `chosenColors` | `1 + min(k - 1, n - k)` |
| `ways` | Running binomial value |

The loop length is the smaller side of the coefficient.

A script checked three cases:

| Case | Coefficient | Product steps | Result |
| --- | --- | --- | --- |
| `n=10 k=10` | C(9, 9) | 0 | 1 |
| `n=30 k=7` | C(29, 6) | 6 | 475020 |
| `n=6 k=3` | C(5, 2) | 2 | 10 |

The sample answers match the products.

## Code

**Number scanner.**

```nim
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value
```

The scanner skips whitespace before each number. It builds values from digits without token allocation. One call costs one pass over its digits.

**Ratio product.**

```nim
proc combineCount(marbleCount, colorCount: int): int64 =
  var chosenColors = colorCount
  if marbleCount - chosenColors < chosenColors - 1:
    chosenColors = marbleCount - chosenColors + 1
  var ways: int64 = 1
  for step in 1 .. chosenColors - 1:
    let numerator = int64(marbleCount - step)
    let denominator = int64(step)
    let firstDivisor = gcd(denominator, ways)
    let reducedWays = ways div firstDivisor
    let reducedDenominator = denominator div firstDivisor
    let secondDivisor = gcd(reducedDenominator, numerator)
    let reducedNumerator = numerator div secondDivisor
    let finalDenominator = reducedDenominator div secondDivisor
    ways = reducedWays * reducedNumerator div finalDenominator
  return ways
```

`chosenColors` moves to the smaller symmetric side. Each step divides the numerator and denominator by their common factors first. The product then stays inside a signed 64-bit integer even when the intermediate product of the direct formula would overflow.

**Driver and output.**

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  var marbleCount = nextInt(inputData, i)
  var colorCount = nextInt(inputData, i)
  outputBuffer.add $combineCount(marbleCount, colorCount)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The program joins input lines into one buffer. It writes each answer to a shared buffer. A flush starts at 131072 bytes.

**Final flush.**

```nim
stdout.write outputBuffer
```

This write emits the leftover answers. It runs once after the last case.

## Complexity

Each case costs a short product.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total digits) | O(Input size) |
| Ratio product | O(min(k, n - k)) | O(1) |
| Output | O(T) | O(1) |

The product never grows longer than 500000 steps.

| Measure | Bound |
| --- | --- |
| Time | O(T + total digits) |
| Space | O(Input size) |

The shortest side of the coefficient sets the cost.

A Pascal triangle would store a million entries and run much longer.
