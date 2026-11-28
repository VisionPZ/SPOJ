# KEQ — K Equal Digits (SPOJ)

<https://www.spoj.com/problems/KEQ/>

## Problem

Find the largest number made of one repeated digit that has at most K digits and is divisible by at least one of the given divisors. Report its digit count and its digit; when no positive-digit answer exists, report one digit zero.

Input starts with the number of test cases, and each case is preceded by a blank line. A case starts with K and R, followed by R divisor lines. Output two integers per case: the digit count N and the repeated digit D.

| item | bound |
|---|---|
| maximal digit count K | 1 to 1000000000 |
| divisor count R | 1 to 7 |
| each divisor | 1 to 100000000000000 |
| judge limit | 2000 ms, 1536 MB |

The divisor size drives the design, since trial division up to its square root would be slow.

Sample input:

```
3

47 2
42
47

99 4
123
234
345
456

3 1
4700
```

Sample output:

```
46 9
96 6
1 0
```

## Idea

Turn divisibility into a period question, like finding when a repeating clock hand returns to twelve. A number with N copies of digit D equals D times the repunit of length N. After dividing out the shared factors of D and the divisor, the remaining factor must divide that repunit. This happens exactly when N is a multiple of the order of ten modulo nine times that factor. Factor the small numbers with Pollard rho, reduce the order, and jump straight to the largest multiple of the period not exceeding K. Brute force over every length would take hours. The takeaway is that one period per digit and divisor settles the whole search.

## Why It Works

1. A repeated-digit number with N digits equals D times the repunit of length N.
2. A divisor d divides that number exactly when d after removing the common factor with D divides the repunit.
3. The repunit condition is equivalent to ten to the N being congruent to one modulo nine times the reduced divisor.
4. If the reduced divisor shares a factor with ten, no positive length can satisfy the congruence.
5. The order of ten modulo that modulus is the shortest period, so every valid length is a multiple of it.
6. The largest multiple of the period not exceeding K is the best length for that digit and divisor.
7. Comparing length first and digit second gives the required answer; zero with one digit is the fallback.

| term | meaning |
|---|---|
| `gcdIntegers` | shared factor of a divisor and a digit |
| `reducedDivisor` | divisor left after removing that shared factor |
| `exponentValue` | order of ten modulo the working modulus |
| `pollardFactor` | factor found for a composite value |
| `bestLength` | largest digit count found so far |
| `bestDigit` | digit paired with the best length |

The table names the values that turn each divisor and digit into a candidate.

A script trace of the first sample case gives visible numbers:

```text
d=42 D=8: gcd=2 reduced=21 modulus=189 order=6 length=42
d=42 D=6: gcd=6 reduced=7 modulus=63 order=6 length=42
d=47 D=9: gcd=1 reduced=47 modulus=423 order=46 length=46
best length 46 with digit 9
```

The trace shows divisor 47 beating every candidate from divisor 42 and reproduces 46 9.

## Code

**Input and scanning.** The hand reader loads every case into one string.

```nim
const flushBlockBytes = 1 shl 17
const primeBases = [int64(2), 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]

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

The base list proves primality for values below the required bound.
Blank lines contain no digits and are skipped.
All divisors fit in a signed 64-bit value.

**Output buffer.** Answers are written in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each case contributes one short line.
The buffer flushes only after reaching the block size.
A final write clears the remaining text.

**Arithmetic.** Multiplication and powers use modular doubling to avoid overflow.

```nim
proc gcdIntegers(leftValue: int64, rightValue: int64): int64 =
  var larger = leftValue
  var smaller = rightValue
  if larger < 0:
    larger = -larger
  if smaller < 0:
    smaller = -smaller
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc multiplyMod(leftValue: int64, rightValue: int64, modulus: int64): int64 =
  var productValue: int64 = 0
  var multiplicand = leftValue mod modulus
  var multiplier = rightValue
  while multiplier > 0:
    if (multiplier and 1) == 1:
      productValue = (productValue + multiplicand) mod modulus
    multiplicand = (multiplicand * 2) mod modulus
    multiplier = multiplier shr 1
  return productValue

proc powerModulo(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var powerResult: int64 = 1 mod modulus
  var factor = baseValue mod modulus
  var exponentLeft = exponentValue
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      powerResult = multiplyMod(powerResult, factor, modulus)
    factor = multiplyMod(factor, factor, modulus)
    exponentLeft = exponentLeft shr 1
  return powerResult
```

Doubling keeps each intermediate below twice the modulus.
Squaring makes each power logarithmic in its exponent.
Both helpers work for moduli near 10^15.

**Primality.** Miller-Rabin with fixed bases rejects composites quickly.

```nim
proc isPrimeNumber(candidate: int64): bool =
  if candidate < 2:
    return false
  for baseValue in primeBases:
    if candidate == baseValue:
      return true
    if candidate mod baseValue == 0:
      return false
  var oddPart = candidate - 1
  var shiftCount = 0
  while (oddPart and 1) == 0:
    oddPart = oddPart shr 1
    shiftCount += 1
  for baseValue in primeBases:
    var observed = powerModulo(baseValue, oddPart, candidate)
    if observed == 1 or observed == candidate - 1:
      continue
    var roundIndex = 1
    var witnessPassed = false
    while roundIndex < shiftCount:
      observed = multiplyMod(observed, observed, candidate)
      if observed == candidate - 1:
        witnessPassed = true
        break
      roundIndex += 1
    if not witnessPassed:
      return false
  return true
```

The chosen bases are deterministic in the required range.
Small prime checks remove easy composites first.
Each witness uses repeated squaring under the modulus.

**Factorization.** Pollard rho splits composites, and factors are then sorted.

```nim
proc pollardFactor(value: int64): int64 =
  if (value and 1) == 0:
    return 2
  if value mod 3 == 0:
    return 3
  var constantValue: int64 = 1
  while true:
    var tortoise: int64 = 2
    var hare: int64 = 2
    var foundFactor: int64 = 1
    var stepCount = 0
    while foundFactor == 1 and stepCount < 200000:
      tortoise = (multiplyMod(tortoise, tortoise, value) + constantValue) mod value
      hare = (multiplyMod(hare, hare, value) + constantValue) mod value
      hare = (multiplyMod(hare, hare, value) + constantValue) mod value
      var difference = tortoise - hare
      if difference < 0:
        difference = -difference
      foundFactor = gcdIntegers(difference, value)
      stepCount += 1
    if foundFactor > 1 and foundFactor < value:
      return foundFactor
    constantValue += 1

proc collectFactors(value: int64, factors: var seq[int64]) =
  if value <= 1:
    return
  if isPrimeNumber(value):
    factors.add value
    return
  let divisor = pollardFactor(value)
  collectFactors(divisor, factors)
  collectFactors(value div divisor, factors)

proc sortFactors(factors: var seq[int64]) =
  for sortIndex in 1 .. factors.len - 1:
    let keyFactor = factors[sortIndex]
    var scanIndex = sortIndex - 1
    while scanIndex >= 0 and factors[scanIndex] > keyFactor:
      factors[scanIndex + 1] = factors[scanIndex]
      scanIndex -= 1
    factors[scanIndex + 1] = keyFactor
```

A new constant is tried if one sequence fails to split a value.
Recursion stops as soon as a factor is prime.
Sorting makes repeated prime factors easy to skip.

**Main loop.** Every divisor and digit yields one candidate length.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let maxDigits = int64(nextInt(inputData, scanPos))
  let divisorCount = nextInt(inputData, scanPos)
  var divisors = newSeq[int64](divisorCount)
  for divisorIndex in 0 .. divisorCount - 1:
    divisors[divisorIndex] = int64(nextInt(inputData, scanPos))
  var bestLength: int64 = 1
  var bestDigit: int64 = 0
  block searchDone:
    for divisor in divisors:
      for digit in 1 .. 9:
        let sharedFactor = gcdIntegers(divisor, int64(digit))
        let reducedDivisor = divisor div sharedFactor
        if reducedDivisor mod 2 == 0 or reducedDivisor mod 5 == 0:
          continue
        let modulusValue = 9 * reducedDivisor
        var primeFactors = newSeq[int64]()
        collectFactors(reducedDivisor, primeFactors)
        sortFactors(primeFactors)
        var phiValue = modulusValue div 3 * 2
        var previousPrime: int64 = 0
        for primeFactor in primeFactors:
          if primeFactor != previousPrime and primeFactor != 3:
            phiValue = phiValue div primeFactor * (primeFactor - 1)
          previousPrime = primeFactor
        var phiFactors = newSeq[int64]()
        collectFactors(phiValue, phiFactors)
        sortFactors(phiFactors)
        var exponentValue = phiValue
        previousPrime = 0
        for primeFactor in phiFactors:
          if primeFactor == previousPrime:
            continue
          previousPrime = primeFactor
          while exponentValue mod primeFactor == 0 and
                powerModulo(10, exponentValue div primeFactor, modulusValue) == 1:
            exponentValue = exponentValue div primeFactor
        let candidateLength = (maxDigits div exponentValue) * exponentValue
        if candidateLength >= 1 and
              (candidateLength > bestLength or
               (candidateLength == bestLength and int64(digit) > bestDigit)):
          bestLength = candidateLength
          bestDigit = int64(digit)
        if bestLength == maxDigits and bestDigit == 9:
          break searchDone
  appendOutput($(bestLength) & " " & $(bestDigit))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Candidates with a factor of two or five in the reduced divisor are skipped.
Phi is reduced by each distinct prime factor until the order is minimal.
The search stops once the largest length with digit nine is found.

## Complexity

At most seven divisors and nine digits are tested per case.

| phase | time | space |
|---|---|---|
| input read | one pass over divisor tokens | one input string |
| factorization | Pollard rho per composite value | factor arrays |
| order reduction | few powers per prime factor | phi factor array |
| output | one line per case | block buffer |

Factorization and order reduction dominate each candidate.

| measure | Big O |
|---|---|
| time per case | O(R times 9 times value to the one quarter) expected |
| space per case | O(number of prime factors) |

Testing every length up to K would take hours when K reaches one billion.
A single multiplicative order per digit and divisor replaces that search, and that is the takeaway.
