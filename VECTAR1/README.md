# VECTAR1 — Matrices with XOR property (SPOJ)

<https://www.spoj.com/problems/VECTAR1/>

## Problem

Fill an N by M matrix with the distinct numbers 1 to N times M. Whenever cell (i, j) has a larger bitwise xor value i xor j than another cell, its number must also be larger. Count the valid matrices modulo 1000000007.

The input starts with the test count T. Each test then supplies N on one line and M on the next. Print one count per test in input order.

| item | bound |
|---|---|
| tests T | 1 to 1000 |
| rows N | 1 to 1000 |
| columns M | 1 to 1000 |
| judge limit | 2000 ms, 1536 MB |

Every dimension stays inside these bounds.

Sample input:

```
1
2
2
```

Sample output:

```
4
```

The four matrices are [1 3; 4 2], [2 3; 4 1], [1 4; 3 2] and [2 4; 3 1].

## Idea

Cells with the same xor value form one pile, like sorting cards into labeled stacks before numbering the whole deck. The rule orders whole piles but never orders cards inside a pile. A Walsh transform counts every pile size in one xor convolution, and the answer is the product of those factorials. A direct double loop over all cells costs N times M per test and repeats that scan for every case.

## Why It Works

1. Two cells share an ordering class exactly when their xor values match.
2. The rule compares different classes only, so a class has no internal order constraint.
3. Sorted numbers split into contiguous blocks, one block per class.
4. A class of size c therefore contributes c! distinct assignments inside its block.
5. The xor convolution of row and column indicators gives every class size at once.
6. The Walsh transform computes that convolution, and its inverse divides by the transform size.

| term | meaning |
|---|---|
| `rowFlags` | indicator array for rows, then transformed counts |
| `columnFlags` | indicator array for columns |
| `forwardTransform` | in-place Walsh transform over 1024 slots |
| `factorials` | precomputed factorials modulo the modulus |
| `resultValue` | running product of class factorials |

The sample has two nonempty classes.

| xor value | cells | size | factorial |
|---|---|---|---|
| 0 | (1, 1), (2, 2) | 2 | 2 |
| 3 | (1, 2), (2, 1) | 2 | 2 |
| others | none | 0 | skipped |

The product 2 times 2 gives the four valid matrices.

## Code

**Input, scanner, helper and transform.** The transform size is fixed at 1024 slots.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const transformSize = 1024
const maxDimension = 1000

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

proc forwardTransform(values: var seq[int64]) =
  var blockSize = 1
  while blockSize < transformSize:
    var blockStart = 0
    while blockStart < transformSize:
      for offset in 0 .. blockSize - 1:
        let leftValue = values[blockStart + offset]
        let rightValue = values[blockStart + offset + blockSize]
        values[blockStart + offset] = leftValue + rightValue
        values[blockStart + offset + blockSize] = leftValue - rightValue
      blockStart += blockSize * 2
    blockSize *= 2
```

The transform uses additions and subtractions only.
Applying it twice undoes itself up to a scale factor.
All 1024 xor values fit because dimensions stop at 1000.

**Factorials and convolution.** One precomputed table serves every test.

```nim
var factorials = newSeq[int64](maxDimension + 1)
factorials[0] = 1
for valueIndex in 1 .. maxDimension:
  factorials[valueIndex] = (factorials[valueIndex - 1] * int64(valueIndex)) mod int64(answerModulus)

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var rowFlags = newSeq[int64](transformSize)
  var columnFlags = newSeq[int64](transformSize)
  for rowIndex in 1 .. rowCount:
    rowFlags[rowIndex] = 1
  for columnIndex in 1 .. columnCount:
    columnFlags[columnIndex] = 1
  forwardTransform(rowFlags)
  forwardTransform(columnFlags)
  for cellIndex in 0 .. transformSize - 1:
    rowFlags[cellIndex] = rowFlags[cellIndex] * columnFlags[cellIndex]
  forwardTransform(rowFlags)
  var resultValue: int64 = 1
  for cellIndex in 0 .. transformSize - 1:
    let frequency = int(rowFlags[cellIndex] div int64(transformSize))
    if frequency > 0:
      resultValue = (resultValue * factorials[frequency]) mod int64(answerModulus)
  appendOutput($resultValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each class size is at most 1000, so the factorial table suffices.
The second transform divides the squared counts back into class sizes.
Each test writes one buffered answer.

## Complexity

The factorial table is shared; the convolution runs per test.

| phase | time | space |
|---|---|---|
| factorial table | one multiplication per value up to 1000 | table of factorials |
| convolution | three transforms over 1024 slots | two indicator arrays |
| output | one line per test | block buffer |

The transform size is a fixed power of two.

| measure | Big O |
|---|---|
| time | O(1000 + T times 1024 times 10) |
| space | O(1024) besides the input |

Counting all cell pairs takes O(N times M) per test and grows with the dimensions.
The fixed-size transform replaces that scan with about ten thousand operations per test.
