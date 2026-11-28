# NUMTHEO01 — Mad Mod (SPOJ)

<https://www.spoj.com/problems/NUMTHEO01/>

## Problem

Report the remainder of a factorial divided by a given modulus. Each query gives the factorial index `n` and modulus `x`, and expects `n! mod x`.

Input starts with `t`, followed by `t` lines each holding two integers `n` and `x`. Output holds one remainder per line.

Constraints and limits for the task:

| item | bound |
|---|---|
| queries `t` | 1 to 15 |
| factorial index `n` | `< 8388700` |
| modulus `x` | `< 10^15` |
| judge languages | C, C++14, Java, Python 3 (no Nim) |
| judge limit | 4000 ms, 1536 MB |

Multiplying a 15-digit remainder directly inside signed 64-bit arithmetic overflows before the modulo step.

Sample input and output:

```
3
5 7
10 231
1 1
```

```
1
21
0
```

In the first query, `5! = 120` leaves remainder `1` modulo `7`.

## Idea

Reduce the running factorial after every multiplication using 128-bit arithmetic (`unsigned __int128`), like keeping only the remainder on a modulo odometer at every step. Exit immediately with `0` whenever `factorialLimit >= modulusValue` or `productValue` reaches `0`.

Each query takes at most `min(factorialLimit, modulusValue)` loop iterations with `O(1)` memory. Executing C++14 compiles natively on SPOJ while removing multi-factor 128-bit overflow hazards completely.

Short-circuiting when `factorialLimit >= modulusValue` also handles huge `n` modulo composite or large primes in constant time.

## Why It Works

1. If `modulusValue <= 1` or `factorialLimit >= modulusValue`, `modulusValue` itself divides `n!`, so the remainder is `0` at once.
2. Otherwise `productValue < modulusValue` holds at every iteration, and `factor <= factorialLimit` never exceeds `2^64`.
3. Casting `productValue` to `unsigned __int128` lets `productValue * factor` reach up to `2^128 - 1` cleanly without overflow.
4. Breaking immediately when `productValue == 0` skips useless trailing multiplications on composite moduli such as `231 = 3 * 7 * 11`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `factorialLimit` | factorial upper bound `n` |
| `modulusValue` | divisor `x` for modulo reduction |
| `productValue` | running value of `k! mod x` |
| `flushBlockBytes` | 128 KiB output buffer flush threshold |

Worked trace for sample query `10 231`: reducing step by step keeps remainders small (`6! = 720 -> 27`, `*7 -> 189`, `*8 -> 126`, `*9 -> 210`, `*10 -> 21`).

## Code

**Fast modular factorial loop.** `main` handles `factorialLimit >= modulusValue` in `O(1)` time and uses `unsigned __int128` per factor.

```cpp
    uint64_t factorialLimit = nextUInt64(inputData, scanPos);
    uint64_t modulusValue = nextUInt64(inputData, scanPos);
    if (modulusValue <= 1ULL || factorialLimit >= modulusValue) {
      appendUInt64(outputBuffer, 0ULL);
      continue;
    }
    uint64_t productValue = 1ULL;
    for (uint64_t factor = 2ULL; factor <= factorialLimit; factor++) {
      productValue = static_cast<uint64_t>(
          (static_cast<unsigned __int128>(productValue) * factor) % modulusValue);
      if (productValue == 0ULL) {
        break;
      }
    }
    appendUInt64(outputBuffer, productValue);
```

## Complexity

| metric | cost |
|---|---|
| time | O(t * min(n, x)) |
| space | O(1) |

Each of the `t` queries runs in linear time up to `min(n, x)` with constant extra memory.
