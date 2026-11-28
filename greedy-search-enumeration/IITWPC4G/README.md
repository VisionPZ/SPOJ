# IITWPC4G — Maggu and Weird things (SPOJ)

<https://www.spoj.com/problems/IITWPC4G/>

## Problem

Apply a two-step array transformation m times and print the final values modulo 1000000007. Step one forms each new entry from an alternating cyclic sum of k entries, and step two swaps every adjacent pair.

Input begins with T. Each case gives n, k, m, then n integers seq[i]; n is even. Print n space-separated integers, the array after m super operations, each reduced modulo 1000000007.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| array length n | even, 1 to 50 |
| window k | 1 to n |
| repetitions m | 1 to 1000000000 |
| judge limit | 3000 ms, 1536 MB |

The large repetition count rules out a loop that runs m times.

Sample input:

```
1
4 3 1
2 4 -3 5
```

Sample output:

```
12 1000000002 7 1000000001
```

## Idea

Treat the whole super operation as one matrix, like a machine that transforms a row of beads in a fixed way. Repeating the operation m times then means multiplying by that matrix m times, which binary exponentiation does in logarithmic steps.

The algorithm builds the n by n transformation matrix and applies its m-th power to the vector. A matrix square costs O(n^3) and there are O(log m) squares. Simulating m operations directly would cost O(m n k), impossible when m reaches 10^9.

A linear map turns a billion repetitions into about thirty matrix squarings.

## Why It Works

1. Step one is linear: each entry is a signed sum of k cyclic entries.
2. Step two only permutes entries, so it is linear too.
3. Their composition is a single matrix T with T[i][j] determined by j minus (i xor 1) modulo n.
4. The offset is (j - source) mod n; it contributes plus one when even and minus one when odd, but only when it is below k.
5. Binary exponentiation applies powers T, T^2, T^4 and so on to the vector, using one matrix square per bit.
6. Reducing after each product keeps every intermediate below 1000000007 squared, which fits in int64.

| term | meaning |
|---|---|
| `transform` | the flat n by n matrix of one super operation |
| `sourceIndex` | i xor 1, the temporary entry that moves to position i |
| `exponent` | remaining repetitions during exponentiation |
| `stateVector` | array after the powers applied so far |

The table terms follow the main loop exactly.

The worked trace uses the sample with n = 4, k = 3, m = 1:

```
step one from [2, 4, -3, 5] gives [-5, 12, -6, 7]
step two swaps adjacent pairs, giving [12, -5, 7, -6]
reduce modulo 1000000007: [12, 1000000002, 7, 1000000001]
```

The trace matches the sample output.

Negative inputs are normalized before exponentiation, so subtraction stays exact modulo the prime.

## Code

**Input, reduction and matrix arithmetic.** The reader normalizes signed values, then matrix products use modular accumulation.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var negativeValue = false
  if pos < data.len and data[pos] == '-':
    negativeValue = true
    pos += 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value

proc reduceValue(value: int64): int64 =
  var reduced = value mod modulusValue
  if reduced < 0:
    reduced += modulusValue
  return reduced

proc multiplyMatrices(leftMatrix: seq[int64], rightMatrix: seq[int64], size: int): seq[int64] =
  var productMatrix = newSeq[int64](size * size)
  for rowIndex in 0 .. size - 1:
    for middleIndex in 0 .. size - 1:
      let leftValue = leftMatrix[rowIndex * size + middleIndex]
      if leftValue == 0:
        continue
      for columnIndex in 0 .. size - 1:
        let cellIndex = rowIndex * size + columnIndex
        productMatrix[cellIndex] = (productMatrix[cellIndex] +
          leftValue * rightMatrix[middleIndex * size + columnIndex]) mod modulusValue
  return productMatrix

proc applyMatrix(matrix: seq[int64], vector: seq[int64], size: int): seq[int64] =
  var resultVector = newSeq[int64](size)
  for rowIndex in 0 .. size - 1:
    var accumulated: int64 = 0
    for columnIndex in 0 .. size - 1:
      accumulated = (accumulated +
        matrix[rowIndex * size + columnIndex] * vector[columnIndex]) mod modulusValue
    resultVector[rowIndex] = accumulated
  return resultVector
```

The scanner reads the optional sign before digits.
A flat sequence stores each matrix in row-major order.
Every accumulation reduces modulo the prime.

**Build and exponentiate.** Each case builds one matrix, applies powers to the vector, then writes the result.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sequenceLength = nextInt(inputData, scanPos)
  let windowLength = nextInt(inputData, scanPos)
  let operationCount = int64(nextInt(inputData, scanPos))
  var stateVector = newSeq[int64](sequenceLength)
  for elementIndex in 0 .. sequenceLength - 1:
    stateVector[elementIndex] = reduceValue(int64(nextInt(inputData, scanPos)))
  var transform = newSeq[int64](sequenceLength * sequenceLength)
  for rowIndex in 0 .. sequenceLength - 1:
    let sourceIndex = rowIndex xor 1
    for columnIndex in 0 .. sequenceLength - 1:
      let offset = (columnIndex - sourceIndex + sequenceLength) mod sequenceLength
      if offset < windowLength:
        if offset mod 2 == 0:
          transform[rowIndex * sequenceLength + columnIndex] = 1
        else:
          transform[rowIndex * sequenceLength + columnIndex] = modulusValue - 1
  var exponent = operationCount
  while exponent > 0:
    if exponent mod 2 == 1:
      stateVector = applyMatrix(transform, stateVector, sequenceLength)
    transform = multiplyMatrices(transform, transform, sequenceLength)
    exponent = exponent div 2
  for elementIndex in 0 .. sequenceLength - 1:
    if elementIndex > 0:
      appendOutput(" ")
    appendOutput($stateVector[elementIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`sourceIndex` encodes the adjacent swap from step two.
Each exponent bit either applies a power or advances the square.
One buffered line holds the whole final array.

## Complexity

Each case builds a matrix, then squares it once per bit of m.

| phase | time | space |
|---|---|---|
| input read | one pass over all cases | one input string |
| matrix build | O(n^2) entries | n squared slots |
| exponentiation | O(n^3 log m) | n squared slots |
| output | one buffered line per case | block buffer |

Matrix squaring dominates, and its count equals the bit length of m.

| measure | Big O |
|---|---|
| time | O(n^3 log m) per case |
| space | O(n^2) per case |

Direct simulation costs O(m n k), which cannot finish for m near 10^9, while exponentiation uses about thirty squares.
