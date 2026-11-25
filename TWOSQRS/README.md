# TWOSQRS — Two squares or not two squares (SPOJ)

<https://www.spoj.com/problems/TWOSQRS/>

## Problem

A number puzzle asks whether an integer can be written as the sum of two squares. Some values, like 17, have such a representation. Others, like 7, never do.

Input starts with `c ≤ 100`, the test count. Each following line holds one integer `n` with `0 ≤ n ≤ 10^12`. Output `Yes` or `No` on its own line for each value. Zero counts as a valid sum, since `0 = 0^2 + 0^2`, and both squares may be equal.

The bounds are compact.

| Quantity | Bound |
| --- | --- |
| Test cases `c` | at most 100 |
| Value `n` | 0 to 10^12 |
| Time limit | 2000 ms |
| Memory limit | 1536 MB |

The square root of the largest value is 10^6, which sets the sieve size.

The sample input and output follow verbatim.

```
10
1
2
7
14
49
9
17
76
2888
27
```

```
Yes
Yes
No
No
Yes
Yes
Yes
No
Yes
No
```

## Idea

Factor the value and inspect only primes of the form `4k + 3`. Think of a recipe check where one spice ruins the dish when it appears an odd number of times. Those primes must occur an even number of times; all other factors never block an answer.

A sieve builds every prime up to 10^6 once. Each test case trial-divides by those primes and counts exponents. Factoring one value costs at most one pass over the prime list, about 78498 divisions.

Testing every pair of squares up to `sqrt(n)` costs 10^6 steps per case. The factorization stops as soon as the prime square exceeds the remainder.

A single sieve plus exponent parity answers every case.

## Why It Works

Fermat's two-square theorem gives the rule. A positive integer is a sum of two squares exactly when each prime factor `4k + 3` has an even exponent.

The table lists each decision step.

| Term | Meaning |
| --- | --- |
| `remaining` | value left after dividing out found primes |
| `exponent` | times a prime divides the remaining value |
| `primeValue mod 4 == 3` | marks a blocking prime family |
| `exponent and 1` | tests whether that exponent is odd |
| leftover `remaining` | a prime factor larger than the sieve root |

The loop divides out each prime while its square stays at most `remaining`. It rejects a `3 mod 4` prime with an odd exponent. After the loop, any leftover value is prime, and it is rejected when it is `3 mod 4`. Zero passes because both squares may be zero.

Sample values show the parity test with visible numbers.

| Value | Relevant factor | Exponent | Answer |
| --- | --- | --- | --- |
| 1 | none | 0 | Yes |
| 7 | 7, which is 3 mod 4 | 1, odd | No |
| 14 | 7, which is 3 mod 4 | 1, odd | No |
| 49 | 7, which is 3 mod 4 | 2, even | Yes |
| 27 | 3, which is 3 mod 4 | 3, odd | No |
| 17 | 17, which is 1 mod 4 | 1 | Yes |

Every `No` row has an odd exponent for a blocking prime.

## Code

**Input setup.** Constants, bulk input, and the 64-bit scanner set up parsing.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const primeLimit = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value: int64 = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int64(int(data[i]) - firstDigitValue)
    i += 1
  return value
```

Values reach 10^12, so the scanner and all arithmetic use 64 bits. Each digit is visited once.

**Prime sieve.** The sieve writes one flag per integer and collects primes in order.

```nim
var isComposite = newSeq[bool](primeLimit + 1)
var primes: seq[int] = @[]
for candidate in 2..primeLimit:
  if not isComposite[candidate]:
    primes.add candidate
    if int64(candidate) * int64(candidate) <= primeLimit:
      var multiple = candidate * candidate
      while multiple <= primeLimit:
        isComposite[multiple] = true
        multiple += candidate
```

Crossing off starts at `candidate^2`, so each composite is marked once per distinct prime factor. The table is built once, before any test case.

**Two-square test.** The check divides out each prime and inspects its exponent.

```nim
proc isSumOfTwoSquares(value: int64): bool =
  var remaining = value
  for prime in primes:
    let primeValue = int64(prime)
    if primeValue * primeValue > remaining:
      break
    if remaining mod primeValue != 0:
      continue
    var exponent = 0
    while remaining mod primeValue == 0:
      remaining = remaining div primeValue
      exponent += 1
    if primeValue mod 4 == 3 and (exponent and 1) == 1:
      return false
  if remaining > 1 and remaining mod 4 == 3:
    return false
  return true
```

The loop stops when the next prime square exceeds the remainder. The leftover value is then prime, and one modulo-four test finishes the decision.

**Answer loop.** The driver writes answers through one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, i))
for j in 0..<caseCount:
  let value = nextInt(inputData, i)
  if isSumOfTwoSquares(value):
    appendOutput("Yes")
  else:
    appendOutput("No")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case performs one factorization and one answer. The buffer flushes in blocks, never once per case.

## Complexity

The sieve dominates setup, and factoring dominates each case.

| Phase | Time | Space |
| --- | --- | --- |
| Sieve | O(10^6 log log 10^6) | O(10^6) flags |
| Factor per case | O(pi(10^6)) worst case | constant |
| Output | O(c) | one flush block |

The sieve bound follows from the value limit of 10^12.

The totals use the case count.

| Measure | Big O |
| --- | --- |
| Time | O(10^6 log log 10^6 + c · pi(10^6)) |
| Space | O(10^6) |

Testing every pair of squares up to `sqrt(n)` would cost `O(n)` per case.
