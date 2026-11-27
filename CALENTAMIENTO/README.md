# CALENTAMIENTO — La tarea (SPOJ)

<https://www.spoj.com/problems/CALENTAMIENTO/>

## Problem

Given a list of `n` non-negative integers, choose one integer step `x` and either add `x`, subtract `x`, or leave each entry unchanged so every entry reaches the same value. Print `Si` if such an `x` exists, otherwise `No`.

Input starts with `n`, followed by `n` integers on the next line. Output prints `Si` or `No` matching the sample output format.

Constraints and limits for the task:

| item | bound |
|---|---|
| entries `n` | `1 <= n <= 100000` |
| entry value | `0 <= a_i <= 10^9` |
| judge languages | C, C++, C++14, Java, Python 3 (no Nim) |
| judge limit | 1000 ms, 1536 MB |

Checking distinct value spacing solves the array in `O(n)` without sorting all entries.

Sample input and output:

```
5
1 3 3 2 1
```

```
Si
```

Choosing `x = 1` adjusts every `1`, `2`, and `3` to `2`.

## Idea

Slide distinct numbers along a ruler by one shared step `x`, like lining up three shelves around a middle mark. Any valid list has at most three distinct values forming an arithmetic progression.

Collect up to four distinct numbers during a single scan of the input array. If two or fewer distinct values exist, any gap works; if three exist, sort the three and check equal spacing (`min + max == 2 * mid`).

C++14 runs cleanly on SPOJ in `O(n)` time and `O(1)` extra space.

## Why It Works

1. If all elements end at value `V`, every starting number must equal `V - x`, `V`, or `V + x`.
2. Four or more distinct numbers require more than three levels, which is impossible with one step `x`.
3. With one or two distinct numbers, choosing `x = 0` or `x = max - min` aligns all entries at once.
4. With three sorted values `v0 < v1 < v2`, `v0 + v2 == 2 * v1` ensures `V = v1` and `x = v1 - v0` balance both ends.

Key identifiers in the program:

| term | meaning |
|---|---|
| `elementCount` | total entries `n` in the array |
| `distinctValues` | fixed array capturing up to four distinct numbers |
| `distinctCount` | count of distinct numbers seen so far (`0 .. 4`) |
| `canEqualize` | boolean decision emitted as `Si` or `No` |

Worked trace on `1 3 3 2 1`: `distinctValues` collects `{1, 3, 2}`, sorting yields `{1, 2, 3}`, and `1 + 3 == 2 * 2` confirms `Si`.

## Code

**Distinct-level filter.** `main` scans `elementCount` numbers while storing at most four distinct values.

```cpp
  for (int64_t idx = 0; idx < elementCount; idx++) {
    int64_t currentValue = nextInt64(inputData, scanPos);
    bool alreadySeen = false;
    for (int slot = 0; slot < distinctCount; slot++) {
      if (distinctValues[slot] == currentValue) {
        alreadySeen = true;
        break;
      }
    }
    if (!alreadySeen && distinctCount < 4) {
      distinctValues[distinctCount] = currentValue;
      distinctCount++;
    }
  }
```

**Spacing decision.** Only two or fewer distinct levels or three equally spaced levels pass.

```cpp
  bool canEqualize = false;
  if (distinctCount <= 2) {
    canEqualize = true;
  } else if (distinctCount == 3) {
    std::sort(distinctValues, distinctValues + 3);
    canEqualize = (distinctValues[0] + distinctValues[2] == 2 * distinctValues[1]);
  }
```

## Complexity

| metric | cost |
|---|---|
| time | O(n) |
| space | O(1) |

Scanning all `n` integers performs at most four equality checks per entry using fixed `O(1)` state.
