# IOPC1204 — A function over factors (SPOJ)

<https://www.spoj.com/problems/IOPC1204/>

## Problem

A function sums each divisor of N multiplied by its Möbius value. This equals Euler's totient, the count of positive integers up to N that share no factor with N. Find the smallest N whose totient exceeds X.

Input starts with the test count. Each following line holds one integer X. Output one integer per line.

| item | bound |
|---|---|
| test cases T | up to 1000 |
| threshold X | 0 to 10^12 |
| judge limit | 1000 ms, 1536 MB |

The sample fixes X = 1 to 3 and X = 2 to 5.

Sample input:

```
2
1
2
```

Sample output:

```
3
5
```

## Idea

A prime keeps almost all of its numbers coprime, like a row of seats with no reserved places. For prime p the totient is p−1. Nearby composite numbers lose a fixed share of their seats to a small prime factor.

The smallest N with totient above X is therefore the first prime after X+1. Test candidates with Miller–Rabin primality and stop at the first prime.

Miller–Rabin costs O(log³ N) per candidate with modular multiplication by doubling. Scanning and factoring every N from X upward would cost far more for large thresholds.

One primality test per candidate settles each case.

## Why It Works

1. The divisor sum of d times μ(d) equals Euler's totient φ(N).
2. For a prime p, φ(p) = p−1, so p passes when p > X+1.
3. Any composite n near X has a smallest prime factor q, so φ(n) ≤ n(1−1/q).
4. That bound falls below X unless q is as large as n, which means n is prime.
5. Products of two large primes also exceed the first prime after X+1.
6. Hence the first prime after X+1 is the smallest passing number.

| term | meaning |
|---|---|
| `threshold` | the input value X |
| `candidate` | current odd number being tested |
| `isPrime` | deterministic Miller–Rabin test for the input range |
| `modMultiply` | product modulo a value using repeated doubling |

Doubling avoids 64-bit overflow because both operands stay below 10^12.

For X = 2, the first candidate is 4, which is even and skipped. Candidate 5 is prime, and φ(5) = 4 > 2. The answer is 5.

The trace matches the second sample line.

## Code

**Input and scanner.** The hand reader loads the test count and every threshold.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

Thresholds fit in int64 after parsing.

The scanner skips spaces and newlines in the same way.

**Output buffer and modular arithmetic.** Text is buffered, and modular products use doubling.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc modMultiply(leftValue: int64, rightValue: int64, modulus: int64): int64 =
  var product: int64 = 0
  var baseValue = leftValue mod modulus
  var factor = rightValue
  while factor > 0:
    if (factor and 1) == 1:
      product = product + baseValue
      if product >= modulus:
        product = product - modulus
    baseValue = baseValue + baseValue
    if baseValue >= modulus:
      baseValue = baseValue - modulus
    factor = factor div 2
  return product

proc modPower(baseValue: int64, exponent: int64, modulus: int64): int64 =
  var power = exponent
  var current = baseValue mod modulus
  var powerResult: int64 = 1
  while power > 0:
    if (power and 1) == 1:
      powerResult = modMultiply(powerResult, current, modulus)
    current = modMultiply(current, current, modulus)
    power = power div 2
  return powerResult
```

Each addition stays below twice the modulus.

Exponentiation scans the binary digits of the exponent.

**Primality test.** Small primes are checked first, then seven Miller–Rabin witnesses.

```nim
proc isPrime(candidate: int64): bool =
  if candidate < 2:
    return false
  let smallPrimes = [int64(2), 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
  for primeValue in smallPrimes:
    if candidate == primeValue:
      return true
    if candidate mod primeValue == 0:
      return false
  var oddPart = candidate - 1
  var powerOfTwo = 0
  while (oddPart and 1) == 0:
    oddPart = oddPart div 2
    powerOfTwo += 1
  let witnessValues = [int64(2), 3, 5, 7, 11, 13, 17]
  for witness in witnessValues:
    var observed = modPower(witness, oddPart, candidate)
    if observed == 1 or observed == candidate - 1:
      continue
    var isWitness = true
    for roundIndex in 1 .. powerOfTwo - 1:
      observed = modMultiply(observed, observed, candidate)
      if observed == candidate - 1:
        isWitness = false
        break
    if isWitness:
      return false
  return true
```

The witness set is deterministic below 3.4×10^14.

The input bound stays well inside that range.

**Candidate search.** Each threshold starts above X+1 and steps over even numbers.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let threshold = int64(nextInt(inputData, scanPos))
  var candidate = threshold + 2
  if candidate > 2 and (candidate mod 2) == 0:
    candidate += 1
  while not isPrime(candidate):
    candidate += 2
  appendOutput($candidate)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Candidate 2 is kept for X = 0.

Every later candidate is odd, which halves the number of tests.

## Complexity

Each case tests odd candidates until the first prime appears.

| phase | time | space |
|---|---|---|
| input read | one pass over T thresholds | one input string |
| primality tests | O(g log³ X) for gap g | constant arrays |
| output | one buffered write per block | block buffer |

Prime gaps near 10^12 stay small, so g stays modest.

| measure | Big O |
|---|---|
| time per case | O(g log³ X) |
| space per case | O(1) |

Factoring every candidate by trial division would cost O(√X) per number.

The primality shortcut keeps 1000 cases within the limit.
