# WILLITST — Will it ever stop (SPOJ)

<https://www.spoj.com/problems/WILLITST/>

## Problem

Determine whether Bob's loop—halving even `n` and mapping odd `n` to `3 * n + 3` while `n > 1`—eventually terminates for a given starting value `n`.

Input consists of a single integer `n` up to `10^14`. Output prints `TAK` if it terminates, or `NIE` otherwise.

Constraints and limits for the task:

| item | bound |
|---|---|
| starting integer `n` | `1 <= n <= 10^14` |
| termination condition | reaches `n <= 1` |
| judge limit | 906 ms, 1536 MB |

Simulating odd trajectories blindly risks falling into endless loops if not detected via cycle checks.

Sample input and output:

```
4
```

```
TAK
```

Starting at `4` halves to `2` and then `1`, stopping the `while n > 1` loop.

## Idea

Test whether `startValue` is a pure power of two via `(startValue and (startValue - 1)) == 0`, like checking a single halving path down to `1`. Any odd number `>= 3` jumps to `3 * (n + 1)`, locking the value inside multiples of `3` forever.

Checking one bitwise `and` in `int64` decides in `O(1)` time and `O(1)` space without iterating or allocating cycle sets. Running the actual `while` loop requires storing visited states to catch cycles such as `3 -> 12 -> 6 -> 3`.

One bitwise check handles values up to `10^14` instantly.

## Why It Works

1. If `n = 2^k` (`k >= 0`), every step divides by `2` until reaching `1`, so the loop always stops (`TAK`).
2. If `n` is not a power of two, repeated halving strips powers of `2` until reaching some odd integer `m >= 3`.
3. Applying `3 * m + 3 = 3 * (m + 1)` produces an even multiple of `3`, and subsequent halvings remove factors of `2` while keeping divisibility by `3`.
4. Because `3` never divides `1`, `n` remains a positive multiple of `3` (`>= 3`) forever, preventing termination (`NIE`).

Key identifiers in the program:

| term | meaning |
|---|---|
| `startValue` | 64-bit starting integer `n` |
| `inputData` | full-stdin byte buffer |

Worked trace on `n = 6`: `6 and 5 = 4 != 0`, printing `NIE` (trajectory `6 -> 3 -> 12 -> 6` loops forever).

## Code

**Power-of-two bit test.** `main` tests whether `startValue` has at most one set bit in `int64`.

```nim
  let startValue = nextInt64(inputData, scanPos)
  if (startValue and (startValue - 1'i64)) == 0'i64:
    outBuffer.add "TAK\n"
  else:
    outBuffer.add "NIE\n"
```

## Complexity

| metric | cost |
|---|---|
| time | O(1) |
| space | O(1) |

Both runtime and memory are strict constants regardless of the 14-digit magnitude of `n`.
