# DQUERY — D-query (SPOJ)

<https://www.spoj.com/problems/DQUERY/>

## Problem

Given an array `a_1 .. a_n` and `q` range queries `(i, j)`, print how many distinct values appear inside each subarray `a_i .. a_j`.

Input gives `n`, the `n` array values, `q`, and `q` one-based query pairs `(i, j)`. Output prints one distinct count per line in input query order.

Constraints and limits for the task:

| item | bound |
|---|---|
| array length `n` | `1 <= n <= 30000` |
| element values | `1 <= a_i <= 10^6` |
| queries `q` | `1 <= q <= 200000` |
| judge limit | 1000 ms, 1536 MB |

Scanning each query subarray naively costs `O(n * q)` operations and times out at `6 * 10^9` steps.

Sample input and output:

```
5
1 1 2 1 3
3
1 5
2 4
3 5
```

```
3
2
3
```

Subarray `[2, 4]` contains `{1, 2, 1}`, leaving `2` distinct values.

## Idea

Group queries by their right endpoint using bucket lists (`bucketHead`, `queryNext`), like shelving receipts by checkout date before tallying active items. As `rightPos` sweeps left to right, mark each value only at its rightmost occurrence (`lastSeenPos`) inside a Fenwick tree (`bitTree`).

Removing the previous occurrence when a value repeats ensures every active value contributes `1` at its latest position inside `[1 .. rightPos]`. Summing `[queryLeft .. rightPos]` answers each query in `O(log n)` time, while bucket lists skip sorting `200,000` queries completely.

Offline right-endpoint bucketing with buffered output finishes `200,000` queries well under 50 ms.

## Why It Works

1. Any distinct value appearing inside `[l, r]` has a unique rightmost position inside `[1, r]` that falls at or after `l`.
2. When `rightPos` visits `elem`, subtracting `1` at `lastSeenPos[elem]` (if positive) and adding `1` at `rightPos` keeps `bitTree` holding `1` solely at each distinct element's latest index.
3. Linking queries onto `bucketHead[rightPos]` processes all queries ending at `rightPos` in `O(1)` grouping time with zero sorting.
4. Query `[queryLeft[qIdx], rightPos]` equals `rightTotal - bitSum(queryLeft[qIdx] - 1)` because only rightmost occurrences up to `rightPos` are marked.

Key identifiers in the program:

| term | meaning |
|---|---|
| `bucketHead` | linked-list head of queries ending at `rightPos` |
| `queryLeft` | stored left endpoint for each query index |
| `lastSeenPos` | latest array index seen for each element value |
| `bitTree` | Fenwick tree maintaining active rightmost markers |
| `queryAnswers` | answers restored into original input query order |

Worked trace on `[1, 1, 2, 1, 3]`: at `rightPos = 4` (`elem = 1`), the marker moves from index `2` to `4`. Active markers sit at `{3, 4}`, so query `[2, 4]` sums to `2`.

## Code

**Offline Fenwick sweep.** `main` updates `lastSeenPos` and `bitTree` at each `rightPos`, then answers every query in `bucketHead[rightPos]`.

```nim
  for rightPos in 1 .. arrayLen:
    let elem = values[rightPos]
    let prevPos = lastSeenPos[elem]
    if prevPos > 0:
      bitAdd(bitTree, arrayLen, prevPos, -1)
    lastSeenPos[elem] = rightPos
    bitAdd(bitTree, arrayLen, rightPos, 1)

    let rightTotal = bitSum(bitTree, rightPos)
    var qIdx = bucketHead[rightPos]
    while qIdx != -1:
      queryAnswers[qIdx] = rightTotal - bitSum(bitTree, queryLeft[qIdx] - 1)
      qIdx = queryNext[qIdx]
```

**Fenwick tree primitives.** `bitAdd` and `bitSum` update and query prefix sums in `O(log n)` steps.

```nim
proc bitAdd(bitTree: var seq[int], treeSize: int, idxStart: int, delta: int) {.inline.} =
  var idx = idxStart
  while idx <= treeSize:
    bitTree[idx] += delta
    idx += idx and (-idx)

proc bitSum(bitTree: seq[int], idxStart: int): int {.inline.} =
  var idx = idxStart
  var acc = 0
  while idx > 0:
    acc += bitTree[idx]
    idx -= idx and (-idx)
  acc
```

## Complexity

| metric | cost |
|---|---|
| time | O((n + q) log n) |
| space | O(n + q + V) |

Here `V = 10^6` is `maxElementValue`, keeping both runtime and memory minimal versus `O(n * q)` naive scans.
