# EDIST — Edit distance (SPOJ)

<https://www.spoj.com/problems/EDIST/>

## Problem

Given two uppercase strings `A` and `B`, find the minimum number of single-character insertions, deletions, or substitutions needed to transform `A` into `B`.

Input starts with `T`, followed by `T` pairs of strings on separate lines. Output prints one minimum edit count per case.

Constraints and limits for the task:

| item | bound |
|---|---|
| test cases `T` | `1 <= T <= 10` |
| string lengths | at most `2000` characters |
| alphabet | uppercase letters |
| judge limit | 15000 ms, 1536 MB |

Storing a full `2001` by `2001` table uses millions of entries needlessly when each row depends only on the row above it.

Sample input and output:

```
1
FOOD
MONEY
```

```
4
```

Changing `F` to `M`, `O` to `N`, `D` to `E`, and inserting `Y` transforms `FOOD` into `MONEY` in `4` edits.

## Idea

Slide a two-row edit table down string `A` against string `B`, like comparing two spelled lines while keeping only last row's tally on scratch paper. Each cell takes the minimum of replacing (`prevRow[col - 1]`), deleting (`prevRow[col] + 1`), or inserting (`currRow[col - 1] + 1`).

This rolling dynamic program runs in `O(|A| * |B|)` time and `O(|B|)` memory, reusing two flat `seq[int]` rows across all cases. Recursive exploration without memoization would blow up exponentially in `O(3^|A|)`.

Scanning `inputData` slices directly via `spanA` and `spanB` avoids string copies completely.

## Why It Works

1. `prevRow[col]` stores the edit distance between prefix `A[0 ..< row - 1]` and prefix `B[0 ..< col]`.
2. Initializing `prevRow[col] = col` and `currRow[0] = row` captures pure insertions or deletions from empty prefixes.
3. Matching characters (`charA == B[col - 1]`) add `0` substitution cost; differing characters add `1`.
4. After finishing each row, copying `currRow` into `prevRow` prepares the next prefix step in `O(|B|)` space.

Key identifiers in the program:

| term | meaning |
|---|---|
| `spanA`, `spanB` | byte slices of strings `A` and `B` inside `inputData` |
| `prevRow` | previous dynamic programming row of costs |
| `currRow` | active dynamic programming row being filled |
| `editDistance` | computes minimum edits in `O(|A| * |B|)` time |

Worked trace on `"FOOD"` to `"MONEY"`: `""` costs `0..5`; row `'F'` gives `[1, 1, 2, 3, 4, 5]`; after rows `'O'`, `'O'`, `'D'`, `prevRow[5]` equals `4`.

## Code

**Rolling Levenshtein DP.** `editDistance` evaluates the three edit transitions in `currRow` from `prevRow` across `lenA` by `lenB` steps.

```nim
  for col in 0 .. lenB:
    prevRow[col] = col
  for row in 1 .. lenA:
    currRow[0] = row
    let charA = data[spanA.lo + row - 1]
    for col in 1 .. lenB:
      let repCost = prevRow[col - 1] + (if charA == data[spanB.lo + col - 1]: 0 else: 1)
      let delCost = prevRow[col] + 1
      let insCost = currRow[col - 1] + 1
      var best = if repCost < delCost: repCost else: delCost
      if insCost < best:
        best = insCost
      currRow[col] = best
    for col in 0 .. lenB:
      prevRow[col] = currRow[col]
```

## Complexity

| metric | cost |
|---|---|
| time | O(T * lenA * lenB) |
| space | O(lenB) |

Each case evaluates at most `4 * 10^6` cell updates using linear row storage instead of a quadratic table.
