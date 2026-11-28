# LARGE — Large party (SPOJ)

<https://www.spoj.com/problems/LARGE/>

## Problem

Count round-table patterns of N men and women where no K plus one women sit together, treating rotations as the same pattern. The answer is taken modulo 100000007.

Input starts with the number of test cases, and each case is preceded by a blank line. Each case has two integers N and K, where N is the number of seats. Output one integer per case: the number of distinct patterns under rotation.

| item | bound |
|---|---|
| seats N | 1 to 999 |
| run limit K | nonnegative integer |
| test cases | almost 1000 |
| modulus | 100000007 |
| judge limit | 2000 ms, 1536 MB |

The seat count drives the precomputation, since every value up to the largest N is prepared once.

Sample input:

```
3

3 1

3 3

4 1
```

Sample output:

```
2
4
3
```

## Idea

Count rotations with Burnside's lemma, like counting distinct bracelets by asking how many patterns survive each turn. A rotation that survives fixes a repeated pattern of length equal to the gcd of the seat count and the turn. For each divisor, count circular patterns with bounded women runs using an inclusion-exclusion sum. The closed form takes a few steps per divisor, while enumerating all two to the N patterns is impossible near the limit. One inverse per seat count turns the rotation sum into the final answer.

## Why It Works

1. Burnside's lemma says the number of rotation classes is the average number of patterns fixed by each rotation.
2. A rotation by r seats fixes patterns whose period divides gcd(N, r).
3. There are phi(N divided by d) rotations with gcd(N, r) equal to d.
4. A fixed pattern of length d repeats, so its women runs stay bounded exactly when the length d pattern is bounded.
5. The all-women pattern of length d fails when N exceeds K, even if d does not.
6. Inclusion-exclusion over runs crossing the circle boundary gives the count of bounded circular patterns.

| term | meaning |
|---|---|
| `circularCount` | bounded circular patterns for one length and limit |
| `binomialCoefficient` | factorial ratio used in inclusion-exclusion |
| `rotationTotal` | Burnside sum before division by N |
| `phiValues` | rotation counts for each divisor |
| `inverses` | modular inverse of each seat count |

The table names the values that turn rotations into a modular answer.

A script trace of the first sample case gives visible numbers:

```text
case 3 1
  divisor 1: rotations 2, fixed 1
  divisor 3: rotations 1, fixed 4
  (2*1 + 1*4) / 3 = 2
```

The trace divides the rotation sum by three and reproduces the first sample answer 2.

## Code

**Input and scanning.** The hand reader loads all cases, then the largest seat count sets the table size.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 100000007

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

The modulus is 10^8+7, not the common 10^9+7.
Blank lines contain no digits, so the scanner skips them.
Reading every case first allows one shared precomputation.

**Output buffer.** Answers are appended to one block buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One line is added per test case.
The buffer writes only when it fills.
A final write handles the remaining text.

**Modular power.** Fermat inversion needs fast exponentiation.

```nim
proc powerModulo(baseValue: int64, exponentValue: int64): int64 =
  var powerResult: int64 = 1
  var factor = baseValue mod modulusValue
  var exponentLeft = exponentValue
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      powerResult = powerResult * factor mod modulusValue
    factor = factor * factor mod modulusValue
    exponentLeft = exponentLeft shr 1
  return powerResult
```

Squaring keeps the work logarithmic in the exponent.
All products stay under the 64-bit limit because the modulus is small.
This helper builds the inverse tables.

**Precomputation.** Factorials, inverses, powers of two, and phi fill once.

```nim
let caseCount = nextInt(inputData, scanPos)
var peopleCounts = newSeq[int](caseCount)
var runLimits = newSeq[int](caseCount)
var maximumPeople = 0
for caseIndex in 0 .. caseCount - 1:
  peopleCounts[caseIndex] = nextInt(inputData, scanPos)
  runLimits[caseIndex] = nextInt(inputData, scanPos)
  if peopleCounts[caseIndex] > maximumPeople:
    maximumPeople = peopleCounts[caseIndex]

if maximumPeople < 1:
  maximumPeople = 1

var factorials = newSeq[int64](maximumPeople + 1)
var inverseFactorials = newSeq[int64](maximumPeople + 1)
var inverses = newSeq[int64](maximumPeople + 1)
var powersOfTwo = newSeq[int64](maximumPeople + 1)
var phiValues = newSeq[int](maximumPeople + 1)

factorials[0] = 1
for valueIndex in 1 .. maximumPeople:
  factorials[valueIndex] = factorials[valueIndex - 1] * int64(valueIndex) mod modulusValue
inverseFactorials[maximumPeople] = powerModulo(factorials[maximumPeople], modulusValue - 2)
for valueIndex in countdown(maximumPeople, 1):
  inverseFactorials[valueIndex - 1] = inverseFactorials[valueIndex] * int64(valueIndex) mod modulusValue
for valueIndex in 1 .. maximumPeople:
  inverses[valueIndex] = powerModulo(int64(valueIndex), modulusValue - 2)
powersOfTwo[0] = 1
for valueIndex in 1 .. maximumPeople:
  powersOfTwo[valueIndex] = powersOfTwo[valueIndex - 1] * 2 mod modulusValue
for valueIndex in 0 .. maximumPeople:
  phiValues[valueIndex] = valueIndex
for primeValue in 2 .. maximumPeople:
  if phiValues[primeValue] == primeValue:
    var multiple = primeValue
    while multiple <= maximumPeople:
      phiValues[multiple] = phiValues[multiple] div primeValue * (primeValue - 1)
      multiple = multiple + primeValue
```

The sieve fills phi values in one pass.
Each table has one entry per seat count up to the maximum.
The cost is shared by every test case.

**Circular count.** Inclusion-exclusion handles runs that wrap around the table.

```nim
proc binomialCoefficient(groupSize: int, chosenCount: int): int64 =
  if chosenCount < 0 or chosenCount > groupSize:
    return 0
  return factorials[groupSize] * inverseFactorials[chosenCount] mod modulusValue *
         inverseFactorials[groupSize - chosenCount] mod modulusValue

proc circularCount(patternLength: int, runLimit: int): int64 =
  var countValue = powersOfTwo[patternLength] - 1
  if countValue < 0:
    countValue = countValue + modulusValue
  if patternLength <= runLimit:
    countValue = (countValue + 1) mod modulusValue
  var cycleIndex = 1
  while cycleIndex * (runLimit + 2) <= patternLength:
    let remainder = patternLength - cycleIndex * (runLimit + 1) - 1
    var termValue = int64(patternLength) * inverses[cycleIndex] mod modulusValue
    termValue = termValue * binomialCoefficient(remainder, cycleIndex - 1) mod modulusValue
    termValue = termValue * powersOfTwo[remainder - cycleIndex + 1] mod modulusValue
    if (cycleIndex and 1) == 1:
      countValue = countValue - termValue
      if countValue < 0:
        countValue = countValue + modulusValue
    else:
      countValue = (countValue + termValue) mod modulusValue
    cycleIndex += 1
  return countValue mod modulusValue
```

The first term counts all patterns except the all-men pattern.
The all-women pattern is added back when it fits the limit.
Each remaining term uses a factorial ratio and a precomputed power of two.

**Burnside sum.** Divisors of N replace the individual rotations.

```nim
for caseIndex in 0 .. caseCount - 1:
  let peopleCount = peopleCounts[caseIndex]
  let runLimit = runLimits[caseIndex]
  var rotationTotal: int64 = 0
  var divisor = 1
  while divisor <= peopleCount:
    if peopleCount mod divisor == 0:
      let quotient = peopleCount div divisor
      var fixedCount = circularCount(divisor, runLimit)
      if divisor <= runLimit and peopleCount > runLimit:
        fixedCount = fixedCount - 1
        if fixedCount < 0:
          fixedCount = fixedCount + modulusValue
      rotationTotal = (rotationTotal + int64(phiValues[quotient]) * fixedCount) mod modulusValue
    divisor += 1
  let answer = rotationTotal * inverses[peopleCount] mod modulusValue
  appendOutput($(answer))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each divisor is weighted by phi of the complementary quotient.
The all-women pattern is removed only when the full table cannot allow it.
Multiplying by the inverse of N completes the average.

## Complexity

Precomputation runs once, and each case walks its divisors.

| phase | time | space |
|---|---|---|
| input read | one pass over case tokens | one input string |
| precompute | one sieve up to largest N | four tables of size N |
| circular count | few terms per divisor | constant working space |
| output | one line per case | block buffer |

Precomputation and divisor counts dominate the run.

| measure | Big O |
|---|---|
| time | O(Nmax log log Nmax + cases times divisors times N divided by K) |
| space | O(Nmax) |

Enumerating all seat assignments would cost O(2 to the N) per case.
Burnside and a closed-form count replace that with a small divisor sum, and that is the takeaway.
