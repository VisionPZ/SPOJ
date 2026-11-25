# POLYMUL — Polynomial Multiplication (SPOJ)

<https://www.spoj.com/problems/POLYMUL/>

## Problem

Multiply two polynomials with integer coefficients and print every resulting coefficient. The coefficient lists are given from degree 0 upward.

Input starts with the test count T. Each case has the maximum degree n, then n + 1 coefficients for the first polynomial and n + 1 for the second. Output one line of 2n + 1 coefficients per case.

| item | bound |
|---|---|
| test count T | 1 to 10 |
| degree n | 0 to 10000 |
| input coefficient | 0 to 1000 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
2
2
1 2 3
3 2 1
2
1 0 1
2 1 0
```

Sample output:

```
3 8 14 8 3
2 1 2 1 0
```

## Idea

Convolution is like stacking two strips of stamps: each pair of positions lands on one output position. A number theoretic transform turns the stacking into pointwise multiplication, then turns it back.

Choose two primes whose roots of unity support a transform length of at least 2n + 1. Run a forward transform on each polynomial, multiply residues pointwise, and invert. Each coefficient stays below the product of the two primes, so the Chinese remainder theorem recovers it exactly. A direct double loop costs O(n^2) per case. Takeaway: transform, multiply, invert, then lift the residues into exact integers.

## Why It Works

1. Coefficient k of the product is the sum over i of left[i] times right[k - i].
2. The transform of a convolution equals the pointwise product of the two transforms.
3. Both chosen primes have a primitive 2^m-th root for every length needed here.
4. The largest coefficient is (n + 1) * 1000^2, which is below 11 billion.
5. The product of the two primes exceeds that bound, so one residue pair fixes each coefficient.

| term | meaning |
|---|---|
| `transformLength` | power of two at least 2n + 1 |
| `firstModulus` | prime 998244353 |
| `secondModulus` | prime 1004535809 |
| `rootStep` | current root of unity in the butterfly |
| `liftFactor` | coefficient reconstructed modulo the second prime |
| `exactValue` | final integer coefficient |

A script multiplies 1 + 2x + 3x^2 by 3 + 2x + x^2. The sums are 3, 1*2 + 2*3 = 8, 1*1 + 2*2 + 3*3 = 14, 2*1 + 3*2 = 8, and 3*1 = 3. That matches the sample line.

The transform stays in 64-bit arithmetic because each product of residues is below the square of a prime. No floating point rounding appears.

## Code

**Reader and modular power.** Input is loaded once, and powers are computed by repeated squaring.

```nim
const flushBlockBytes = 1 shl 17
const firstModulus = 998244353'i64
const secondModulus = 1004535809'i64
const primitiveRoot = 3'i64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc powerMod(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var basePart = baseValue mod modulus
  var exponentPart = exponentValue
  result = 1'i64
  while exponentPart > 0:
    if exponentPart mod 2 == 1:
      result = result * basePart mod modulus
    basePart = basePart * basePart mod modulus
    exponentPart = exponentPart div 2
```

Both primes support the required transform length.
`powerMod` supplies roots and modular inverses.
`nextInt` reads every coefficient without line assumptions.

**Transform and output helper.** Butterflies run in place with bit-reversed input.

```nim
proc transform(values: var seq[int64], length: int, invertTransform: bool, modulus: int64) =
  var reverseIndex = 0
  for index in 1 .. length - 1:
    var bit = length shr 1
    while (reverseIndex and bit) != 0:
      reverseIndex = reverseIndex xor bit
      bit = bit shr 1
    reverseIndex = reverseIndex or bit
    if index < reverseIndex:
      swap(values[index], values[reverseIndex])
  var blockLength = 2
  while blockLength <= length:
    var rootStep = powerMod(primitiveRoot, (modulus - 1) div blockLength, modulus)
    if invertTransform:
      rootStep = powerMod(rootStep, modulus - 2, modulus)
    var blockStart = 0
    while blockStart < length:
      var twist = 1'i64
      let halfBlock = blockLength shr 1
      for offset in 0 .. halfBlock - 1:
        let leftValue = values[blockStart + offset]
        let rightValue = values[blockStart + offset + halfBlock] * twist mod modulus
        var combined = (leftValue + rightValue) mod modulus
        var difference = (leftValue - rightValue) mod modulus
        if difference < 0:
          difference = difference + modulus
        values[blockStart + offset] = combined
        values[blockStart + offset + halfBlock] = difference
        twist = twist * rootStep mod modulus
      blockStart = blockStart + blockLength
    blockLength = blockLength shl 1
  if invertTransform:
    let lengthInverse = powerMod(int64(length), modulus - 2, modulus)
    for index in 0 .. length - 1:
      values[index] = values[index] * lengthInverse mod modulus

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The bit reversal reorders input for the iterative butterflies.
`invertTransform` selects inverse roots and scales by the length inverse.
`appendOutput` flushes coefficient blocks instead of single numbers.

**Case driver.** Two residue runs are lifted into exact coefficients.

```nim
let caseCount = nextInt(inputData, scanPos)
let firstInverse = powerMod(firstModulus mod secondModulus, secondModulus - 2, secondModulus)
for caseIndex in 0 .. caseCount - 1:
  let degree = int(nextInt(inputData, scanPos))
  var firstPoly = newSeq[int64](degree + 1)
  var secondPoly = newSeq[int64](degree + 1)
  for coefficientIndex in 0 .. degree:
    firstPoly[coefficientIndex] = nextInt(inputData, scanPos)
  for coefficientIndex in 0 .. degree:
    secondPoly[coefficientIndex] = nextInt(inputData, scanPos)
  var transformLength = 1
  while transformLength < 2 * degree + 1:
    transformLength = transformLength shl 1
  var firstPart = newSeq[int64](transformLength)
  var secondPart = newSeq[int64](transformLength)
  for coefficientIndex in 0 .. degree:
    firstPart[coefficientIndex] = firstPoly[coefficientIndex] mod firstModulus
    secondPart[coefficientIndex] = secondPoly[coefficientIndex] mod firstModulus
  transform(firstPart, transformLength, false, firstModulus)
  transform(secondPart, transformLength, false, firstModulus)
  for coefficientIndex in 0 .. transformLength - 1:
    firstPart[coefficientIndex] = firstPart[coefficientIndex] * secondPart[coefficientIndex] mod firstModulus
  transform(firstPart, transformLength, true, firstModulus)
  var secondResult = newSeq[int64](transformLength)
  secondPart = newSeq[int64](transformLength)
  for coefficientIndex in 0 .. degree:
    secondResult[coefficientIndex] = firstPoly[coefficientIndex] mod secondModulus
    secondPart[coefficientIndex] = secondPoly[coefficientIndex] mod secondModulus
  transform(secondResult, transformLength, false, secondModulus)
  transform(secondPart, transformLength, false, secondModulus)
  for coefficientIndex in 0 .. transformLength - 1:
    secondResult[coefficientIndex] = secondResult[coefficientIndex] * secondPart[coefficientIndex] mod secondModulus
  transform(secondResult, transformLength, true, secondModulus)
  for coefficientIndex in 0 .. 2 * degree:
    let residueGap = (secondResult[coefficientIndex] - firstPart[coefficientIndex]) mod secondModulus
    var liftFactor = 0'i64
    if residueGap < 0:
      liftFactor = (residueGap + secondModulus) * firstInverse mod secondModulus
    else:
      liftFactor = residueGap * firstInverse mod secondModulus
    let exactValue = firstPart[coefficientIndex] + firstModulus * liftFactor
    if coefficientIndex > 0:
      outputBuffer.add ' '
    appendOutput($exactValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`secondPart` is reset before the second modulus run.
`firstInverse` is the inverse of the first prime modulo the second prime.
The final loop prints 2n + 1 coefficients with single spaces.

## Complexity

Each case runs six transforms of length L, where L is the next power of two above 2n + 1.

| phase | time | space |
|---|---|---|
| parse coefficients | one pass over 2n + 2 values | two polynomial arrays |
| two transform passes | six transforms of length L | two arrays of length L |
| CRT and output | one pass over 2n + 1 coefficients | one output string |

| measure | Big O |
|---|---|
| time | O(T * L log L) |
| space | O(L) |

A direct double loop costs O(n^2) per case and dominates for degree 10000. Takeaway: two exact residue runs recover every coefficient without rounding.
