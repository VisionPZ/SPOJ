# LASTDIG — The Last Digit (SPOJ)

<https://www.spoj.com/problems/LASTDIG/>

## Problem

Given a base `a` and a huge exponent `b` (not both zero), find the units digit of `a^b`.

Input starts with `t`, followed by `t` pairs `(a, b)`. Output prints one digit `0 .. 9` per test case.

Constraints and limits for the task:

| item | bound |
|---|---|
| test cases `t` | up to `30` |
| base `a` | `0` to `20` |
| exponent `b` | `0` to `2147483000` |
| source limit | `700B` |
| judge limit | 1000 ms, 1536 MB |

Multiplying `a` up to two billion times would exceed the one-second limit, and the tight 700-byte source limit requires concise code.

Sample input and output:

```
2
3 10
6 2
```

```
9
6
```

`3^10 = 59049` ends in `9`, and `6^2 = 36` ends in `6`.

## Idea

Use the repeating four-step cycle of units digits under multiplication, like reading hours off a clock after skipping full revolutions. Because every digit `base` repeats its power pattern with period dividing `4` for positive exponents, raising `base` to `((expVal - 1) mod 4) + 1` matches `a^b mod 10` exactly.

Evaluating at most four modular multiplications per case takes `O(1)` time and keeps `solution.nim` well under the 700-byte limit. Direct looping up to `2.1 * 10^9` fails on time.

Handling `expVal == 0` separately outputs `1` directly while reducing positive exponents into `1 .. 4`.

## Why It Works

1. Last digits satisfy `(x * y) mod 10 = ((x mod 10) * y) mod 10`, so only `base = a mod 10` matters.
2. When `expVal == 0` and `a != 0`, `a^0 = 1`.
3. For any digit `d` and positive `k`, `d^(k + 4) == d^k (mod 10)`. This holds because `10` always divides `d^5 - d`.
4. Shifting `expVal >= 1` via `((expVal - 1) mod 4) + 1` maps every positive exponent into `1 .. 4` while preserving its residue modulo `4`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `base` | units digit `a mod 10` |
| `expVal` | exponent `b` |
| `ans` | final units digit of `a^b` |

Worked trace on `3 10`: `((10 - 1) mod 4) + 1 = 2`, and `3^2 mod 10 = 9`.

## Code

**Period-4 modular power.** Each test case runs at most four multiplications modulo `10` inside a compact buffered loop.

```nim
for i in 1 .. nextInt(text, pos):
  let base = nextInt(text, pos) mod 10
  let expVal = nextInt(text, pos)
  var ans = 1
  if expVal > 0:
    for step in 1 .. ((expVal - 1) mod 4) + 1: ans = (ans * base) mod 10
  res.add $ans & '\n'
stdout.write res
```

## Complexity

| metric | cost |
|---|---|
| time | O(t) |
| space | O(1) |

Each case performs constant arithmetic (`<= 4` multiplications) using a compact 700-byte-safe implementation.
