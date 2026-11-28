# DETER3 — Find The Determinant III (SPOJ)

<https://www.spoj.com/problems/DETER3/>

## Problem

Find each matrix determinant modulo a given modulus P, which may be composite. Input runs until end of file.

Every case starts with N and P, followed by N rows of N integers. Matrix entries range between minus one billion plus one and one billion minus one.

Print one residue per case, between zero and P minus one.

| item | bound |
|---|---|
| matrix size N | 1 to 200 |
| modulus P | 1 to 1000000000 |
| matrix entry | between -1000000001 and 1000000001 |
| input size | about 3 MB |
| judge limit | 2541 ms, 1536 MB |

Composite moduli make ordinary modular division unsafe.

Sample input:

```
1 10
-528261590
2 2
595698392 -398355861
603279964 -232703411
3 4
-840419217 -895520213 -303215897
537496093 181887787 -957451145
-305184545 584351123 -257712188
```

Sample output:

```
0
0
2
```

## Idea

Crack a combination lock one wheel at a time: split the modulus into coprime prime-power wheels, solve each wheel, then align them. The algorithm factors P by trial division, eliminates each matrix modulo a prime power, and joins residues with the Chinese remainder theorem. Each prime power costs O(N^3) work.

Plain Gaussian elimination fails because a pivot may lack an inverse modulo a composite number. Valuation-aware elimination keeps the determinant correct even when a pivot is a zero divisor.

## Why It Works

1. Coprime prime powers multiply to P, so their residues determine the answer modulo P.
2. Inside one prime power, choose the pivot with the fewest factors of that prime.
3. Write that pivot as a prime power times a unit, and invert only the unit.
4. Other column entries have at least as many prime factors, so elimination is exact.
5. Multiplying pivots and tracking row swaps gives the determinant in that ring.
6. The Chinese remainder theorem recombines the coprime residues into one answer.

A zero column makes the determinant zero modulo that prime power.

| term | meaning |
|---|---|
| `valuationOf` | count of prime factors in a value |
| `modInverse` | inverse from the extended Euclidean algorithm |
| `primePowerOf` | prime raised to a small exponent |
| `determinantForPrimePower` | elimination result in one prime-power ring |
| `combinedResidue` | residue after joining prime powers |

Every elimination uses only invertible unit parts.

A trace of the third sample case, with P = 4:

```
entries modulo 4      3 3 3 / 1 3 3 / 3 3 0
exact determinant     -928594294119705688086549698
residue modulo 4      2
output                2
```

The trace reproduces the sample answer of two.

Negative entries are normalized into the range from zero to P minus one before elimination.

## Code

**Input and modular inverse.** All integers are read once, including signs.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc modInverse(value: int64, modulus: int64): int64 =
  var oldRemainder = value mod modulus
  if oldRemainder < 0:
    oldRemainder += modulus
  var remainder = modulus
  var oldCoefficient: int64 = 1
  var coefficient: int64 = 0
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    oldRemainder = remainder
    remainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * coefficient
    oldCoefficient = coefficient
    coefficient = nextCoefficient
  var inverse = oldCoefficient mod modulus
  if inverse < 0:
    inverse += modulus
  return inverse
```

The scanner accepts minus signs. The inverse needs a unit, never a zero divisor. Products stay inside 64-bit integers.

**Elimination in one prime power.** Valuation chooses the pivot and its inverse.

```nim
proc valuationOf(value: int64, prime: int64): int =
  if value == 0:
    return high(int)
  var remaining = value
  var power = 0
  while remaining mod prime == 0:
    remaining = remaining div prime
    power += 1
  return power

proc primePowerOf(prime: int64, exponent: int): int64 =
  var power: int64 = 1
  for step in 1 .. exponent:
    power = power * prime
  return power

proc determinantForPrimePower(matrix: seq[int64], size: int,
                              prime: int64, exponent: int): int64 =
  let modulus = primePowerOf(prime, exponent)
  var work = newSeq[int64](size * size)
  for index in 0 .. size * size - 1:
    var normalized = matrix[index] mod modulus
    if normalized < 0:
      normalized += modulus
    work[index] = normalized
  var signMultiplier: int64 = 1
  var accumulated: int64 = 1
  for column in 0 .. size - 1:
    var bestRow = column
    var bestValue = work[column * size + column]
    var bestValuation = valuationOf(bestValue, prime)
    for row in column + 1 .. size - 1:
      let candidate = work[row * size + column]
      let candidateValuation = valuationOf(candidate, prime)
      if candidateValuation < bestValuation:
        bestValuation = candidateValuation
        bestRow = row
        bestValue = candidate
        if bestValuation == 0:
          break
    if bestValue == 0 or bestValuation >= exponent:
      return 0
    if bestRow != column:
      for columnIndex in 0 .. size - 1:
        swap work[column * size + columnIndex], work[bestRow * size + columnIndex]
      signMultiplier = -signMultiplier
    let pivotValue = work[column * size + column]
    accumulated = (accumulated * pivotValue) mod modulus
    let pivotPower = primePowerOf(prime, bestValuation)
    let unitPart = pivotValue div pivotPower
    let inverseUnit = modInverse(unitPart, modulus)
    for row in column + 1 .. size - 1:
      let entryValue = work[row * size + column]
      if entryValue == 0:
        continue
      let scaledFactor = ((entryValue div pivotPower) * inverseUnit) mod modulus
      for columnIndex in column + 1 .. size - 1:
        let subtrahend = (scaledFactor * work[column * size + columnIndex]) mod modulus
        var updated = work[row * size + columnIndex] - subtrahend
        if updated < 0:
          updated += modulus
        work[row * size + columnIndex] = updated
      work[row * size + column] = 0
  let signedProduct = accumulated * signMultiplier
  var answer = signedProduct mod modulus
  if answer < 0:
    answer += modulus
  return answer
```

The least-valued pivot keeps every elimination factor integral. A zero column yields determinant zero. Row swaps flip the sign.

**Chinese remainder recombination.** Coprime residues are merged into one answer.

```nim
proc determinantModulo(matrix: seq[int64], size: int,
                       modulusValue: int64): int64 =
  if modulusValue == 1:
    return 0
  var remainingModulus = modulusValue
  var combinedResidue: int64 = 0
  var combinedModulus: int64 = 1
  var prime: int64 = 2
  while prime * prime <= remainingModulus:
    if remainingModulus mod prime == 0:
      var exponent = 0
      var primePower: int64 = 1
      while remainingModulus mod prime == 0:
        remainingModulus = remainingModulus div prime
        exponent += 1
        primePower = primePower * prime
      let residue = determinantForPrimePower(matrix, size, prime, exponent)
      if combinedModulus == 1:
        combinedResidue = residue mod primePower
        combinedModulus = primePower
      else:
        let inverseModulus = modInverse(combinedModulus mod primePower, primePower)
        let difference = ((residue - combinedResidue) mod primePower + primePower) mod primePower
        let step = (difference * inverseModulus) mod primePower
        combinedResidue = (combinedResidue + combinedModulus * step) mod (combinedModulus * primePower)
        combinedModulus = combinedModulus * primePower
    prime += 1
  if remainingModulus > 1:
    let residue = determinantForPrimePower(matrix, size, remainingModulus, 1)
    if combinedModulus == 1:
      combinedResidue = residue mod remainingModulus
      combinedModulus = remainingModulus
    else:
      let inverseModulus = modInverse(combinedModulus mod remainingModulus, remainingModulus)
      let difference = ((residue - combinedResidue) mod remainingModulus + remainingModulus) mod remainingModulus
      let step = (difference * inverseModulus) mod remainingModulus
      combinedResidue = (combinedResidue + combinedModulus * step) mod (combinedModulus * remainingModulus)
      combinedModulus = combinedModulus * remainingModulus
  return combinedResidue mod modulusValue
```

Trial division factors P quickly. Each new modulus is coprime with the running product. The final residue lies in the required range.

**Case driver.** Cases are parsed until tokens run out.

```nim
var allValues = newSeq[int64]()
var tokenPos = 0
while tokenPos < inputData.len:
  let current = inputData[tokenPos]
  if (current >= '0' and current <= '9') or current == '-':
    allValues.add nextInt(inputData, tokenPos)
  else:
    tokenPos += 1

var valuePos = 0
while valuePos < allValues.len:
  let matrixSize = int(allValues[valuePos])
  valuePos += 1
  let modulusValue = allValues[valuePos]
  valuePos += 1
  var matrix = newSeq[int64](matrixSize * matrixSize)
  for index in 0 .. matrixSize * matrixSize - 1:
    matrix[index] = allValues[valuePos]
    valuePos += 1
  let answer = determinantModulo(matrix, matrixSize, modulusValue)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The token list ends at EOF. Each case stores N squared entries. One residue line is written per case.

## Complexity

Each case factors P and eliminates the matrix once per prime power.

| phase | time | space |
|---|---|---|
| input read | one pass over integer tokens | input string and values |
| factorization | trial division up to square root of P | small factor list |
| elimination | O(k * N^3) modular operations | one N by N work matrix |
| recombination | one CRT merge per prime power | two residues |
| output | one line per case | block buffer |

The factor count stays small for moduli below one billion.

| measure | Big O |
|---|---|
| time | O(k * N^3) per case |
| space | O(N^2) |

Fraction-free integer elimination grows huge intermediate numbers and defeats this bound. Working in each prime-power ring keeps every product inside 64 bits.
