# GSS1 — Can you answer these queries I (SPOJ)

<https://www.spoj.com/problems/GSS1/>

## Problem

Given an array `A[1 .. N]` and `M` range queries `(x, y)`, output the maximum non-empty contiguous subarray sum inside each interval `A[x .. y]`.

Input contains `N`, `N` integers, `M`, and `M` pairs `(x, y)`. Output prints one maximum subarray sum per line.

Constraints and limits for the task:

| item | bound |
|---|---|
| array size `N` | `1 <= N <= 50000` |
| element values | `|A[i]| <= 15007` |
| source limit | `5000B` |
| judge limit | 1000 ms, 1536 MB |

Running Kadane's scan independently per query takes `O(N * M)` time and exceeds the one-second limit.

Sample input and output:

```
3
-1 2 3
1
1 2
```

```
2
```

Inside `[-1, 2]`, picking the single element `[2]` maximizes the non-empty sum.

## Idea

Store four summary numbers (`total`, `pref`, `suff`, `best`) for each segment-tree block (`SegNode`), like recording total profit, best opening streak, best closing streak, and best overall streak per quarter. Merging two adjacent blocks tests whether the best subarray crosses the boundary via `leftNode.suff + rightNode.pref`.

An iterative bottom-up segment tree builds in `O(N)` time and answers each range query in `O(log N)` steps without recursion overhead. Scanning each interval linearly takes `O(N)` per query and fails when `M` is large.

Tracking separate `leftAcc` and `rightAcc` accumulators respects segment order cleanly without identity-element overflow tricks.

## Why It Works

1. Any non-empty contiguous subarray inside `leftNode` + `rightNode` lies entirely in `leftNode`, entirely in `rightNode`, or crosses their boundary.
2. The best crossing sum takes the largest suffix of `leftNode` followed immediately by the largest prefix of `rightNode`.
3. Updated `pref` equals `max(leftNode.pref, leftNode.total + rightNode.pref)`, and `suff` updates symmetrically from the right.
4. Keeping `hasLeft` and `hasRight` flags avoids needing a negative-infinity dummy identity when `[leftPos, rightPos]` splits bottom-up.

Key identifiers in the program:

| term | meaning |
|---|---|
| `SegNode` | tuple holding `total`, `pref`, `suff`, and `best` |
| `combineNodes` | merges two adjacent `SegNode` summaries in `O(1)` |
| `treeBase` | power-of-two leaf offset inside `tree` |
| `leftAcc` | merged summary accumulated from left boundary indices |
| `rightAcc` | merged summary accumulated from right boundary indices |

Worked trace on `[-1, 2, 3]` for query `(1, 2)`: left leaf `(-1)` merges with leaf `(2)`. The merged node holds `total = 1`, `pref = 1`, `suff = 2`, and `best = 2`.

## Code

**Summary combiner.** `combineNodes` computes the four invariants when gluing a left interval onto a right interval.

```nim
proc combineNodes(leftNode: SegNode, rightNode: SegNode): SegNode {.inline.} =
  result.total = leftNode.total + rightNode.total
  let prefCand = leftNode.total + rightNode.pref
  result.pref = if leftNode.pref > prefCand: leftNode.pref else: prefCand
  let suffCand = rightNode.total + leftNode.suff
  result.suff = if rightNode.suff > suffCand: rightNode.suff else: suffCand
  let maxEnds = if leftNode.best > rightNode.best: leftNode.best else: rightNode.best
  let crossVal = leftNode.suff + rightNode.pref
  result.best = if maxEnds > crossVal: maxEnds else: crossVal
```

**Iterative range query.** `main` walks inward toward the root while preserving left-to-right merge order in `leftAcc` and `rightAcc`.

```nim
    while leftPos <= rightPos:
      if (leftPos and 1) == 1:
        if not hasLeft:
          leftAcc = tree[leftPos]
          hasLeft = true
        else:
          leftAcc = combineNodes(leftAcc, tree[leftPos])
        leftPos += 1
      if (rightPos and 1) == 0:
        if not hasRight:
          rightAcc = tree[rightPos]
          hasRight = true
        else:
          rightAcc = combineNodes(tree[rightPos], rightAcc)
        rightPos -= 1
      leftPos = leftPos shr 1
      rightPos = rightPos shr 1
```

## Complexity

| metric | cost |
|---|---|
| time | O(N + M log N) |
| space | O(N) |

Building the tree takes linear time and each query visits at most `2 log N` nodes instead of `O(N)` elements.
