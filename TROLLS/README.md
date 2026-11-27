# TROLLS — Trolls (SPOJ)

<https://www.spoj.com/problems/TROLLS/>

## Problem

Four standalone C and Pascal programs from `trolls.zip` run simple loops on an imaginary supercomputer with arbitrarily large integers. Compute the exact final output of each program without executing slow loops directly.

Programs 1 and 2 ask for the total count of `*` characters printed. Programs 3 and 4 ask for the single integer printed on standard output.

Constraints and limits for the task:

| item | bound |
|---|---|
| input | none (fixed four source programs) |
| output | four integers, one per line |
| integer precision | arbitrary (up to 58 decimal digits) |
| judge limit | 100 ms, 1536 MB |

Executing the nested loops directly takes astronomically long for binomial enumeration and divisor search.

Sample fragments and outputs from the problem statement:

```
var i:integer; begin for i:=2 to 8 do write('*'); end.
```

```
7
```

```
var a,i:integer; begin a:=0; for i:=1 to 9 do a:=a*10+i; writeln(a); end.
```

```
123456789
```

The first fragment prints seven stars, and the second builds the nine-digit number `123456789`.

## Idea

Translate each troll program into an exact mathematical quantity or fast state-machine walk, like measuring the track length instead of walking a maze twice. Use `BigDigits` base-`10^9` arrays (`bigBase`) for exact huge integers and Floyd's tortoise-and-hare walk for the sliding ring.

Computing `C(300, 50)` takes 50 multiplications and divisions, and cycle finding finishes in `1104928` small ring updates. Counting factorials modulo 13 stops once `fact` reaches `0` at `13!`. Factoring `7777 = 7 * 11 * 101` directly builds the smallest number with 7777 divisors.

Combining four tiny analytical solvers runs all answers well below 100 ms.

## Why It Works

1. Program 1 recursively picks 50 strictly increasing values from `1 .. 300`. It prints one `*` per combination, which totals `C(300, 50)`.
2. Program 2 tracks an 11-element sliding state `RingState`. Whenever the fast walker matches the slow walker, the slow walker steps once and resets the fast walker. Thus every outer step advances the slow pointer one unique state until it enters and finishes the loop, totaling `tailLen + cycleLen` stars.
3. Program 3 increments a factorial-radix counter `A` and a base-13 counter `B` together until `A[1000]` becomes positive. Whenever a new highest digit `j` turns positive at `(j + 1)!` steps, `m` adds `steps mod 13`. That sums `x! mod 13` for `1 <= x <= 12`.
4. Program 4 wraps standard arithmetic inside small helpers: `foo(a, b) = max(0, a - b)`, `goo(a, b) = max(a, b)`, and `boo(a, b) = min(a, b)`.
5. Inside `moo(a, b)`, condition `j = 0` locates `r = gcd(a, b)`. Checking `boo(r, b) = a - foo(a, b)` tests `gcd(a, b) = min(a, b)`, so `b` divides `a`.
6. Thus `soo(a)` counts divisors of `a`. Factoring `7777 = 7 * 11 * 101` and putting the largest exponents on the smallest primes gives `2^100 * 3^10 * 5^6`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `bigBase` | base `10^9` used in `BigDigits` arithmetic |
| `RingState` | 11-element state array for Program 2 |
| `stepRing` | single transition `(state[10] + state[0] div 3) mod 1001` |
| `tailLen` | pre-period length (`590473`) found by Floyd's algorithm |
| `cycleLen` | cycle length (`514455`) found by Floyd's algorithm |
| `modBase` | modulus `13` where factorials vanish from `13!` onward |

Worked check on small target `12 = 2 * 2 * 3`: sorting prime exponents descending yields `2^2 * 3^1 * 5^1 = 60`. That product has `(2 + 1)(1 + 1)(1 + 1) = 12` divisors and beats `2^11 = 2048`.

## Code

**Arbitrary-precision binomial calculation.** `solveProgram1` computes `C(300, 50)` exact in base `10^9` using `mulSmall` and `divSmall`.

```nim
proc mulSmall(digits: var BigDigits, factor: uint64) =
  var carry = 0'u64
  for idx in 0 ..< digits.len:
    let prod = uint64(digits[idx]) * factor + carry
    digits[idx] = uint32(prod mod bigBase)
    carry = prod div bigBase
  if carry > 0'u64:
    digits.add uint32(carry)

proc divSmall(digits: var BigDigits, divisor: uint64) =
  var rem = 0'u64
  for idx in countdown(digits.len - 1, 0):
    let cur = rem * bigBase + uint64(digits[idx])
    digits[idx] = uint32(cur div divisor)
    rem = cur mod divisor
  while digits.len > 1 and digits[^1] == 0'u32:
    digits.setLen(digits.len - 1)
```

```nim
proc solveProgram1(): string =
  var digits: BigDigits = @[1'u32]
  for step in 1'u64 .. 50'u64:
    digits.mulSmall(301'u64 - step)
    digits.divSmall(step)
  bigToStr(digits)
```

**Floyd cycle finder and closed forms.** `solveProgram2` counts distinct rho-path states while `solveProgram3` and `solveProgram4` evaluate the remaining two closed forms.

```nim
proc stepRing(state: var RingState) {.inline.} =
  let nxt = uint16((uint32(state[10]) + uint32(state[0]) div 3'u32) mod 1001'u32)
  for idx in 0 .. 9:
    state[idx] = state[idx + 1]
  state[10] = nxt

proc solveProgram2(): int =
  var initial: RingState
  for idx in 0 .. 10:
    initial[idx] = uint16(idx)
  var tortoise = initial
  var hare = initial
  stepRing(tortoise)
  stepRing(hare)
  stepRing(hare)
  while tortoise != hare:
    stepRing(tortoise)
    stepRing(hare)
    stepRing(hare)
  var tailLen = 0
  tortoise = initial
  while tortoise != hare:
    stepRing(tortoise)
    stepRing(hare)
    tailLen += 1
  var cycleLen = 1
  hare = tortoise
  stepRing(hare)
  while tortoise != hare:
    stepRing(hare)
    cycleLen += 1
  tailLen + cycleLen
```

```nim
proc solveProgram3(): int =
  const modBase = 13
  var total = 0
  var fact = 1
  for term in 1 .. 1001:
    fact = (fact * term) mod modBase
    if fact == 0:
      break
    total += fact
  total

proc solveProgram4(): string =
  var digits: BigDigits = @[1'u32]
  for power in 1 .. 100:
    digits.mulSmall(2'u64)
  for power in 1 .. 10:
    digits.mulSmall(3'u64)
  for power in 1 .. 6:
    digits.mulSmall(5'u64)
  bigToStr(digits)
```

## Complexity

| metric | cost |
|---|---|
| time | O(L + mu + lambda) |
| space | O(L) |

Here `mu` is `tailLen` (`590473`), `lambda` is `cycleLen` (`514455`), and `L <= 7` is the base-`10^9` limb length for the big-integer results.
