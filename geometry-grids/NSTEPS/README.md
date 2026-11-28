# NSTEPS — Number Steps (SPOJ)

<https://www.spoj.com/problems/NSTEPS/>

## Problem

Non-negative integers `0, 1, 2, ...` are written diagonally along two lines on the plane starting at `(0, 0)`, `(1, 1)`, `(2, 0)`, `(3, 1)`, repeating upward and right. Given `(x, y)`, output the number written there or `No Number` if the point is empty.

Input starts with `N`, followed by `N` coordinate pairs `(x, y)`. Output prints one line per query.

Constraints and limits for the task:

| item | bound |
|---|---|
| coordinates `x, y` | `0` to `10000` |
| grid lines | `x == y` or `x == y + 2` |
| judge limit | 1159 ms, 1536 MB |

Simulating the walk up to coordinate `10000` for every query wastes linear work per query when a single formula decides immediately.

Sample input and output:

```
3
4 2
6 6
3 4
```

```
6
12
No Number
```

Point `(4, 2)` lies on `x = y + 2` with even `x`, yielding `4 + 2 = 6`.

## Idea

Check whether `(xCoord, yCoord)` lands on either diagonal track, like checking mileposts along two parallel rails. Numbers sit exclusively on `xCoord == yCoord` or `xCoord == yCoord + 2`, with value `xCoord + yCoord` at even columns and `xCoord + yCoord - 1` at odd columns.

Evaluating two comparisons and one parity bit answers each query in `O(1)` time and `O(1)` memory. Simulating the spiral grid per query or storing a `10001` by `10001` table uses needless memory and time.

Parity decides both rails simultaneously in one short expression.

## Why It Works

1. Starting at `(0, 0)`, each block of four integers shifts diagonally. Values `4k` through `4k + 3` occupy `(2k, 2k)`, `(2k + 1, 2k + 1)`, `(2k + 2, 2k)`, and `(2k + 3, 2k + 1)`.
2. Thus `(xCoord, yCoord)` carries a number if and only if `xCoord == yCoord` or `xCoord == yCoord + 2`.
3. When `xCoord` is even, both `(2k, 2k)` and `(2k + 2, 2k)` equal `xCoord + yCoord`.
4. When `xCoord` is odd, both `(2k + 1, 2k + 1)` and `(2k + 3, 2k + 1)` equal `xCoord + yCoord - 1`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `xCoord`, `yCoord` | input coordinates `(x, y)` |
| `sumVal` | coordinate sum `xCoord + yCoord` |
| `stepVal` | computed grid integer before formatting |

Worked trace on `(3, 4)`: `3 != 4` and `3 != 4 + 2`, so the condition fails and outputs `No Number`.

## Code

**Closed-form step evaluator.** `main` checks both valid diagonals and adjusts by `1` for odd `xCoord`.

```nim
    let xCoord = nextInt(inputData, scanPos)
    let yCoord = nextInt(inputData, scanPos)
    if xCoord == yCoord or xCoord == yCoord + 2:
      let sumVal = xCoord + yCoord
      let stepVal = if (xCoord and 1) == 0: sumVal else: sumVal - 1
      appendLine($stepVal)
    else:
      appendLine("No Number")
```

## Complexity

| metric | cost |
|---|---|
| time | O(N) |
| space | O(1) |

For `N` coordinate queries, each case executes constant arithmetic without building the grid.
