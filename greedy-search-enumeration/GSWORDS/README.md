# GSWORDS — Counting Words (SPOJ)

<https://www.spoj.com/problems/GSWORDS/>

## Problem

Count strings of length N over `o` and `x` such that every prime-length block has at least as many `o` as `x`. Report the count modulo 1 000 000 007.

Input is a single integer N. Output is a single integer, the count modulo 1 000 000 007.

| item | bound |
|---|---|
| length N | 1 to 1000000000000 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

The length bound drives the design: linear iteration cannot reach N = 10^12.

Sample input:

```
2
```

Sample output:

```
3
```

## Idea

Keep `x` letters at least three places apart, like parking cars with two empty spaces between them. That local rule enforces every prime-length condition, so a short recurrence counts all valid words. Matrix exponentiation raises the three-state transition to the N-th position in logarithmic time. A linear scan would need one step per position and cannot finish for large N. Takeaway: count separated letters with a fast matrix power.

## Why It Works

1. A prime window of length 2 forbids `xx`, so two `x` letters cannot be adjacent.
2. A prime window of length 3 forbids `xox`, so two `x` letters cannot be two places apart.
3. Any window of length p contains at most `ceil(p/3)` letters `x`, which never exceeds `floor(p/2)`.
4. Therefore every prime window has at least as many `o` as `x` exactly when `x` letters stay three places apart.
5. Appending `o` keeps every valid word valid, and appending `x` requires the last two letters to be `o`.

| term | meaning |
|---|---|
| `wordLength` | requested length N |
| `countWords` | number of valid words of a given length |
| `transitionMatrix` | one-step transition on the last three counts |
| `modulusValue` | 1000000007, the output modulus |

The three table states count words ending with `o`, `ox`, and `oox` in that order.

A script trace for small lengths:

```
length : count
1      : 2
2      : 3
3      : 4
4      : 6
5      : 9
6      : 13
```

Each value equals the previous value plus the value three positions earlier.

All arithmetic stays below the modulus after each addition, and no rounding occurs.

## Code

**Input and hand scanner.** The reader loads the single length and parses it one digit at a time.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007'i64
const matrixSize = 3

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

The scanner skips non-digit bytes and returns the parsed length.
The buffer collects all input in one pass.
The constants set the flush size, modulus, and matrix dimension.

**Matrix arithmetic.** Multiplication and binary powering work on three-by-three matrices.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type
  SquareMatrix = array[matrixSize, array[matrixSize, int64]]

proc multiplyMatrices(leftMatrix: SquareMatrix, rightMatrix: SquareMatrix): SquareMatrix =
  for rowIndex in 0 .. matrixSize - 1:
    for colIndex in 0 .. matrixSize - 1:
      var cellValue: int64 = 0
      for innerIndex in 0 .. matrixSize - 1:
        cellValue = (cellValue + leftMatrix[rowIndex][innerIndex] * rightMatrix[innerIndex][colIndex]) mod modulusValue
      result[rowIndex][colIndex] = cellValue

proc powerMatrix(baseMatrix: SquareMatrix, exponentValue: int64): SquareMatrix =
  var accumulated: SquareMatrix
  for rowIndex in 0 .. matrixSize - 1:
    for colIndex in 0 .. matrixSize - 1:
      if rowIndex == colIndex:
        accumulated[rowIndex][colIndex] = 1
      else:
        accumulated[rowIndex][colIndex] = 0
  var runningBase = baseMatrix
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1'i64) != 0:
      accumulated = multiplyMatrices(accumulated, runningBase)
    remainingExponent = remainingExponent div 2
    if remainingExponent > 0:
      runningBase = multiplyMatrices(runningBase, runningBase)
  return accumulated
```

Each cell reduces modulo `modulusValue` after three products.
Binary powering needs one squaring per exponent bit.
The identity start makes an exponent of zero work.

**Count and output.** The transition encodes the recurrence and produces the answer.

```nim
proc countWords(lengthValue: int64): int64 =
  if lengthValue == 0:
    return 1
  if lengthValue == 1:
    return 2
  if lengthValue == 2:
    return 3
  var transitionMatrix: SquareMatrix
  transitionMatrix[0][0] = 1
  transitionMatrix[0][1] = 0
  transitionMatrix[0][2] = 1
  transitionMatrix[1][0] = 1
  transitionMatrix[1][1] = 0
  transitionMatrix[1][2] = 0
  transitionMatrix[2][0] = 0
  transitionMatrix[2][1] = 1
  transitionMatrix[2][2] = 0
  let poweredMatrix = powerMatrix(transitionMatrix, lengthValue - 2)
  return (poweredMatrix[0][0] * 3 + poweredMatrix[0][1] * 2 + poweredMatrix[0][2]) mod modulusValue

let wordLength = nextInt(inputData, scanPos)
appendOutput($countWords(int64(wordLength)))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Lengths below three return known constants.
The last vector holds the counts for lengths zero, one, and two.
One buffer write emits the single answer line.

## Complexity

The matrix power replaces a linear scan with a logarithmic one.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| matrix power | O(27 log N) modular products | two 3x3 matrices |
| output | one line | block buffer |

The power uses only a constant number of cells.

| measure | Big O |
|---|---|
| time | O(log N) |
| space | O(1) |

A linear recurrence scan would take O(N) steps and stall at N = 10^12. Takeaway: matrix powering makes the full length range practical.
