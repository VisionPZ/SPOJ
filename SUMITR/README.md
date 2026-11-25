# SUMITR — Sums in a Triangle (SPOJ)

<https://www.spoj.com/problems/SUMITR/>

## Problem

The input gives a triangle of numbers with one value in the first row, two in the second, and so on. Compute the largest sum of a path from top to base, stepping each time directly below or one place to the right.

Input: the first integer gives the number of test cases. Each case starts with its row count `r`, followed by all row values. Output: one line per case, the largest sum along a path from top to base.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Test cases | about 1000 |
| Rows per case | positive, fewer than 100 |
| Cell values | 0 to 99 |
| Judge limit | 2000 ms, 1536 MB |

Large input and output demand buffered reads and batched writes.

The sample input and output:

```
2
3
1
2 1
1 2 3
4
1
1 2
4 1 2
2 3 1 1
```

```
5
9
```

## Idea

Merge the triangle from the bottom row upward, like pruning a family tree from the leaves. Each parent takes its own value plus the better of its two children.

The program stores the whole triangle in one flat array and edits it in place. It visits each cell once, so a case with `r` rows costs `O(r²)` time and needs no second triangle.

Enumerating every root-to-base path visits `2^(r-1)` routes. Bottom-up merging keeps only the best sum per cell and finishes in quadratic time.

Working from the leaves removes every repeated path computation.

## Why It Works

Four facts justify the in-place update.

1. Row `k` starts at offset `k(k + 1)/2` in the flat array. Earlier rows hold `1 + 2 + ... + k` values.
2. Cell `j` of row `k` has children at row `k + 1` positions `j` and `j + 1`.
3. Processing rows upward means both children already hold their best downward sums. Adding the larger child gives the best sum from the parent.
4. After row 0 is updated, its single cell holds the best sum over all paths.

The compact identifiers in the source:

| Term | Meaning |
| --- | --- |
| `a` | flat array holding all triangle values |
| `p` | cursor at the first value of the current case |
| `r` | row count of the current case |
| `k` | row index during the upward sweep |
| `t` | flat offset of row `k` within the case |

Negative row values cannot occur, so no path sum needs a separate minimum guard.

A generator trace of the first sample case:

```
start [1, 2, 1, 1, 2, 3]
k= 1 [1, 4, 4, 1, 2, 3]
k= 0 [5, 4, 4, 1, 2, 3]
answer: 5
```

Row 1 becomes `[4, 4]`, and the root becomes `1 + max(4, 4) = 5`.

## Code

**Bulk input.** The program reads all of standard input and splits it into one integer array.

```nim
import strutils,sequtils
var s=stdin.readAll
var a=s.splitWhitespace.map(parseInt)
var p=1
```

`readAll` returns the whole stream in one call.
`splitWhitespace` builds the token array.
`p` starts at 1 because slot zero holds the test count.

**Bottom-up sweep.** Each case updates rows from the second-to-last up to the top.

```nim
for _ in 1..a[0]:
 let r=a[p];p+=1
 for k in countdown(r-2,0):
  let t=p+k*(k+1)div 2
  for j in 0..k:a[t+j]+=max(a[t+k+1+j],a[t+k+2+j])
 echo a[p];p+=r*(r+1)div 2
```

`k` counts down from `r - 2`, so the bottom row stays unchanged.
Offset `t` equals `p + k(k + 1)/2`, the start of row `k`.

The two children sit at `t + k + 1 + j` and `t + k + 2 + j`. The cursor `p` then jumps past `r(r + 1)/2` values to the next case.

## Complexity

Each case touches every cell once while sweeping upward.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | token array |
| Row sweep | O(r²) cell updates | O(1) extra |
| Answer write | one line per case | buffered output |
| Total | O(sum of r² over cases) | input array |
| Per case | O(r²) | O(1) extra |

At `r = 99` the sweep updates about 5,000 cells.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(r²) per case, O(total cells) overall |
| Space | O(total cells) for the flat array |

Walking every root-to-base path takes `O(2^r)` time, while bottom-up merging finishes in quadratic time.
