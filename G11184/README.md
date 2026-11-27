# G11184 — Jolly Grado 11 (SPOJ)

<https://www.spoj.com/problems/G11184/>

## Problem

A sequence of `n` integers is a jolly jumper when the absolute differences between consecutive elements cover every integer from `1` through `n - 1`. Decide each sequence until `n = 0` ends input.

Input holds one sequence per line starting with `n`, followed by `n` signed integers, ending at `0`. Print `Jolly` or `Not jolly` per sequence.

Constraints and limits for the task:

| item | bound |
|---|---|
| sequence length `n` | 1 to 2999 |
| sequence elements | signed 64-bit integers |
| judge languages | C, C++, Java, Python 3 (no Nim) |
| judge limit | 1000 ms, 1536 MB |

Sorting neighbor differences costs `O(n log n)`, whereas direct boolean marking runs in linear time.

Sample input and output:

```
4 1 4 2 3
5 1 4 2 -1 6
0
```

```
Jolly
Not jolly
```

The first sequence produces differences `3, 2, 1`, while the second repeats `3` and misses `1`.

## Idea

Check off each adjacent gap in a flat marker array `seenDifferences`, like ticking attendance numbers on a checklist from `1` to `n - 1`. Any gap outside `[1, caseLength - 1]` or seen twice disqualifies the sequence immediately.

Marking adjacent differences and clearing only `1 .. caseLength - 1` runs in `O(n)` time per sequence. Implementing the parser in C++14 compiles natively on SPOJ and computes unsigned 64-bit differences without signed subtraction overflow.

Reusing one resizable vector across all cases keeps memory flat and fast.

## Why It Works

1. A sequence of length `1` has zero adjacent pairs, leaving `distinctCount == 0 == caseLength - 1`, so `Jolly` is returned automatically.
2. Unsigned difference `static_cast<uint64_t>(cur) - static_cast<uint64_t>(prev)` avoids signed overflow even at extreme 64-bit values.
3. Because there are `caseLength - 1` adjacent pairs, `distinctCount == caseLength - 1` holds if and only if every value `1 .. caseLength - 1` appeared once.
4. Clearing only `seenDifferences[1 .. caseLength - 1]` leaves every slot ready for the next sequence without reallocating.

Key identifiers in the program:

| term | meaning |
|---|---|
| `caseLength` | element count `n` for the current test case |
| `sequenceValues` | buffer holding the current sequence values |
| `seenDifferences` | marker table tracking seen step distances |
| `distinctCount` | number of distinct valid step distances found |
| `isJolly` | boolean verdict for the current case |

Worked trace on sample `5 1 4 2 -1 6`: step distances are `3, 2, 3, 7`; repeated `3` and out-of-range `7` keep `distinctCount` at `2 != 4`, yielding `Not jolly`.

## Code

**Linear difference checker.** `main` computes unsigned neighbor distances and resets only the entries needed by the current length.

```cpp
    bool isJolly = true;
    int distinctCount = 0;
    for (int idx = 0; idx + 1 < caseLength; idx++) {
      long long cur = sequenceValues[idx + 1];
      long long prev = sequenceValues[idx];
      unsigned long long diff = cur >= prev
          ? static_cast<unsigned long long>(cur) - static_cast<unsigned long long>(prev)
          : static_cast<unsigned long long>(prev) - static_cast<unsigned long long>(cur);
      if (diff == 0 || diff >= static_cast<unsigned long long>(caseLength) ||
          seenDifferences[static_cast<size_t>(diff)]) {
        isJolly = false;
      } else {
        seenDifferences[static_cast<size_t>(diff)] = 1;
        distinctCount++;
      }
    }
    if (distinctCount != caseLength - 1) {
      isJolly = false;
    }
    appendLiteral(outputBuffer, isJolly ? "Jolly\n" : "Not jolly\n");
    for (int diffIdx = 1; diffIdx < caseLength; diffIdx++) {
      seenDifferences[diffIdx] = 0;
    }
```

## Complexity

| metric | cost |
|---|---|
| time | O(N) |
| space | O(max n) |

Summing over `N` total sequence integers across all cases runs linearly with memory bounded by the longest sequence.
