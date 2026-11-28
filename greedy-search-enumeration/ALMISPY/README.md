# ALMISPY — Almost-isosceles Pythagorean triple (easy) (SPOJ)

<https://www.spoj.com/problems/ALMISPY/>

## Problem

An almost-isosceles Pythagorean triple has legs a and a + 1 and hypotenuse c. Given the rank n and a modulus m, print a and c for the n-th triple in increasing order, each reduced modulo m.

Input starts with the number of test cases. Each case gives n and m on one line. Print two integers per case, the reduced leg and the reduced hypotenuse.

| item | bound |
|---|---|
| test cases | 1 to 9999 |
| rank n | 1 to 10^18 |
| modulus m | 2 to 10^9 - 1 |
| judge limit | 1110 ms, 1536 MB |

The rank bound requires a logarithmic method, since writing out the triples one by one cannot finish.

Sample input:

```
3
1 10
2 123
4 289
```

Sample output:

```
3 5
20 29
118 118
```

The fourth triple is far larger than its reduced output suggests.

## Idea

Picture each triple as one step along a fixed ladder, like climbing stairs where each step is built from the previous one by the same rule. Substituting x = 2a + 1 turns the Pythagorean equation into the negative Pell equation x squared minus 2 c squared equals minus 1. Those solutions follow a two-term recurrence, so a matrix power jumps straight to rank n in O(log n) steps. Iterating the recurrence would take O(n) steps and cannot reach 10^18. The modulus is doubled so the leg can be halved exactly at the end.

## Why It Works

1. Expanding a squared plus (a + 1) squared gives (2a + 1) squared plus 1, all over 2.
2. Setting x = 2a + 1 turns the equation into x squared minus 2 c squared equals minus 1.
3. The positive solutions of that equation start at x = 7, c = 5 and follow x next = 3x + 4c and c next = 2x + 3c.
4. The affine recurrence for the leg is a next = 3a + 2c + 1, with the first leg equal to 3.
5. Because x is odd, reducing it modulo 2m and then subtracting 1 and halving gives a modulo m.

| term | meaning |
|---|---|
| oddTerm | x reduced modulo twice the modulus |
| hypotenuse | c reduced modulo twice the modulus |
| doubledModulus | 2m, chosen so halving stays exact |
| base | the two-by-two step matrix |

The table names the values used to turn a Pell step into a modular answer.

The generator traces the first four exact triples as follows:

```
first legs: [(3, 5), (20, 29), (119, 169), (696, 985)]
```

Reducing the fourth pair modulo 289 gives 118 and 118, matching the sample.

Each matrix multiplication works on values below 2m, so a product stays below 4 times 10^18. That fits a signed 64-bit integer.

## Code

**Input and matrix product.** The reader takes both query values, and the product stays modular.

```nim
const flushBlockBytes = 1 shl 17

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

proc multiplyMatrices(first: array[4, int64], second: array[4, int64], modulus: int64): array[4, int64] =
  result[0] = (first[0] * second[0] + first[1] * second[2]) mod modulus
  result[1] = (first[0] * second[1] + first[1] * second[3]) mod modulus
  result[2] = (first[2] * second[0] + first[3] * second[2]) mod modulus
  result[3] = (first[2] * second[1] + first[3] * second[3]) mod modulus
```

The four entries encode a two-by-two matrix.
Every sum is reduced before it is stored.
Using 64-bit integers keeps the products exact.

**Matrix power.** Repeated squaring applies the step rank minus one times.

```nim
proc matrixPower(base: array[4, int64], exponentValue: int64, modulus: int64): array[4, int64] =
  result = [1'i64, 0'i64, 0'i64, 1'i64]
  var factor = base
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      result = multiplyMatrices(result, factor, modulus)
    factor = multiplyMatrices(factor, factor, modulus)
    remaining = remaining div 2
```

The identity matrix starts the accumulator.
Bits of the exponent choose which powers are multiplied in.
About sixty squarings cover the largest rank.

**Query loop.** Each case rebuilds the transformed pair and writes one buffered line.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rank = int64(nextInt(inputData, scanPos))
  let modulus = int64(nextInt(inputData, scanPos))
  let doubledModulus = 2 * modulus
  let base = [3'i64, 4'i64, 2'i64, 3'i64]
  let powered = matrixPower(base, rank - 1, doubledModulus)
  let oddTerm = (powered[0] * 7'i64 + powered[1] * 5'i64) mod doubledModulus
  let hypotenuse = (powered[2] * 7'i64 + powered[3] * 5'i64) mod doubledModulus
  let leg = ((oddTerm - 1) div 2) mod modulus
  appendOutput($leg)
  outputBuffer.add ' '
  appendOutput($(hypotenuse mod modulus))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The step matrix comes from the Pell recurrence.
Doubling the modulus makes the final halving lossless.
The hypotenuse is reduced once more to the real modulus.
Both values are written on one line.

## Complexity

Repeated squaring sets the cost of each query.

| phase | time | space |
|---|---|---|
| input read | one pass over query pairs | one input string |
| matrix power | O(log n) two-by-two products | constant scratch |
| output | one line per case | block buffer |

All cases have the same small constant work per exponent bit.

| measure | Big O |
|---|---|
| time per case | O(log n) |
| space per case | O(1) |

Walking the recurrence one triple at a time would cost O(n) per case and cannot reach rank 10^18.

Matrix powering turns a huge rank into a few dozen modular products.
