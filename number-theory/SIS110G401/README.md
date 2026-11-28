# SIS110G401 — Suma de Numeros (SPOJ)

<https://www.spoj.com/problems/SIS110G401/>

## Problem

The input holds pairs of integers, one pair per line: a count for the left hand and a count for the right hand. Add the two counts and print one sum per line, reading pairs up to end of input.

There is no test count and no terminator value. Every complete pair produces one output line.

| item | bound |
|---|---|
| input form | pairs of integers, one pair per line |
| pair count | until end of input |
| judge limit | 1000 ms, 1536 MB |

The input can hold more than one pair, so the program must keep reading to EOF.

Sample input:

```
4 4
3 4
```

Sample output:

```
8
7
```

Each line adds its own pair, giving 8 and then 7.

## Idea

Treat each pair like two hands of counters and combine them into one pile. Read every integer in order, pair the values, and add them.

The algorithm is a linear scan with a hand-written integer reader and a block output buffer. Each pair costs one addition and one formatted write. Flushing after every line would issue many small writes, so the buffer flushes only when it grows large.

## Why It Works

1. Consecutive integers form one pair because the input is written pair by pair.
2. Scanning to EOF handles any number of pairs without a count.
3. Widening each value to int64 keeps large sums exact.
4. A block buffer reduces writes while preserving line order.

| term | meaning |
|---|---|
| `buffer` | 64 KiB read buffer filled by `fread` |
| `position` | current byte cursor inside `buffer` |
| `leftHand` | first integer of the current pair |
| `rightHand` | second integer of the current pair |
| `outputBuffer` | 128 KiB buffer for pending answer lines |

The scanner skips spaces and line breaks, so extra whitespace is harmless.

The sample trace from the generator is:

```
pair 4 4 -> 4 + 4 = 8
pair 3 4 -> 3 + 4 = 7
output lines: 8, 7
```

The trace reproduces the sample output exactly.

## Code

**Buffered scanner.** `Scanner` refills a 64 KiB buffer with `fread` and returns false at EOF.

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
  bool nextNumber(u64 &value) {
    int c = get();
    while (c != -1 && (c < '0' || c > '9')) c = get();
    if (c == -1) return false;
    value = 0;
    while (c >= '0' && c <= '9') {
      value = value * 10ULL + (u64)(c - '0');
      c = get();
    }
    return true;
  }
} scanner;
```

`nextNumber` skips non-digit bytes and stops cleanly at EOF.
Reading in 64 KiB blocks avoids per-line syscalls.
Unsigned 64-bit parsing keeps large sums exact.

**Pair loop and block output.** Each pair is summed, formatted into `outputBuffer`, and flushed every 64 KiB.

```cpp
int main() {
  static char outputBuffer[1 << 17];
  int outputLength = 0;
  u64 leftHand, rightHand;
  while (scanner.nextNumber(leftHand)) {
    if (!scanner.nextNumber(rightHand)) break;
    u64 sum = leftHand + rightHand;
    char scratch[24];
    int scratchLength = 0;
    if (sum == 0) scratch[scratchLength++] = '0';
    while (sum > 0) {
      scratch[scratchLength++] = (char)('0' + (sum % 10ULL));
      sum /= 10ULL;
    }
    while (scratchLength > 0) {
      outputBuffer[outputLength++] = scratch[--scratchLength];
      if (outputLength >= (1 << 16)) {
        fwrite(outputBuffer, 1, (size_t)outputLength, stdout);
        outputLength = 0;
      }
    }
    outputBuffer[outputLength++] = '\n';
    if (outputLength >= (1 << 16)) {
      fwrite(outputBuffer, 1, (size_t)outputLength, stdout);
      outputLength = 0;
    }
  }
  fwrite(outputBuffer, 1, (size_t)outputLength, stdout);
  return 0;
}
```

The second `nextNumber` check guards against an incomplete trailing pair.
Digits are reversed through `scratch` straight into `outputBuffer`.
The final `fwrite` flushes all remaining buffered lines.

## Complexity

The work splits into reading, pairing, and writing.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| parse and add | one pass over integers | constant working space |
| output | one formatted line per pair | block buffer |

All phases are linear in the input size.

| measure | Big O |
|---|---|
| time | O(total input bytes) |
| space | O(total input bytes) for the input string |

Reading and writing line by line with an immediate flush would add many system calls. Scan once, buffer answers, then write in blocks.
