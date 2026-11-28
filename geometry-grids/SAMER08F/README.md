# SAMER08F — Feynman (SPOJ)

<https://www.spoj.com/problems/SAMER08F/>

## Problem

Count the total number of distinct axis-aligned squares of all sizes inside an `N` by `N` grid. Process each line until `0` ends the input.

Input contains one integer `N` per test line, ending with `0`. Output prints one integer total per test case.

Constraints and limits for the task:

| item | bound |
|---|---|
| grid side `N` | `1 <= N <= 100` |
| termination | `0` |
| judge languages | C, C++, C++14, Fortran, Java, Pascal (no Nim) |
| judge limit | 1000 ms, 1536 MB |

Iterating over every grid cell and size costs `O(N)` per case, whereas a closed form answers in `O(1)`.

Sample input and output:

```
2
1
8
0
```

```
5
1
204
```

An `8` by `8` chessboard holds `64 + 49 + 36 + 25 + 16 + 9 + 4 + 1 = 204` squares.

## Idea

Group squares by side length like stacking smaller tiles over larger ones: a grid of side `N` holds `(N - k + 1)^2` squares of side `k`, summing to `1^2 + 2^2 + ... + N^2`. Using the pyramid sum formula `N * (N + 1) * (2 * N + 1) / 6` answers each query in constant time.

A brute-force scan costs `O(N)` or `O(N^2)` per case, while the closed form needs two additions, two multiplications, and one division. Implementing the solution in C++14 matches SPOJ's accepted compiler list natively.

Evaluating the closed formula keeps per-case work constant even across tens of thousands of lines.

## Why It Works

1. A `k` by `k` sub-square can start at any row `1 .. sideLen - k + 1` and column `1 .. sideLen - k + 1`.
2. Letting `m = sideLen - k + 1` turns the total count into the sum of squares `sum_{m=1..sideLen} m^2`.
3. By standard summation, `sum_{m=1..sideLen} m^2 = sideLen * (sideLen + 1) * (2 * sideLen + 1) / 6`.
4. With `sideLen <= 100`, the numerator stays below `2.1 * 10^6` and fits safely in `int64_t`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `sideLen` | grid dimension `N` for the active test case |
| `squaresCount` | closed-form total distinct squares in the grid |
| `flushBlockBytes` | 128 KiB output flush threshold |

Worked trace on `N = 2`: `2 * 3 * 5 / 6 = 30 / 6 = 5` (four `1` by `1` squares plus one `2` by `2` square).

## Code

**Closed-form square counter.** `main` scans each `sideLen` until zero and evaluates the pyramid formula directly.

```cpp
  while (true) {
    int64_t sideLen = nextInt64(inputData, scanPos);
    if (sideLen == 0) {
      break;
    }
    int64_t squaresCount = sideLen * (sideLen + 1) * (2 * sideLen + 1) / 6;
    appendInt64(outputBuffer, squaresCount);
  }
```

## Complexity

| metric | cost |
|---|---|
| time | O(T) |
| space | O(1) |

For `T` test cases, each query computes its exact total in `O(1)` time without auxiliary memory.
