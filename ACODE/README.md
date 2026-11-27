# ACODE — Alphacode (SPOJ)

<https://www.spoj.com/problems/ACODE/>

## Problem

Count how many distinct letter sequences decode a digit string under the mapping `1 -> A`, `2 -> B`, ..., `26 -> Z`. Stop when a line equals `0`.

Input lists valid digit strings up to 5000 characters long with no spaces, followed by `0`. Output prints one 64-bit integer count per string.

Constraints and limits for the task:

| item | bound |
|---|---|
| string length | up to `5000` digits |
| termination | single digit `0` |
| answer width | fits in signed 64-bit integer |
| judge limit | 500 ms, 1536 MB |

Because valid decodings branch at each one-or-two-digit boundary, naive recursion explodes exponentially.

Sample input and output:

```
25114
1111111111
3333333333
0
```

```
6
89
1
```

For `25114`, the six decodings are `BEAN`, `BEAAD`, `YAAD`, `YAN`, `YKD`, and `BEKD`.

## Idea

Walk the digit string left to right while holding only the previous two decoding counts, like climbing stairs with one-step and two-step strides. At index `idx`, a nonzero single digit extends `prevOne`, while a two-digit number from `10` to `26` extends `prevTwo`.

This dynamic program scans each digit once in `O(L)` time and `O(1)` extra space instead of branching over `2^L` subsets. Sliding `prevTwo` and `prevOne` removes any need to allocate a 5000-element table.

Constant memory keeps cache usage tiny well inside the 500 ms limit.

## Why It Works

1. Any decoding of prefix `0 .. idx` ends with either a single digit (`data[idx]`) or a two-digit code (`data[idx - 1 .. idx]`).
2. Zero maps to no letter, so `data[idx]` forms a valid single-digit tail if and only if `data[idx] != '0'`.
3. A two-digit slice forms a valid letter if and only if its numeric value `pairVal` satisfies `10 <= pairVal <= 26`.
4. Summing `prevOne` (when nonzero) and `prevTwo` (when in `10 .. 26`) counts every distinct decoding once.

Key identifiers in the program:

| term | meaning |
|---|---|
| `prevTwo` | ways to decode up to `idx - 2` |
| `prevOne` | ways to decode up to `idx - 1` |
| `currentWays` | ways to decode up to `idx` |
| `pairVal` | two-digit integer formed by `idx - 1` and `idx` |

Worked trace on `25114`: counts start `(1, 1)` at `'2'`, then become `2` at `"25"`, `2` at `"251"` (`51 > 26`), `4` at `"2511"`, and `6` at `"25114"`.

## Code

**Rolling dynamic program.** `countDecodings` tracks only the last two prefix counts while handling `'0'` strictly inside valid pairs.

```nim
proc countDecodings(data: string, firstIdx: int, lastIdx: int): int64 =
  let spanLen = lastIdx - firstIdx
  if spanLen <= 0 or data[firstIdx] == '0':
    return 0'i64
  var prevTwo = 1'i64
  var prevOne = 1'i64
  for idx in (firstIdx + 1) ..< lastIdx:
    var currentWays = 0'i64
    if data[idx] != '0':
      currentWays += prevOne
    let pairVal = (int(data[idx - 1]) - firstDigitValue) * 10 + (int(data[idx]) - firstDigitValue)
    if pairVal >= 10 and pairVal <= 26:
      currentWays += prevTwo
    prevTwo = prevOne
    prevOne = currentWays
  prevOne
```

## Complexity

| metric | cost |
|---|---|
| time | O(L) |
| space | O(1) |

For total input length `L`, each digit takes constant arithmetic versus exponential `O(2^L)` naive backtracking.
