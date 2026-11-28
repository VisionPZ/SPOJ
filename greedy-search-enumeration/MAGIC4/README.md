# MAGIC4 — Magic Program IV (SPOJ)

<https://www.spoj.com/problems/MAGIC4/>

## Problem

Given one integer n, compute the product of i to the power j over all ordered pairs from 1 to n whose greatest common divisor is 1. The answer is taken modulo 1e9+7. The original page supplies a slow program instead of a prose statement; its functions perform 32-bit addition, multiplication modulo 1e9+7, and binary exponentiation.

Input is a single integer n. Output is a single integer, the product modulo 1e9+7. Inputs outside 1 to 100000 make the original program print `ERROR`.

| item | bound |
|---|---|
| n | 1 to 100000 |
| output | one integer below 1e9+7 |
| judge limit | 100 ms, 1536 MB |

The pair count grows as n squared, so the bound drives the design.

The statement has no sample; the smallest valid case is:

```
1
```

```
1
```

## Idea

Group the product by its base instead of by pairs. All pairs with the same i share one base, so only their exponents must be added. Möbius inversion turns that exponent sum into a short walk over the divisors of i. One modular power per base then finishes the product. Visiting all n squared pairs would take far too long at n = 100000. Grouping replaces that work with about n log n divisor steps.

## Why It Works

1. The slow program skips pair (i, j) exactly when some k at least 2 divides both numbers.
2. That condition is the same as gcd(i, j) greater than 1.
3. For a fixed base i, its exponent is the sum of j over all j coprime to i.
4. Möbius inversion gives that sum as a signed sum over divisors d of i.
5. Each divisor contributes d times the triangular number of n divided by d.
6. Modular powers multiply to the required product, since the modulus is prime.

| term | meaning |
|---|---|
| `mobius` | Möbius value for each integer up to n |
| `triangular` | sum of integers from 1 to n/d |
| `exponents` | total power for each base |
| `powerMod` | binary modular exponentiation |

One divisor pass fills every base exponent at once.

A script trace for n = 3 gives:

```
coprime pairs  (1,1) (1,2) (1,3) (2,1) (2,3) (3,1) (3,2)
exponent of 2  1 + 3 = 4       2^4 = 16
exponent of 3  1 + 2 = 3       3^3 = 27
product        16 * 27 = 432
out            432
```

The trace matches the slow program on the same input.

## Code

**Input and output helpers.** All input is read once and the single number is scanned by hand.

```nim
const flushBlockBytes = 1 shl 17
const primeModulus = 1000000007

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var powerResult: int64 = 1
  var base = baseValue mod primeModulus
  var exponent = exponentValue
  while exponent > 0:
    if exponent mod 2 == 1:
      powerResult = (powerResult * base) mod primeModulus
    base = (base * base) mod primeModulus
    exponent = exponent div 2
  return powerResult
```

`powerMod` keeps every intermediate below the modulus squared.
`appendOutput` uses one block buffer for the single result line.
The hand scanner skips all input whitespace.

**Möbius sieve.** A linear sieve fills the Möbius value for every number up to n.

```nim
let limit = nextInt(inputData, scanPos)
var mobius = newSeq[int](limit + 1)
var composite = newSeq[bool](limit + 1)
var primes = newSeq[int](0)
if limit >= 1:
  mobius[1] = 1
for value in 2 .. limit:
  if not composite[value]:
    primes.add value
    mobius[value] = -1
  for primeIndex in 0 .. primes.len - 1:
    let prime = primes[primeIndex]
    if value * prime > limit:
      break
    composite[value * prime] = true
    if value mod prime == 0:
      mobius[value * prime] = 0
      break
    mobius[value * prime] = -mobius[value]
```

Each composite gets its smallest prime factor once.
Squares receive zero and squarefree products flip the sign.
The sieve costs O(n) steps.

**Exponent accumulation and product.** One pass over divisors fills all exponents.

```nim
var exponents = newSeq[int64](limit + 1)
for divisor in 1 .. limit:
  if mobius[divisor] != 0:
    let quotient = limit div divisor
    let triangular = (int64(quotient) * int64(quotient + 1)) div 2
    let term = int64(mobius[divisor]) * int64(divisor) * triangular
    var multiple = divisor
    while multiple <= limit:
      exponents[multiple] = exponents[multiple] + term
      multiple = multiple + divisor
var result: int64 = 1
for baseValue in 2 .. limit:
  if exponents[baseValue] > 0:
    result = (result * powerMod(int64(baseValue), exponents[baseValue])) mod primeModulus
appendOutput($result)
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

64-bit intermediates hold triangular numbers near five billion.
Each base contributes one modular power, not one per pair.
The final answer is written once.

## Complexity

The sieve and divisor walks scale linearly or near-linearly with n.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| Möbius sieve | one step per composite | two arrays of size n |
| exponents and product | divisor walk plus n powers | one exponent array |

The divisor walk dominates the sieve by a small logarithmic factor.

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n) |

Testing every ordered pair would cost O(n squared) modular powers and miss the time limit at the upper bound.
