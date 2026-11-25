# PON — Prime or Not (SPOJ)

<https://www.spoj.com/problems/PON/>

## Problem

A gate guard at the pyramid asks one question about every number that passes: is it prime? Five hundred numbers arrive in one batch, so each answer must come back fast. Print YES or NO for each number.

Input: `t`, the number of test cases, then `t` lines. Each line holds one integer `N`. Output: one line per case, `YES` when `N` is prime and `NO` otherwise.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `t` | at most 500 |
| Candidate `N` | 2 ≤ N ≤ 2^63 − 1 |
| Output | `YES` or `NO` per case |
| Judge limit | 21000 ms, 1536 MB |

`N` can hold 19 digits, so dividing by every smaller number cannot finish in time.

The sample input and output:

```
5
2
3
4
5
6
```

```
YES
YES
NO
YES
NO
```

## Idea

Probe a number with a few clever arithmetic questions instead of dividing by every smaller number. Think of a guard who recognizes a guest by asking a few secret questions, not by searching the whole guest list.

The program uses the Miller–Rabin primality test (a residue test made deterministic by fixed bases). Write `N − 1` as `d · 2^s` with `d` odd. For each base `a`, raise `a` to `d` modulo `N`, then square up to `s` times.

A prime always reaches 1 or `N − 1` in that chain. A composite fails for at least one of the twelve chosen bases. Modular multiplication uses double-and-add, and modular powers use exponentiation by squaring.

Cost per case: twelve bases, each with about 63 squaring steps of constant size. Trial division would try roughly √N candidates, about 3 × 10^9 divisions at the largest input.

A dozen fixed bases turn a slow search into a fast fingerprint check.

## Why It Works

Four facts carry the test.

1. Fermat's little theorem states that a prime `p` makes `a^(p−1) ≡ 1 (mod p)` whenever `gcd(a, p) = 1`.
2. Miller–Rabin refines this. Write `N − 1 = d · 2^s` with odd `d`. A prime makes `a^d` equal 1 or `N − 1`, or reach `N − 1` after squaring.
3. For every `N < 2^64`, the bases 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37 give a deterministic verdict.
4. Double-and-add keeps every intermediate product below 2^64, so unsigned 64-bit arithmetic never overflows.

The quantities the program computes:

| Term | Meaning |
|---|---|
| `d`, `s` | `N − 1` written as odd `d` times `2^s` |
| witness base `a` | one of the twelve fixed probes |
| `modMultiply` | product modulo `N` by repeated doubling |
| `modularPower` | `a^d mod N` by exponentiation by squaring |
| `witnessed` | the squaring chain reached `N − 1` |

The bases cover every 64-bit composite, so no random choice is needed.

A script-traced example with `N = 341`, a Carmichael number (a composite that fools the plain Fermat test):

```
N - 1 = 340 = 85 * 2^2, so d = 85 and s = 2
base 2: 2^85 mod 341 = 32; square -> 1; never 340 -> composite witness
base 3: 3^85 mod 341 = 254; square -> 67; never 340 -> composite witness
prime 13: 13 - 1 = 12 = 3 * 2^2; 2^3 mod 13 = 8; square -> 12 = 13 - 1 -> prime
```

Base 2 rejects 341, while the prime 13 passes. The squaring chain is where the test decides.

## Code

**Constants and scanner.** The input goes into one buffer, and the scanner walks it by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const witnessBases: array[12, uint64] = [2'u64, 3'u64, 5'u64, 7'u64, 11'u64, 13'u64,
                                         17'u64, 19'u64, 23'u64, 29'u64, 31'u64, 37'u64]

proc nextUint(data: string, i: var int): uint64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0'u64
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10'u64 + uint64(int(data[i]) - firstDigitValue)
    i += 1
  return value
```

`witnessBases` fixes the twelve probes once. `nextUint` skips separators and reads each unsigned value by index. The scanner costs one pass over the input bytes.

**Modular multiplication.** Doubling builds the product without overflow.

```nim
proc modMultiply(leftValue, rightValue, modulusValue: uint64): uint64 =
  var doubled = leftValue mod modulusValue
  var remaining = rightValue
  var product = 0'u64
  while remaining != 0'u64:
    if (remaining and 1'u64) != 0'u64:
      product = product + doubled
      if product >= modulusValue: product = product - modulusValue
    remaining = remaining shr 1
    doubled = doubled shl 1
    if doubled >= modulusValue: doubled = doubled - modulusValue
  return product
```

The loop runs once per bit of `rightValue`, at most 64 times. Each addition and doubling reduces modulo `modulusValue` at once. The `shl` and `shr` steps replace multiplication and division by two.

**Modular power.** Exponentiation by squaring raises a base to `oddPart`.

```nim
proc modularPower(baseValue, exponentValue, modulusValue: uint64): uint64 =
  var factor = baseValue mod modulusValue
  var power = 1'u64
  var exponent = exponentValue
  while exponent != 0'u64:
    if (exponent and 1'u64) != 0'u64:
      power = modMultiply(power, factor, modulusValue)
    factor = modMultiply(factor, factor, modulusValue)
    exponent = exponent shr 1
  return power
```

The loop runs once per bit of `exponentValue`. It squares the factor on every round and multiplies the power only on set bits. Each multiplication goes through `modMultiply`, so no intermediate value overflows.

**Primality test.** The small-base checks run first, then the Miller–Rabin chain.

```nim
proc isPrime(candidate: uint64): bool =
  if candidate < 2'u64: return false
  for primeBase in witnessBases:
    if candidate == primeBase: return true
    if candidate mod primeBase == 0'u64: return false
  var oddPart = candidate - 1'u64
  var twosCount = 0
  while (oddPart and 1'u64) == 0'u64:
    oddPart = oddPart shr 1
    twosCount += 1
  for primeBase in witnessBases:
    var term = modularPower(primeBase, oddPart, candidate)
    if term == 1'u64 or term == candidate - 1'u64: continue
    var witnessed = false
    var roundIndex = 1
    while roundIndex < twosCount:
      term = modMultiply(term, term, candidate)
      if term == candidate - 1'u64:
        witnessed = true
        break
      roundIndex += 1
    if not witnessed: return false
  return true
```

The first loop rejects exact base values and their multiples. The next loop splits `N − 1` into odd `oddPart` and `twosCount`. Each base passes on `1` or `N − 1`, or after repeated squaring. One failing base returns `false`.

**Input and driver.** One verdict per case, with block output.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = int(nextUint(inputData, i))
var outputBuffer = ""

var caseIndex = 0
while caseIndex < caseCount:
  let candidate = nextUint(inputData, i)
  if isPrime(candidate):
    outputBuffer.add "YES\n"
  else:
    outputBuffer.add "NO\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

stdout.write outputBuffer
```

`readLine` accumulates the whole stream before any test runs. The loop runs exactly `caseCount` times. Output flushes at 256 KiB, and the final write covers the tail.

## Complexity

Each case runs the same fixed chain of modular steps.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| `modMultiply` | at most 64 doubling steps | O(1) |
| `modularPower` | at most 63 squarings per base | O(1) |
| `isPrime` | twelve bases times that chain | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total, 500 cases | about 500 × 12 × 63 modular steps | O(1) |

The work stays constant per case, even at 500 cases.

| Measure | Big O |
|---|---|
| Time | O(1) per case for 64-bit inputs, O(T) for T cases |
| Space | O(1) per case, plus input and output buffers |

Fixed bases keep the cost independent of input size.

Trial division up to √N needs about 3 × 10^9 divisions at the largest candidate. These twelve bases need a few thousand modular steps.
