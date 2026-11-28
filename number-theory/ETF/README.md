# ETF — Euler Totient Function (SPOJ)

<https://www.spoj.com/problems/ETF/>

## Problem

Compute Euler's totient function `phi(n)`—the count of positive integers up to `n` coprime to `n`—for `T` queried values.

Input starts with `T`, followed by `T` integers `n`. Output prints one `phi(n)` value per line.

Constraints and limits for the task:

| item | bound |
|---|---|
| queries `T` | up to `20000` |
| query integer `n` | `1 <= n <= 10^6` |
| judge limit | 1000 ms, 1536 MB |

Factoring every `n` from scratch `20,000` times repeats work up to `10^6` and risks timing out.

Sample input and output:

```
5
1
2
3
4
5
```

```
1
1
2
2
4
```

Integers `{1, 3}` are coprime to `4`, giving `phi(4) = 2`.

## Idea

Fill an entire totient sieve (`phi`) once like stamping discount rates onto a price catalog, then answer every query by array lookup. Whenever an untouched prime `prime` satisfies `phi[prime] == prime`, multiply every multiple `mult` by `(prime - 1) / prime` via `phi[mult] -= phi[mult] div int32(prime)`.

Precomputing up to `10^6` costs `O(M log log M)` time (`4 MB` of `int32`), after which each of the `20,000` queries takes `O(1)`. Trial-dividing `20,000` times would do up to `2 * 10^7` divisions.

One sieve pass before reading queries keeps total runtime tiny inside `1000 ms`.

## Why It Works

1. By Euler's product formula, `phi(n) = n * prod_{p | n} (1 - 1 / p)`.
2. Initializing `phi[idx] = idx` starts every entry with factor `n`.
3. Visiting integers `prime >= 2` in ascending order hits `phi[prime] == prime` if and only if `prime` has no smaller prime divisor, hence `prime` is prime.
4. Subtracting `phi[mult] div int32(prime)` multiplies `phi[mult]` by `(1 - 1 / prime)` exactly once per prime factor `prime`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `maxQueryLimit` | sieve upper bound `1000000` |
| `phi` | `int32` sieve storing `phi(n)` for `1 .. 10^6` |
| `prime` | discovered prime dividing untouched entries |
| `mult` | multiples of `prime` updated inside the sieve |

Worked trace for `n = 6`: `phi[6]` starts at `6`. Prime `2` reduces it to `3`, and prime `3` reduces `3` to `2`.

## Code

**Euler totient sieve and O(1) lookup.** `main` populates `phi` once up to `maxQueryLimit` and streams every answer directly.

```nim
  var phi = newSeq[int32](maxQueryLimit + 1)
  for idx in 1 .. maxQueryLimit:
    phi[idx] = int32(idx)
  for prime in 2 .. maxQueryLimit:
    if phi[prime] == int32(prime):
      var mult = prime
      while mult <= maxQueryLimit:
        phi[mult] -= phi[mult] div int32(prime)
        mult += prime

  let inputData = readInputBytes()
  var scanPos = 0
  let caseCount = nextInt(inputData, scanPos)
  for caseIdx in 0 ..< caseCount:
    let targetVal = nextInt(inputData, scanPos)
    appendIntLine(int(phi[targetVal]))
```

## Complexity

| metric | cost |
|---|---|
| time | O(M log log M + T) |
| space | O(M) |

With `M = 10^6`, precomputation runs once in `~10 ms` and serves `T` queries in constant time per query.
