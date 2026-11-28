# OTOY1 — One Theorem, One Year (SPOJ)

<https://www.spoj.com/problems/OTOY1/>

## Problem

Sum Euler's totient over every number whose prime factors are exactly the first P primes and whose prime factor count is exactly K. Both conditions are about the multiset of prime factors, not their order.

Input starts with T, the number of cases, where T ≤ 10000. Each case gives K and P, with 1 ≤ P ≤ K ≤ 500. Print one labeled line per case with its case number and answer, with the answer modulo 1000000007.

| item | bound |
|---|---|
| cases T | up to 10000 |
| prime factor count K | 1 to 500 |
| distinct primes P | 1 to K |
| judge limit | 1000 ms, 1536 MB |

The 500 by 500 coefficient grid drives one shared precomputation.

The sample case has three queries and three replies.

```
3
3 2
5 4
99 45
```

```
Case 1: 10
Case 2: 816
Case 3: 49939643
```

The third answer is 49939643 modulo 1000000007.

## Idea

The trick is to turn each prime into a row of a counting triangle, like adding one more coin type to a running tally. Each new prime scales the previous diagonal and shifts it by one place.

The algorithm treats phi as a product and sums over exponent tuples with the generating function of (1 - p x) to the power minus one. Row i holds coefficients for the first i primes, and each cell costs one multiply and one add. Each query then costs two table lookups and one multiply, while enumerating exponent tuples would be exponential.

Precompute once, then answer each case in constant time.

## Why It Works

1. Every valid number has the form product of p_i to the e_i, with each e_i at least 1 and the exponents summing to K.
2. Totient is multiplicative on coprime factors, so phi of that number is the product of p_i to the e_i minus 1 times p_i minus 1.
3. For prime p, the sum over e at least 1 of phi(p^e) times x to the e is (p - 1) times x over 1 minus p times x.
4. Multiplying P such series gives a factor of x to the P, so the required coefficient sits at index K minus P.
5. Writing h_i(j) for the reciprocal series of the first i primes gives h_i(j) = h_{i-1}(j) + p_i times h_i(j-1), which fills the table exactly.

| term | meaning |
|---|---|
| `coefficientTable` | reciprocal-series coefficients for the first i primes |
| `baseFactors` | product of p minus 1 over the first P primes |
| `primeDegree` | the total prime factor count K |
| `primeFactorCount` | the number of distinct primes P |
| `extraExponent` | K minus P, the coefficient index |

The table and the base product combine into one modular answer.

The generator checks the table against brute-force exponent tuples for small cases.

```
brute_sum(3, 2) = 10
brute_sum(5, 4) = 816
```

The two small sums match Case 1 and Case 2 of the sample.

## Code

**Input and sieve.** The reader loads all tokens, and a sieve collects the first 500 primes.

```nim
const flushBlockBytes = 1 shl 17
const modulus = 1000000007
const maxPrimeCount = 500
const maxPrimeDegree = 500
const primeLimit = 4000
const tableStride = maxPrimeDegree + 1

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
```

The scanner reads K before P, matching the statement.

`appendOutput` writes one large block at a time.

The 500th prime is 3571, so the sieve stage stays small.

**Coefficient table.** Each row adds one prime to the reciprocal series.

```nim
var isComposite = newSeq[bool](primeLimit + 1)
var primeList = newSeq[int](maxPrimeCount)
var foundPrimes = 0
for candidate in 2 .. primeLimit:
  if not isComposite[candidate]:
    primeList[foundPrimes] = candidate
    foundPrimes += 1
    if foundPrimes == maxPrimeCount:
      break
    var multiple = candidate * candidate
    while multiple <= primeLimit:
      isComposite[multiple] = true
      multiple += candidate

var coefficientTable = newSeq[int]((maxPrimeCount + 1) * tableStride)
var baseFactors = newSeq[int](maxPrimeCount + 1)
coefficientTable[0] = 1
baseFactors[0] = 1
for primeIndex in 1 .. maxPrimeCount:
  let currentPrime = primeList[primeIndex - 1]
  baseFactors[primeIndex] = int(int64(baseFactors[primeIndex - 1]) *
      int64(currentPrime - 1) mod int64(modulus))
  let previousRow = (primeIndex - 1) * tableStride
  let currentRow = primeIndex * tableStride
  coefficientTable[currentRow] = 1
  for extraExponent in 1 .. maxPrimeDegree:
    let carry = int64(currentPrime) * int64(coefficientTable[currentRow + extraExponent - 1])
    let total = int64(coefficientTable[previousRow + extraExponent]) + carry
    coefficientTable[currentRow + extraExponent] = int(total mod int64(modulus))
```

Row zero has coefficient one at index zero.

`int64` holds the product of a prime and a residue before reduction.

The build costs 250000 multiply-add steps.

**Case answers.** Each case reads K and P, then combines two table values.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let primeDegree = nextInt(inputData, scanPos)
  let primeFactorCount = nextInt(inputData, scanPos)
  let extraExponent = primeDegree - primeFactorCount
  let coefficient = coefficientTable[primeFactorCount * tableStride + extraExponent]
  let answer = int(int64(baseFactors[primeFactorCount]) * int64(coefficient) mod int64(modulus))
  appendOutput("Case " & $caseIndex & ": " & $answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The coefficient index is never negative because P does not exceed K.

One modular multiplication joins the base product and the coefficient.

## Complexity

One table build serves all cases, and each case is two lookups and one multiply.

| phase | time | space |
|---|---|---|
| input read | one pass over case tokens | one input string |
| table build | 500 rows of 501 coefficients | 501 table rows |
| case answers | one lookup and one multiply per case | one output block |

Each case adds only constant work after the build.

| measure | Big O |
|---|---|
| time | O(500 * 500 + T) |
| space | O(500 * 500) |

Enumerating exponent tuples would cost exponential time per case, so the shared coefficient table is the decisive gain.
