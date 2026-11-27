# SDF4G — Praktikum 4 SDF G (SPOJ)

<https://www.spoj.com/problems/SDF4G/>

## Problem

List every non-negative integer up to `n` whose adjacent decimal digits differ by exact value `1`, sorted in ascending order. Follow each printed integer with a space, then end the first line and print `AilafyuU` on the second line.

All single-digit integers from `0` to `9` satisfy this jumping-number property trivially because they have no adjacent digit pairs.

Constraints and limits for the task:

| item | bound |
|---|---|
| upper bound `n` | unbounded unsigned 128-bit (`u128`), tested up to `10^11` |
| output format | space-terminated numbers (`0 ... \n`), then `AilafyuU` |
| negative `n` | empty first line, then `AilafyuU` |
| judge languages | C++, PyPy 3, C#, Julia (no Nim) |
| judge limit | 1000 ms, 1536 MB |

Scanning every integer from `0` to `n` spends almost all work rejecting non-jumping numbers when `n` reaches billions or larger.

Sample input and output:

```
15
```

```
0 1 2 3 4 5 6 7 8 9 10 12 
AilafyuU
```

Up to `15`, single digits `0 .. 9` come first, then `10` and `12`, while `11`, `13`, `14`, and `15` fail the unit-difference rule.

## Idea

Generate only valid numbers directly from shorter prefixes using breadth-first search (`queue`), like growing branches of a digit tree one level at a time. Because every pop yields the smallest unexpanded prefix, appending `lastDigit - 1` before `lastDigit + 1` emits answers already sorted.

If `K` valid jumping numbers are at most `n`, generating them takes `O(K)` work instead of checking all `n` integers. Using unsigned 128-bit `u128` handles bounds past 64 bits cleanly, and emitting a trailing space after every number matches the live SPOJ judge checker.

Expanding by digit length with buffered writes (`flushBlockBytes`) skips sorting completely and keeps output overhead minimal.

## Why It Works

1. When `isNegative` is true, there are no non-negative jumping numbers, so only `\nAilafyuU\n` is written.
2. Otherwise `0 ` is emitted first because `0` cannot prepend positive digits without creating leading zeros.
3. `queue` starts with `1 .. min(9, limitVal)` in increasing order, covering all positive single-digit jumping numbers.
4. Popping `cur` guarantees all shorter jumping numbers and all same-length prefixes smaller than `cur` have already been processed, letting `lastDigit = cur % 10` extend by `lastDigit - 1` when positive and `lastDigit + 1` when below `9`.
5. Checking `cur <= (limitVal - lowDigit) / 10` and `cur <= (limitVal - highDigit) / 10` avoids overflow even near `u128` limits.

Key identifiers in the program:

| term | meaning |
|---|---|
| `limitVal` | parsed upper limit `n` as `u128` |
| `queue` | FIFO list storing valid jumping numbers |
| `head` | index of the next prefix to print and expand |
| `lastDigit` | ones digit `cur % 10` controlling valid suffixes |
| `flushBlockBytes` | 128 KiB output buffer threshold |

Worked trace on sample `n = 15`: queue pops `1` (`lastDigit = 1`), pushes `10` and `12`. Next pops `2 .. 9` fail child bounds above `15`, emitting `0 1 2 3 4 5 6 7 8 9 10 12 \nAilafyuU`.

## Code

**Buffered integer writer.** `appendU128` formats each `u128` followed by `' '` directly into `outBuf` and flushes once `flushBlockBytes` is reached.

```cpp
static void appendU128(std::string &outBuf, u128 value) {
  char digits[48];
  int len = 0;
  if (value == 0) {
    digits[len++] = '0';
  } else {
    while (value > 0) {
      digits[len++] = static_cast<char>('0' + static_cast<int>(value % 10));
      value /= 10;
    }
  }
  while (len > 0) {
    outBuf.push_back(digits[--len]);
  }
  outBuf.push_back(' ');
  if (static_cast<int>(outBuf.size()) >= flushBlockBytes) {
    std::fwrite(outBuf.data(), 1, outBuf.size(), stdout);
    outBuf.clear();
  }
}
```

**Breadth-first jumping generator.** `main` seeds single digits and emits children in ascending order without sorting.

```cpp
    if (limitVal >= 1) {
      std::vector<u128> queue;
      queue.reserve(65536);
      u128 firstTop = limitVal < 9 ? limitVal : 9;
      for (u128 digit = 1; digit <= firstTop; digit++) {
        queue.push_back(digit);
      }
      size_t head = 0;
      while (head < queue.size()) {
        u128 cur = queue[head++];
        appendU128(outBuf, cur);
        u128 lastDigit = cur % 10;
        if (lastDigit > 0) {
          u128 lowDigit = lastDigit - 1;
          if (cur <= (limitVal - lowDigit) / 10) {
            queue.push_back(cur * 10 + lowDigit);
          }
        }
        if (lastDigit < 9) {
          u128 highDigit = lastDigit + 1;
          if (cur <= (limitVal - highDigit) / 10) {
            queue.push_back(cur * 10 + highDigit);
          }
        }
      }
    }
```

## Complexity

| metric | cost |
|---|---|
| time | O(K) |
| space | O(K) |

Here `K` is the total count of jumping numbers at most `n`.
