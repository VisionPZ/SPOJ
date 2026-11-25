# POWPOW2 — Power with Combinatorics(HARD) (SPOJ)

<https://www.spoj.com/problems/POWPOW2/>

## Problem

For each triple `a`, `b`, `n`, report `a` raised to `b` raised to `exp`, modulo `1000000007`, where `exp` is the sum of the squared binomial coefficients `C(n, r)`.

Input begins with `T`, followed by `T` lines each holding `a`, `b`, and `n`. Output one answer per line. The value of `0^0` is defined as one.

| item | bound |
|---|---|
| test cases `T` | 1 to 1000 |
| base `a` | 0 to 100000 |
| inner base `b` | 0 to 100000 |
| binomial index `n` | 0 to 100000 |
| judge limit | 100 ms, 1536 MB |

The notation `C(n, r)` means choose `r` items from `n`, and `exp = C(2n,n)` is the squared-coefficient sum. A triple `a b n` gives the two bases and the index. The rule `0^0 = 1` applies to a zero base. Math spans `sum C(n, r)^2 = C(2n, n)`, `a^(p-1) = 1`, `b^exp`, `1000000006`, `500000002`, and `2 × 41^2 × 148721` use standard notation, as does `2 × 500000003`. All exponents are evaluated as integers before the final modulus.

Sample input:

```
1

1 1 1
```

Sample output:

```
1
```

## Idea

Vandermonde's identity collapses the whole sum into one central binomial coefficient, like replacing a long hand count with a single labelled box. The solution computes that coefficient modulo the factors of `500000002`, reduces the double exponent with Fermat's theorem, and finishes with modular exponentiation. Each test costs a few logarithms, so a thousand cases stay cheap.

A direct sum over `r` would need `n` terms per case and would also overflow ordinary integers.

## Why It Works

1. Vandermonde's identity gives `sum C(n, r)^2 = C(2n, n)`.
2. The outer modulus `1000000007` is prime, so `a^(p-1) = 1` for nonzero `a`.
3. The needed exponent is `b^exp` reduced modulo `1000000006`.
4. That modulus factors as `2 × 500000003`, with both factors prime.
5. Reducing `b^exp` modulo `500000003` needs `exp` modulo `500000002`.
6. The number `500000002` factors into `2 × 41^2 × 148721`, and each part is handled with p-adic factorials and the Chinese remainder theorem.
7. A zero base or inner base is handled directly, including the rule `0^0 = 1`.

| term | meaning |
|---|---|
| `primeModulus` | the final prime `1000000007` |
| `largePrime` | the prime `500000003` |
| `prefixSmallPrime` | p-free factorials modulo `1681` |
| `exponentResidue` | `exp` modulo `500000002` |

A script evaluated small triples with exact big integers and printed these intermediate values.

| `a b n` | `exp = C(2n,n)` | reduced exponent | answer |
|---|---|---|---|
| 1 1 1 | 2 | 1 | 1 |
| 2 2 2 | 6 | 64 | 582344008 |
| 10 10 10 | 184756 | 695506420 | 330427784 |

The first row matches the sample output exactly.

## Code

**Input and scanning.** The reader loads the stream and exposes a digit scanner.

```nim
const flushBlockBytes = 1 shl 17
const primeModulus: int64 = 1000000007
const largePrime: int64 = 500000003
const smallPrimePower: int64 = 1681
const smallPrime: int64 = 41
const largePrimePower: int64 = 148721

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
```

The constants name each prime and prime power.
The blank line in the sample is skipped by the scanner.
All arithmetic uses 64-bit integers.

**Output buffering.** One buffer holds the answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each answer is appended as text.
Blocks flush when they grow large.
One final flush ends the run.

**Modular helpers.** Powers, inverses, and residues use small integer routines.

```nim
proc modPow(baseValue, exponentValue, modulus: int64): int64 =
  var powerResult: int64 = 1
  var current = baseValue mod modulus
  var powerLeft = exponentValue
  while powerLeft > 0:
    if (powerLeft and 1) != 0:
      powerResult = powerResult * current mod modulus
    current = current * current mod modulus
    powerLeft = powerLeft div 2
  return powerResult

proc modInverse(value, modulus: int64): int64 =
  var oldRemainder = value mod modulus
  var newRemainder = modulus
  var oldCoefficient: int64 = 1
  var newCoefficient: int64 = 0
  while newRemainder != 0:
    let quotient = oldRemainder div newRemainder
    let nextRemainder = oldRemainder - quotient * newRemainder
    oldRemainder = newRemainder
    newRemainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * newCoefficient
    oldCoefficient = newCoefficient
    newCoefficient = nextCoefficient
  return ((oldCoefficient mod modulus) + modulus) mod modulus

proc combineResidues(firstResidue, firstModulus, secondResidue, secondModulus: int64): int64 =
  let inverseFactor = modInverse(firstModulus mod secondModulus, secondModulus)
  var difference = (secondResidue - firstResidue) mod secondModulus
  if difference < 0:
    difference += secondModulus
  let offset = difference * inverseFactor mod secondModulus
  return (firstResidue + firstModulus * offset) mod (firstModulus * secondModulus)
```

Exponentiation squares the base for each set bit.
The extended Euclidean algorithm produces inverses.
Residues merge pairwise into one congruence.

**p-adic binomial residue.** Each prime power contributes one residue of `exp`.

```nim
proc buildPrefix(prime, primePower: int64): seq[int64] =
  var prefixProduct = newSeq[int64](int(primePower))
  prefixProduct[0] = 1
  for index in 1 .. int(primePower) - 1:
    var factor = int64(index)
    if int64(index) mod prime == 0:
      factor = 1
    prefixProduct[index] = prefixProduct[index - 1] * factor mod primePower
  return prefixProduct

proc pFreeFactorial(value, prime, primePower: int64, prefixProduct: seq[int64]): int64 =
  var factorialPart: int64 = 1
  var current = value
  let blockProduct = prefixProduct[int(primePower) - 1]
  while current > 0:
    factorialPart = factorialPart * modPow(blockProduct, current div primePower, primePower) mod primePower
    factorialPart = factorialPart * prefixProduct[int(current mod primePower)] mod primePower
    current = current div prime
  return factorialPart

proc centralModuloPrimePower(combinValue, prime, primePower: int64, prefixProduct: seq[int64]): int64 =
  let doubled = 2 * combinValue
  var valuation: int64 = 0
  var power = prime
  while power <= doubled:
    valuation += doubled div power - 2 * (combinValue div power)
    power *= prime
  var threshold: int64 = 1
  if primePower != prime:
    threshold = 2
  if valuation >= threshold:
    return 0
  let numerator = pFreeFactorial(doubled, prime, primePower, prefixProduct)
  let denominator = pFreeFactorial(combinValue, prime, primePower, prefixProduct)
  let inverseDenominator = modInverse(denominator, primePower)
  var binomialResidue = numerator * inverseDenominator mod primePower
  binomialResidue = binomialResidue * inverseDenominator mod primePower
  binomialResidue = binomialResidue * modPow(prime, valuation, primePower) mod primePower
  return binomialResidue
```

The prefix table holds p-free products up to the prime power.
The valuation counts prime factors left in the binomial.
A valuation past the power limit yields zero.

**Driver.** The loop reduces both exponent layers and emits the answer.

```nim
let prefixSmallPrime = buildPrefix(smallPrime, smallPrimePower)
let prefixLargePrime = buildPrefix(largePrimePower, largePrimePower)

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let baseValue = int64(nextInt(inputData, scanPos))
  let powerBase = int64(nextInt(inputData, scanPos))
  let combinValue = int64(nextInt(inputData, scanPos))
  var answer: int64 = 0
  if baseValue == 0:
    if powerBase == 0:
      answer = 1
    else:
      answer = 0
  elif powerBase == 0:
    answer = 1
  else:
    let parityResidue: int64 = if combinValue == 0: 1 else: 0
    let smallResidue = centralModuloPrimePower(combinValue, smallPrime, smallPrimePower, prefixSmallPrime)
    let largeResidue = centralModuloPrimePower(combinValue, largePrimePower, largePrimePower, prefixLargePrime)
    var exponentResidue = combineResidues(parityResidue, 2, smallResidue, smallPrimePower)
    exponentResidue = combineResidues(exponentResidue, 2 * smallPrimePower, largeResidue, largePrimePower)
    let oddResidue: int64 = if (powerBase and 1) != 0: 1 else: 0
    let primeResidue = modPow(powerBase, exponentResidue, largePrime)
    let reducedExponent = combineResidues(oddResidue, 2, primeResidue, largePrime)
    answer = modPow(baseValue, reducedExponent, primeModulus)
  appendOutput($answer)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Zero bases take a direct branch.
Two Chinese-remainder steps reduce the exponent.
The last power produces the printed residue.

## Complexity

The prefix tables are built once before any test case.

| phase | time | space |
|---|---|---|
| prefix build | one pass up to `148721` and `1681` | two product tables |
| binomial residue | logarithms in `n` per prime power | a few integers |
| case loop | constant powers per test | block buffer |

| measure | Big O |
|---|---|
| time | O(148721 + T log n) |
| space | O(148721) |

A direct sum of squared binomials would take `n` steps per case and could not store the exact huge exponent.

The p-adic reduction replaces that sum with short modular arithmetic.
