# ADASQR — Ada and Squares (SPOJ)

<https://www.spoj.com/problems/ADASQR/>

## Problem

An N by N field has a generated height in every cell. Sum the smallest height of each K by K subsquare, modulo 1000000007.

The first line gives N and K. Each following line gives x0, a, b and c; row values follow x next equals x times a plus b, modulo c. Output one integer, the sum of all subsquare minima.

| item | bound |
|---|---|
| field size N | 1 to 5000 |
| window size K | 1 to N |
| generator values | 0 to 10 to the 18 |
| judge limit | 4000 ms, 1536 MB |

The field size drives the design; the generator values need wide arithmetic.

Sample input:

```
4 2
8 2 9 9
5 7 9 3
9 7 7 5
7 4 7 3
```

Sample output:

```
6
```

## Idea

Shrink each row to its sliding minima, then shrink those results down the columns, like folding a map twice. Each pass uses a monotonic deque and touches every cell once. The first pass gives the minimum of each K cell row segment. The second pass turns those into the minimum of each K by K square. A fresh scan of every square costs K squared times more work. Two folds produce the answer in linear time per cell.

## Why It Works

1. Row generation uses modular multiplication of values up to 10 to the 18.
2. A monotonic deque holds candidate column indexes in increasing height order.
3. After the row pass, each value is the minimum of a K cell horizontal segment.
4. The minimum of a K by K square is the minimum of K of those row values.
5. The column pass applies the same deque to those K values.
6. Adding each output value modulo `resultModulo` gives the required sum.

| term | meaning |
|---|---|
| `windowSize` | side length K of a subsquare |
| `windowCount` | number of windows per row or column |
| `rowMinimums` | horizontal K cell minima for every row |
| `windowQueue` | deque of indexes reused by both passes |
| `totalMinimums` | running sum modulo `resultModulo` |

The two deques implement one shared idea at two scales.

A script trace of the sample after the row pass:

| row | generated row | row minima for K equals 2 |
|---|---|---|
| 0 | 8 7 5 1 | 7 5 1 |
| 1 | 5 2 2 2 | 2 2 2 |
| 2 | 9 0 2 1 | 0 0 1 |
| 3 | 7 2 0 1 | 2 0 0 |

The column windows add two plus two plus two, which equals the sample answer six.

The emitted product uses a wide C integer, so values near 10 to the 18 do not overflow.

## Code

**Input and wide multiplication.** The reader loads the four generator parameters and computes each row.

```nim
const flushBlockBytes = 1 shl 17
const resultModulo = 1000000007

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

proc multiplyModulo(firstValue: int64, secondValue: int64, modulusValue: int64): int64 =
  {.emit: """
  __int128 product = (__int128)`firstValue` * (__int128)`secondValue`;
  `result` = (NI64)(product % `modulusValue`);
  """.}

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let fieldSize = nextInt(inputData, scanPos)
let windowSize = nextInt(inputData, scanPos)
let windowCount = fieldSize - windowSize + 1
var rowMinimums = newSeq[int64](fieldSize * windowCount)
var generatedValues = newSeq[int64](fieldSize)
var windowQueue = newSeq[int](fieldSize)
```

The wide product keeps the generator exact.
One flat array stores all horizontal minima.
The deque array is reused by the second pass.

**Row pass.** Each row becomes its K cell sliding minima.

```nim
for rowIndex in 0 .. fieldSize - 1:
  let initialValue = int64(nextInt(inputData, scanPos))
  let multiplierValue = int64(nextInt(inputData, scanPos))
  let addendValue = int64(nextInt(inputData, scanPos))
  let modulusValue = int64(nextInt(inputData, scanPos))
  var currentValue = initialValue
  for columnIndex in 0 .. fieldSize - 1:
    generatedValues[columnIndex] = currentValue
    currentValue = (multiplyModulo(currentValue, multiplierValue, modulusValue) + addendValue) mod modulusValue
  var queueHead = 0
  var queueTail = 0
  for columnIndex in 0 .. fieldSize - 1:
    while queueTail > queueHead and generatedValues[windowQueue[queueTail - 1]] >= generatedValues[columnIndex]:
      queueTail -= 1
    windowQueue[queueTail] = columnIndex
    queueTail += 1
    while windowQueue[queueHead] <= columnIndex - windowSize:
      queueHead += 1
    if columnIndex >= windowSize - 1:
      rowMinimums[rowIndex * windowCount + columnIndex - windowSize + 1] = generatedValues[windowQueue[queueHead]]
```

Equal heights evict older indexes first.
The front of the deque is the minimum of the current window.
Only complete windows are written.

**Column pass and output.** The same deque folds rows, then the total is printed.

```nim
var totalMinimums: int64 = 0
for columnIndex in 0 .. windowCount - 1:
  var queueHead = 0
  var queueTail = 0
  for rowIndex in 0 .. fieldSize - 1:
    let currentValue = rowMinimums[rowIndex * windowCount + columnIndex]
    while queueTail > queueHead and rowMinimums[windowQueue[queueTail - 1] * windowCount + columnIndex] >= currentValue:
      queueTail -= 1
    windowQueue[queueTail] = rowIndex
    queueTail += 1
    while windowQueue[queueHead] <= rowIndex - windowSize:
      queueHead += 1
    if rowIndex >= windowSize - 1:
      totalMinimums = (totalMinimums + rowMinimums[windowQueue[queueHead] * windowCount + columnIndex]) mod resultModulo

appendOutput($totalMinimums)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each column is scanned once from top to bottom.
The modulo keeps the running sum inside a 64 bit integer.
The single output line is flushed after the last column.

## Complexity

Both folds scan the field once and store one result per horizontal window.

| phase | time | space |
|---|---|---|
| row generation | one step per cell | one generated row |
| row pass | one deque step per cell | flat row minima array |
| column pass | one deque step per window cell | one deque array |
| output | one line | block buffer |

Each deque step pushes and pops a cell at most once.

| measure | Big O |
|---|---|
| time | O(N squared) |
| space | O(N squared) |

Scanning all K squared cells of every square would be far slower.

Two folds give every subsquare minimum with work proportional to the field size.
