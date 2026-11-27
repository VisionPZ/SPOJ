# ACPC10A — What's Next (SPOJ)

<https://www.spoj.com/problems/ACPC10A/>

## Problem

Given three distinct integers from either an arithmetic progression or a geometric progression, identify the sequence type and print the fourth term. Stop when all three numbers equal zero.

Input has one triple per line until `0 0 0`. Output prints `AP v` or `GP v` on each line.

Constraints and limits for the task:

| item | bound |
|---|---|
| sequence terms | `-10000 < a1, a2, a3 < 10000` |
| termination | `0 0 0` |
| judge limit | 1799 ms, 1536 MB |

Because values can be negative and geometric ratios can be rational (`16 8 4 -> 2`), multiply before dividing.

Sample input and output:

```
4 7 10
2 6 18
0 0 0
```

```
AP 13
GP 54
```

The first triple grows by constant step `3`, while the second multiplies by `3`.

## Idea

Compare the two consecutive gaps like checking steps on a staircase: equal steps mean an arithmetic progression, while unequal gaps mean a geometric progression. Because both ratios stay rational integers here, `thirdTerm * secondTerm div firstTerm` avoids losing fractional ratios such as `8 / 16`.

Checking each triple takes `O(1)` arithmetic per case with buffered streaming over standard input. Computing `secondTerm div firstTerm` before multiplying fails when `|secondTerm| < |firstTerm|`, truncating the ratio to zero.

One branch and one multiplication handle every valid triple directly.

## Why It Works

1. If `secondTerm - firstTerm == thirdTerm - secondTerm`, the sequence is arithmetic with constant step `diffSecond`.
2. Adding `diffSecond` to `thirdTerm` gives the next arithmetic term immediately.
3. Otherwise the triple is guaranteed to be geometric with ratio `secondTerm / firstTerm`.
4. Multiplying `thirdTerm * secondTerm` in `int64` before dividing by `firstTerm` stays exact and avoids overflow since `|term| < 10^4`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `firstTerm` | first integer in the triple |
| `secondTerm` | middle integer in the triple |
| `thirdTerm` | third integer in the triple |
| `diffFirst` | difference `secondTerm - firstTerm` |
| `diffSecond` | difference `thirdTerm - secondTerm` |

Worked trace on `16 8 4`: `diffFirst = -8` differs from `diffSecond = -4`, so `(4 * 8) div 16 = 2` produces `GP 2`.

## Code

**Progression classifier.** `main` compares consecutive differences and emits either the next `AP` or `GP` term.

```nim
    let diffFirst = secondTerm - firstTerm
    let diffSecond = thirdTerm - secondTerm
    if diffFirst == diffSecond:
      appendLine("AP " & $(thirdTerm + diffSecond))
    else:
      appendLine("GP " & $((thirdTerm * secondTerm) div firstTerm))
```

## Complexity

| metric | cost |
|---|---|
| time | O(T) |
| space | O(1) |

For `T` triples, the program scans every integer once in linear time with constant working space.
