# NUMTH02 — Worst Mango (SPOJ)

<https://www.spoj.com/problems/NUMTH02/>

## Problem

Count buckets as a power, share them among rooms, and report the leftovers. Then share the total mangoes among those leftover buckets and report the mango leftovers.

Input begins with three integers `b`, `n`, and `r`. The next line holds the partition count `p`. The following `p` lines each hold one mango amount `xi`.

Output holds two numbers on one line: the extra buckets and the extra mangoes.

| item | bound |
|---|---|
| base b and exponent n | 1 to 10^6 |
| rooms r | 1 to 5000 |
| partitions p | 1 to 50 |
| each amount xi | 1 to 10^18 |
| judge limit | 500 ms, 1536 MB |

The exponent makes the raw bucket count far too large to store, so the remainder is computed directly.

Sample input:

```
2 3 5
3
2
4
4
```

Sample output:

```
3 1
```

## Idea

Find the remainder of a huge power by repeated squaring, like folding a long rope in half again and again. Reduce the mango total at each addition so the running sum stays small.

Modular exponentiation halves the exponent on every loop, so it costs logarithmic steps. The mango amounts are summed modulo the bucket remainder, which avoids ever holding the full total. Each step uses only one 64-bit value.

Shrink the power first, then reduce the mango sum with it.

## Why It Works

1. The number of buckets equals `b` raised to `n`, written as `b^n` in the note.
2. Equal sharing among `r` rooms leaves `b^n mod r` spare buckets.
3. Repeated squaring preserves the remainder after every multiplication.
4. The mango remainder equals the sum of all amounts modulo the spare buckets.
5. Reducing each amount before adding keeps every intermediate inside 64 bits.

| term | meaning |
|---|---|
| `bucketBase` | the base of the bucket power |
| `bucketExponent` | the exponent of the bucket power |
| `powerResult` | running remainder of the bucket power |
| `extraBuckets` | spare buckets after room sharing |
| `mangoRemainder` | spare mangoes after bucket sharing |

The note traces `2^3 = 8`, `8 mod 5 = 3`, and `(2+4+4) mod 3 = 1`. The sample answer is therefore `3 1`.

The code prints `0 0` when the room count divides the power exactly.

## Code

**Buffered scanner.** `Scanner` refills a 64 KiB buffer with `fread` and parses unsigned 64-bit integers directly.

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

All inputs are non-negative, so `nextNumber` needs no sign branch.
Reading 64 KiB chunks keeps input syscalls minimal.
Unsigned 64-bit arithmetic holds amounts up to 10^18 directly.

**Modular power and mango remainder.** Binary exponentiation computes `extraBuckets`, then one pass reduces all mango amounts modulo `extraBuckets`.

```cpp
int main() {
  u64 bucketBase = scanner.nextNumber();
  u64 bucketExponent = scanner.nextNumber();
  u64 roomCount = scanner.nextNumber();
  u64 powerBase = bucketBase % roomCount;
  u64 powerResult = 1 % roomCount;
  u64 exponentCursor = bucketExponent;
  while (exponentCursor > 0) {
    if ((exponentCursor & 1ULL) != 0) powerResult = (powerResult * powerBase) % roomCount;
    powerBase = (powerBase * powerBase) % roomCount;
    exponentCursor >>= 1;
  }
  u64 extraBuckets = powerResult;
  u64 mangoRemainder = 0;
  if (extraBuckets > 0) {
    u64 partitionCount = scanner.nextNumber();
    for (u64 partitionIndex = 0; partitionIndex < partitionCount; partitionIndex++) {
      u64 mangoAmount = scanner.nextNumber();
      mangoRemainder = (mangoRemainder + mangoAmount % extraBuckets) % extraBuckets;
    }
  }
  char line[32];
  int lineLength = 0;
  char scratch[24];
  int scratchLength = 0;
  u64 value = extraBuckets;
  if (value == 0) scratch[scratchLength++] = '0';
  while (value > 0) { scratch[scratchLength++] = (char)('0' + (value % 10ULL)); value /= 10ULL; }
  while (scratchLength > 0) line[lineLength++] = scratch[--scratchLength];
  line[lineLength++] = ' ';
  scratchLength = 0;
  value = mangoRemainder;
  if (value == 0) scratch[scratchLength++] = '0';
  while (value > 0) { scratch[scratchLength++] = (char)('0' + (value % 10ULL)); value /= 10ULL; }
  while (scratchLength > 0) line[lineLength++] = scratch[--scratchLength];
  line[lineLength++] = '\n';
  fwrite(line, 1, (size_t)lineLength, stdout);
  return 0;
}
```

`roomCount` is at most 5000, so squaring modulo `roomCount` never overflows.
The `extraBuckets > 0` guard prevents division by zero when `r` divides `b^n`.
One `fwrite` call emits both formatted remainders.

## Complexity

The power loop follows the exponent bits, and the mango loop follows the partitions.

| phase | time | space |
|---|---|---|
| input read | one pass over the tokens | one input string |
| modular power | one squaring per exponent bit | three integers |
| mango sum | one reduction per partition | one accumulator |
| output | one line | block buffer |

The exponent drives the power loop and p drives the mango loop.

| measure | Big O |
|---|---|
| time | O(log n + p) |
| space | O(1) beyond the input string |

Building `b^n` as a full integer would need n multiplication steps and enormous memory.

Reduce the power early, reduce each mango amount early, and print both remainders.
