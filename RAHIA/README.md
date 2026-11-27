# RAHIA — Riyad And His Increasing Array (SPOJ)

<https://www.spoj.com/problems/RAHIA/>

## Problem

Decide whether an array can be made strictly increasing by repeatedly decreasing positive entries. Print YES when it can and NO otherwise.

The first line gives the element count. The next line holds the array values, each between 1 and 10^9. A decrease may be applied any number of times, but an entry can never go below zero.

| item | bound |
|---|---|
| element count | 1 to 100000 |
| each value | 1 to 10^9 |
| judge limit | 1000 ms, 1536 MB |

Entries may be left unchanged, so only decreases are available.

Sample input:

```
7
5 2 3 9 88 9 10
```

Sample output:

```
YES
```

## Idea

Think of filling N ordered slots with distinct whole numbers starting from zero. The smallest possible strictly increasing array is 0, 1, 2 and so on. Slot i therefore needs at least i, and every original value that meets this floor can be lowered to it.

The real algorithm checks each value against its zero-based index in one forward pass. Each element costs constant work. Trying every possible final value by brute force would be exponential. The takeaway is that the minimum increasing sequence gives a per-position floor.

## Why It Works

1. Decreasing an entry never raises it above its original value.
2. A strictly increasing array of non-negative integers has value at least i at index i.
3. If the original value at index i is below i, no sequence of decreases can reach that floor.
4. If every original value is at least its index, setting each value to its index works.
5. The resulting array is 0, 1, 2 and so on, which is strictly increasing.

| term | meaning |
|---|---|
| `elementCount` | number of array entries |
| `currentValue` | value read at the current index |
| `index` | zero-based position of the current entry |
| `possible` | false once any value falls below its index |

For the sample, the values at indices two and six are 3 and 10. Both meet their floors, so setting the array to 0 through 6 is valid and the answer is YES.

The lowest allowed final value is zero, which makes the floor exact.

## Code

**Buffered scanner.** `Scanner` reads 64 KiB blocks with `fread` and parses unsigned integers in place.

```cpp
#include <cstdio>
#include <cstddef>

typedef unsigned long long u64;

struct Scanner {
  static const int BufferSize = 1 << 16;
  char buffer[BufferSize];
  int position = 0;
  int length = 0;
  int get() {
    if (position >= length) {
      length = (int)fread(buffer, 1, BufferSize, stdin);
      position = 0;
      if (length == 0) return -1;
    }
    return buffer[position++];
  }
  u64 nextNumber() {
    int c = get();
    while (c != -1 && (c < '0' || c > '9')) c = get();
    u64 value = 0;
    while (c >= '0' && c <= '9') {
      value = value * 10ULL + (u64)(c - '0');
      c = get();
    }
    return value;
  }
} scanner;
```

Whitespace between values is skipped without allocations.
Each call to `nextNumber` advances `position` across one integer.
`BufferSize` caps memory at 64 KiB.

**Floor check.** Each entry is compared against its zero-based position.

```cpp
int main() {
  u64 elementCount = scanner.nextNumber();
  bool possible = true;
  for (u64 index = 0; index < elementCount; index++) {
    u64 currentValue = scanner.nextNumber();
    if (currentValue < index) possible = false;
  }
  if (possible) fwrite("YES\n", 1, 4, stdout);
  else fwrite("NO\n", 1, 3, stdout);
  return 0;
}
```

Unsigned 64-bit values handle entries up to 10^9 safely.
Any single violation clears `possible`.
One `fwrite` call emits the final answer.

## Complexity

The program reads the array once and checks one condition per element.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| floor check | constant work per element | constant extra space |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(1) beyond input and output |

Exploring all reachable arrays would take exponential time.
The index floor reduces the decision to one linear pass.
