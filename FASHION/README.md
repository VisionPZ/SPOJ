# FASHION — Fashion Shows (SPOJ)

<https://www.spoj.com/problems/FASHION/>

## Problem

Given `N` men's hotness scores and `N` women's hotness scores, pair them one-to-one so the sum of pairwise products `x * y` is maximized.

Input begins with `t`, followed by `t` cases each giving `N`, `N` men scores, and `N` women scores. Output prints one maximum bond sum per line.

Constraints and limits for the task:

| item | bound |
|---|---|
| group size `N` | `1 <= N <= 1000` |
| hotness ratings | non-negative integers |
| judge limit | 1000 ms, 1536 MB |

Testing all `N!` pairings is impossible for `N = 1000`, whereas pairing sorted lists is optimal and fast.

Sample input and output:

```
2
2
1 1
3 2
3
2 3 2
3 2 1
```

```
5
15
```

Sorting `[1, 1]` with `[2, 3]` yields `5`. Sorting `[2, 2, 3]` with `[1, 2, 3]` yields `15`.

## Idea

Sort both arrays ascending and pair positions `0 .. N - 1` straight across. This puts top multipliers together like matching strongest performers. By the rearrangement inequality, same-order pairing maximizes the dot product.

Quicksorting both `N`-element slices via `sortSlice` and multiplying matching indices costs `O(N log N)` time per test case. Trying arbitrary permutations would take factorial time.

Reusing pre-sized `menRates` and `womenRates` sequences avoids per-case heap allocations.

## Why It Works

1. When `a1 <= a2` and `b1 <= b2`, the difference `(a2 - a1) * (b2 - b1)` is non-negative. Expanding it gives `a1 * b1 + a2 * b2 >= a1 * b2 + a2 * b1`.
2. Swapping any out-of-order pair into sorted alignment never reduces the total sum.
3. Repeating swaps until both `menRates` and `womenRates` are sorted yields the global maximum dot product `totalBond`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `pairCount` | group size `N` for the current test case |
| `menRates`, `womenRates` | arrays storing the two rating lists |
| `sortSlice` | in-place quicksort ordering indices `0 .. pairCount - 1` |
| `totalBond` | `int64` sum of matched rating products |

Worked trace on `2 3 2` and `3 2 1`: sorting yields `[2, 2, 3]` and `[1, 2, 3]`, summing `2*1 + 2*2 + 3*3 = 15`.

## Code

**Sorted greedy pairing.** `main` sorts `menRates` and `womenRates` with `sortSlice`, then sums pairwise products into `totalBond`.

```nim
    sortSlice(menRates, 0, pairCount - 1)
    sortSlice(womenRates, 0, pairCount - 1)
    var totalBond = 0'i64
    for idx in 0 ..< pairCount:
      totalBond += int64(menRates[idx]) * int64(womenRates[idx])
    appendInt64Line(totalBond)
```

## Complexity

| metric | cost |
|---|---|
| time | O(t * N log N) |
| space | O(N) |

Sorting two arrays of length `N <= 1000` per case takes negligible time versus brute-force `O(N!)` matching.
