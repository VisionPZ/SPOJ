# AE00 — Rectangles (SPOJ)

<https://www.spoj.com/problems/AE00/>

## Problem

Count how many distinct axis-aligned rectangles can be built using at most `N` unit squares, where rotating a rectangle does not create a new one.

Input holds a single integer `N`. Output prints one integer total.

Constraints and limits for the task:

| item | bound |
|---|---|
| unit squares `N` | `1 <= N <= 10000` |
| symmetry rule | `h * w` and `w * h` count once |
| judge limit | 1000 ms, 1536 MB |

Counting all pairs `h <= w` with `h * w <= N` directly takes `O(N^2)`, whereas iterating only heights up to `sqrt(N)` runs in `O(sqrt(N))`.

Sample input and output:

```
6
```

```
8
```

Valid dimensions `(h, w)` are `(1, 1..6)` (`6` rectangles) plus `(2, 2)` and `(2, 3)` (`2` rectangles), totaling `8`.

## Idea

Fix the shorter side `height` and count all valid widths directly in one division, like counting shelves up to length `N / height`. Requiring `height <= width` prevents counting rotated duplicates, bounding `height` at `sqrt(N)`.

Each height contributes `(squareCount div height) - height + 1` rectangles, taking `O(sqrt(N))` total additions and `O(1)` memory. Checking every `(height, width)` pair would loop quadratically up to `10^8` checks.

Bounding `height * height <= squareCount` computes the exact sum in roughly 100 steps at `N = 10000`.

## Why It Works

1. Every distinct rectangle corresponds uniquely to an integer pair `(height, width)` satisfying `1 <= height <= width` and `height * width <= squareCount`.
2. For fixed `height`, `width` ranges from `height` up to `squareCount div height`.
3. Whenever `height * height <= squareCount`, the interval `[height, squareCount div height]` is non-empty and contains `(squareCount div height) - height + 1` integers.
4. Once `height * height > squareCount`, no valid `width >= height` exists, so the loop stops.

Key identifiers in the program:

| term | meaning |
|---|---|
| `squareCount` | maximum available unit squares `N` |
| `height` | shorter side `h` iterated while `h * h <= N` |
| `rectCount` | cumulative count of distinct rectangles |

Worked trace on `N = 6`: `height = 1` adds `6` and `height = 2` adds `2`. Height `3` stops since `9 > 6`, returning `8`.

## Code

**Square-root side sweep.** `main` sums `(squareCount div height) - height + 1` over all valid shorter sides `height`.

```nim
  let squareCount = nextInt(inputData, scanPos)
  var rectCount = 0
  var height = 1
  while height * height <= squareCount:
    rectCount += (squareCount div height) - height + 1
    height += 1
```

## Complexity

| metric | cost |
|---|---|
| time | O(sqrt(N)) |
| space | O(1) |

For `N <= 10000`, the loop finishes in at most `100` integer divisions using constant memory.
