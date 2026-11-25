# HIGH — Highways (SPOJ)
<https://www.spoj.com/problems/HIGH/>

## Problem

A country lists the city pairs that may get highways. It asks how many networks connect every city with exactly one path between any pair. Each network is a different subset of the listed links.

The input starts with a test count of about 1000. Each case gives a city count n from 1 to 12 and a link count, then one link per line. City numbers run from 1 to n, and a blank line separates cases. Print one count per case, which fits a signed 64-bit integer. A single city has answer 1.

The judge limits are:

| Item | Value |
| --- | --- |
| Test cases | about 1000 |
| Cities n | 1 to 12 |
| Answer | fits a signed 64-bit integer |
| Time limit | 7 s |
| Memory limit | 1536 MB |

The small city count makes a matrix method practical.

The sample input reads:

```text
4
4 5
3 4
4 2
2 3
1 2
1 3

2 1
2 1

1 0

3 3
1 2
2 3
3 1

```

The sample output reads:

```text
8
1
1
3
```

## Idea

Turn the link list into a degree-and-minus-one matrix, like copying a wiring diagram into a table. The matrix-tree theorem (a rule linking determinants to spanning trees) says one determinant of that matrix counts the networks. Compute the determinant modulo two large primes. Combine the remainders with the Chinese remainder theorem (rebuilding a number from two remainders). Each determinant costs O(n³) operations. Enumerating all link subsets would cost O(2^m). Takeaway: build the matrix, take two determinants, and rebuild the exact answer.

## Why It Works

1. The matrix has each city's degree on the diagonal and minus one wherever a link meets another city.
2. Deleting one row and column gives a cofactor whose determinant counts spanning trees.
3. Each spanning tree contributes exactly one to the determinant expansion.
4. Modular Gaussian elimination (row reduction inside a prime modulus) computes the determinant without huge integers.
5. Fermat inversion gives each pivot's inverse because both moduli are prime, and a row swap flips the determinant's sign.
6. The answer is below the product of the two primes, so two remainders determine it uniquely.
7. The reconstruction uses `difference = r2 - r1 (mod m2)`, `multiplier = difference * m1^-1 (mod m2)`, and `answer = r1 + m1 * multiplier`.

The table defines the terms.

| Term | Meaning |
| --- | --- |
| cofactor | matrix with one row and column removed |
| `firstModulus` | prime 1000000007 |
| `secondModulus` | prime 1000000009 |
| `modPower` | fast modular exponentiation for inverses |

These four terms describe the reconstruction.

A script computed the first sample case, with four cities and five links.

| Quantity | Value |
| --- | --- |
| Determinant mod 1000000007 | 8 |
| Determinant mod 1000000009 | 8 |
| Difference | 0 |
| Multiplier | 0 |
| Reconstructed answer | 8 |

The program prints 8, which matches the sample.

## Code

**Input and scanner.** The program reads all input once and skips blank lines while parsing.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCities = 12
const firstModulus: int64 = 1000000007
const secondModulus: int64 = 1000000009

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

Every input number is non-negative, so the scanner needs no sign branch. Blank lines contain no digits and are skipped automatically. Parsing one number visits each digit once.

**Modular determinant.** Fermat inversion and elimination form one determinant.

```nim
proc modPower(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var baseRemainder = baseValue mod modulus
  if baseRemainder < 0:
    baseRemainder += modulus
  var result: int64 = 1
  var walker = exponentValue
  while walker > 0:
    if (walker and 1) == 1:
      result = result * baseRemainder mod modulus
    baseRemainder = baseRemainder * baseRemainder mod modulus
    walker = walker shr 1
  return result

proc determinantModulo(matrix: array[maxCities, array[maxCities, int64]],
                       size: int, modulus: int64): int64 =
  var work: array[maxCities, array[maxCities, int64]]
  for i in 0..<size:
    for j in 0..<size:
      work[i][j] = matrix[i][j] mod modulus
      if work[i][j] < 0:
        work[i][j] += modulus
  var result: int64 = 1
  for i in 0..<size:
    var j = i
    while j < size and work[j][i] == 0:
      j += 1
    if j == size:
      return 0
    if j != i:
      for k in 0..<size:
        swap work[i][k], work[j][k]
      result = modulus - result
    let pivotValue = work[i][i]
    result = result * pivotValue mod modulus
    let inversePivot = modPower(pivotValue, modulus - 2, modulus)
    for k in i + 1..<size:
      if work[k][i] == 0:
        continue
      let factor = work[k][i] * inversePivot mod modulus
      for l in i..<size:
        work[k][l] = (work[k][l] - factor * work[i][l]) mod modulus
        if work[k][l] < 0:
          work[k][l] += modulus
  return result
```

Reduction happens after every subtraction, so no intermediate value exceeds the modulus squared. A zero column makes the determinant zero. Row swaps track the sign. Exponentiation scans the bits of the exponent.

**Reconstruction.** Two remainders combine into the exact answer.

```nim
proc spanningTreeCount(matrix: array[maxCities, array[maxCities, int64]],
                       size: int): int64 =
  let firstRemainder = determinantModulo(matrix, size, firstModulus)
  let secondRemainder = determinantModulo(matrix, size, secondModulus)
  let difference = (secondRemainder - firstRemainder + secondModulus) mod secondModulus
  let inverseFirst = modPower(firstModulus mod secondModulus,
                              secondModulus - 2, secondModulus)
  let multiplier = difference * inverseFirst mod secondModulus
  return firstRemainder + firstModulus * multiplier
```

The inverse is taken modulo the second prime, and the multiplier scales the first prime. Swapping those two would produce a large meaningless value. Both determinants use the same cofactor matrix.

**Driver.** The loop builds the cofactor and writes buffered answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let cityCount = nextInt(inputData, i)
  let connectionCount = nextInt(inputData, i)
  var matrix: array[maxCities, array[maxCities, int64]]
  for k in 0..<cityCount - 1:
    for l in 0..<cityCount - 1:
      matrix[k][l] = 0
  for k in 0..<connectionCount:
    let firstCity = nextInt(inputData, i) - 1
    let secondCity = nextInt(inputData, i) - 1
    if firstCity < cityCount - 1:
      matrix[firstCity][firstCity] += 1
      if secondCity < cityCount - 1:
        matrix[firstCity][secondCity] -= 1
    if secondCity < cityCount - 1:
      matrix[secondCity][secondCity] += 1
      if firstCity < cityCount - 1:
        matrix[secondCity][firstCity] -= 1
  if cityCount == 1:
    appendOutput("1")
  else:
    appendOutput($spanningTreeCount(matrix, cityCount - 1))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Links to the deleted last city are dropped from the cofactor. The matrix is rebuilt per case because sizes differ. A single city takes the direct answer branch. Output is written in blocks.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Build cofactor | O(m) | O(n²) |
| One determinant | O(n³ log p) | O(n²) |
| Reconstruct answer | O(log p) | O(1) |

Elimination dominates one case.

The exponent bit length log p is at most 31 for these primes.

| Measure | Bound |
| --- | --- |
| Per case | O(m + n³ log p) time |
| Per case | O(n²) space |
| Determinants | two per case |

Enumerating link subsets would cost O(2^m) per case and quickly becomes impossible.
