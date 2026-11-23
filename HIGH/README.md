## Problem

Read several undirected graphs with at most 12 vertices. Count how many subsets of the given edges form a spanning tree: every vertex connected and exactly one path between any two vertices. Print one count per graph. A graph with one city has answer one.

| Quantity | Bound |
| --- | --- |
| Test cases | about 1000 |
| Cities `n` | 1 to 12 |
| Answer | fits a signed 64-bit integer |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

A blank line separates consecutive test cases.

## Idea

Apply the matrix-tree theorem. Delete one row and column from the graph Laplacian; the remaining determinant equals the number of spanning trees. Compute that determinant modulo two large primes, then reconstruct the exact value with the Chinese remainder theorem.

Each determinant costs O(n³) modular operations, so the cost per graph is O(n³). Enumerating all edge subsets would cost O(2ᵐ).

## Why It Works

The Laplacian has degree on the diagonal and minus one for each edge. Its cofactor counts spanning trees because each spanning tree contributes exactly one to the determinant expansion. The answer is below both primes' product, so two residues determine it uniquely.

The reconstruction rule is:

- `difference = r2 − r1 (mod m2)`
- `multiplier = difference · m1⁻¹ (mod m2)`
- `answer = r1 + m1 · multiplier`

Modular Gaussian elimination uses Fermat inversion because both moduli are prime. Row swaps flip the sign of the determinant.

## Code

Input is read once and parsed with a digit scanner that skips the blank lines.

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

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

Every input number is non-negative, so the scanner needs no sign branch. Parsing one number visits each digit once.

Fermat inversion and modular elimination form the first determinant.

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
  for row in 0..<size:
    for column in 0..<size:
      work[row][column] = matrix[row][column] mod modulus
      if work[row][column] < 0:
        work[row][column] += modulus
  var result: int64 = 1
  for pivot in 0..<size:
    var pivotRow = pivot
    while pivotRow < size and work[pivotRow][pivot] == 0:
      pivotRow += 1
    if pivotRow == size:
      return 0
    if pivotRow != pivot:
      for column in 0..<size:
        swap work[pivot][column], work[pivotRow][column]
      result = modulus - result
    let pivotValue = work[pivot][pivot]
    result = result * pivotValue mod modulus
    let inversePivot = modPower(pivotValue, modulus - 2, modulus)
    for row in pivot + 1..<size:
      if work[row][pivot] == 0:
        continue
      let factor = work[row][pivot] * inversePivot mod modulus
      for column in pivot..<size:
        work[row][column] = (work[row][column] - factor * work[pivot][column]) mod modulus
        if work[row][column] < 0:
          work[row][column] += modulus
  return result
```

Reduction happens after every subtraction, so no intermediate value exceeds the modulus squared. A zero column makes the determinant zero. Row swaps track the sign.

The two residues combine into the exact answer.

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

The inverse is taken modulo the second prime, and the multiplier multiplies the first prime. Swapping those two would produce a large meaningless value.

The driver builds the Laplacian cofactor and writes the answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  let connectionCount = nextInt(inputData, scanPos)
  var matrix: array[maxCities, array[maxCities, int64]]
  for row in 0..<cityCount - 1:
    for column in 0..<cityCount - 1:
      matrix[row][column] = 0
  for connectionIndex in 0..<connectionCount:
    let firstCity = nextInt(inputData, scanPos) - 1
    let secondCity = nextInt(inputData, scanPos) - 1
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

Edges touching the last city still raise that city's degree, but its row and column are absent from the cofactor. The matrix is rebuilt per case because sizes differ. Output is written in blocks.

## Complexity

Building the cofactor costs O(m). Each modular determinant costs O(n³ log p) for exponent bit length log p, and two are computed. Total time is O(m + n³ log p) per case and space is O(n²). Enumerating edge subsets would cost O(2ᵐ).
