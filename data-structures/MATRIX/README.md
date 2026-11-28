# MATRIX — Count maximum matrices (SPOJ)

<https://www.spoj.com/problems/MATRIX/>

## Problem

Score every rectangle of a 0/1 matrix by adding one per 1 on its border and subtracting one per 0 on its border. Report the highest score W and the number of rectangles S that reach it.

Input starts with the test count t. Each case gives M N, then M lines of N values, each 0 or 1, separated by spaces. Output one line per case with W and S, separated by a space.

The bounds from the statement:

| Item | Bound |
|---|---|
| test cases t | at most 15 |
| rows M and columns N | 1 ≤ M, N ≤ 200 |
| cells per case | at most 40 000 |
| rectangles per case | at most 404 010 000 |
| judge limits | 2538 ms, 1536 MB |

The rectangle count drives the design, not the cell count.

The sample input:

```
1
5 6
1 1 1 1 1 1
1 0 0 0 0 1
1 0 0 0 0 1
1 0 0 0 0 1
1 1 1 1 1 1
```

The sample output:

```
18 1
```

## Idea

Fix two rows and read every column between them as one number, like checking fence posts while walking once along a fence. The algorithm is a row-pair sweep. For each top and bottom row it forms one value per column, then keeps the largest left-column value seen so far.

Each column costs O(1), so a row pair costs O(N) and a case costs O(M²N). Testing every rectangle instead checks O(M²N²) borders, about 4×10^8 per full case. The sweep also tracks tie counts, so it returns both the maximum and its frequency.

One walk per row pair replaces a search over every column pair.

## Why It Works

Four facts prove the count.

1. A border splits into the top row segment, the bottom row segment, and the middle of the left and right columns. The middles exclude both chosen rows, so corners are counted once.
2. For a fixed row pair, `topBottom` is the sum of the two row cells at column c. `middle` is the column sum between those rows. The running `segmentSum` holds `topBottom` for columns before c.
3. For left < right, the score is leftValue at the left column plus rightValue at the right column. Here `leftValue` is `middle - segmentSum` and `rightValue` adds `topBottom` and `middle` to `segmentSum`. This is exact algebra.
4. A running maximum of `leftValue` with its tie count gives the best left column for each right column in O(1). Single rows use a prefix-min scan; width-one rectangles use the `topBottom + middle` candidate.

The terms of the sweep:

| Term | Meaning |
|---|---|
| `topBottom` | `cellValue` at the top and bottom rows of column c, added |
| `middle` | column c summed between those rows, corners excluded |
| `segmentSum` | running sum of `topBottom` over columns before c |
| `leftValue` | `middle - segmentSum`, the part contributed by the left column |
| `rightValue` | `segmentSum` plus `topBottom` plus `middle`, the right column's part |

These terms turn a two-column choice into one addition.

A script trace of row pair 0 and 4 on the sample:

```
column      0    1    2    3    4    5
topBottom   2    2    2    2    2    2
middle      3   -3   -3   -3   -3    3
leftValue   3   -5   -7   -9  -11   -7
rightValue  5    1    3    5    7   15
width1      5   -1   -1   -1   -1    5
```

The best pair uses left column 0 and right column 5, since 3 + 15 = 18. No other rectangle ties it, so S = 1. The trace matches the sample output 18 1.

## Code

**Constants and token reader.** Digits are scanned by index, with no substring or parse call.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maximumDimension = 200
const noValueYet = -1000000000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

`maximumDimension` caps the two flat arrays at 200. `noValueYet` sits below every possible border score. The scanner skips spaces and newlines, so all tokens parse from one buffer. Cost is one pass over the input bytes.

**Best tracker.** One candidate updates the maximum and its count.

```nim
proc considerCandidate(candidateValue: int, candidateCount: int64,
                       bestValue: var int, bestCount: var int64) =
  if candidateValue > bestValue:
    bestValue = candidateValue
    bestCount = candidateCount
  elif candidateValue == bestValue:
    bestCount += candidateCount
```

A larger score replaces the count; an equal score adds to it. `bestCount` is `int64` because up to 4×10^8 rectangles can tie. The call costs O(1).

**Buffers and input.** Flat arrays are allocated once and reused across cases.

```nim
var cellValue = newSeq[int](maximumDimension * maximumDimension)
var colPrefix = newSeq[int]((maximumDimension + 1) * maximumDimension)
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`cellValue` uses the offset `rowIndex * columnCount + columnIndex`. `colPrefix` adds one spare row, with row zero cleared per case. `appendOutput` flushes at 256 KiB, so no per-line write occurs.

**Case setup.** One digit pass fills the cells, then a second pass builds column prefixes.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  for columnIndex in 0..<columnCount:
    colPrefix[columnIndex] = 0
  for rowIndex in 0..<rowCount:
    for columnIndex in 0..<columnCount:
      let inputDigit = nextInt(inputData, scanPos)
      cellValue[rowIndex * columnCount + columnIndex] = inputDigit * 2 - 1
  for rowIndex in 0..<rowCount:
    for columnIndex in 0..<columnCount:
      colPrefix[(rowIndex + 1) * columnCount + columnIndex] =
        colPrefix[rowIndex * columnCount + columnIndex] +
        cellValue[rowIndex * columnCount + columnIndex]
```

A 0 becomes -1 and a 1 becomes +1, so border sums are plain addition. The prefix loop costs M·N additions. Row zero of `colPrefix` is reset because a shorter case reuses the same flat array.

**Single-row rectangles.** A prefix-min scan handles every horizontal segment.

```nim
  var bestValue = noValueYet
  var bestCount: int64 = 0
  for rowIndex in 0..<rowCount:
    var prefixSum = 0
    var minPrefix = 0
    var minCount: int64 = 0
    for columnIndex in 0..<columnCount:
      if prefixSum < minPrefix:
        minPrefix = prefixSum
        minCount = 1
      elif prefixSum == minPrefix:
        minCount += 1
      prefixSum += cellValue[rowIndex * columnCount + columnIndex]
      considerCandidate(prefixSum - minPrefix, minCount, bestValue, bestCount)
```

The minimum prefix is added before the current cell, so a segment of length one works. Ties in the minimum multiply the count. Cost is N steps per row and M·N overall.

**Row-pair sweep.** One pass per row pair finds the best left and right columns and their count.

```nim
  for topRow in 0..<(rowCount - 1):
    for bottomRow in (topRow + 1)..<rowCount:
      var segmentSum = 0
      var runningMax = noValueYet
      var runningCount: int64 = 0
      for columnIndex in 0..<columnCount:
        let topBottom = cellValue[topRow * columnCount + columnIndex] +
                        cellValue[bottomRow * columnCount + columnIndex]
        let middle = colPrefix[bottomRow * columnCount + columnIndex] -
                     colPrefix[(topRow + 1) * columnCount + columnIndex]
        let leftValue = middle - segmentSum
        segmentSum += topBottom
        let rightValue = segmentSum + middle
        if columnIndex > 0:
          considerCandidate(runningMax + rightValue, runningCount,
                            bestValue, bestCount)
        considerCandidate(topBottom + middle, int64(1), bestValue, bestCount)
        if leftValue > runningMax:
          runningMax = leftValue
          runningCount = 1
        elif leftValue == runningMax:
          runningCount += 1
```

The pair is considered before its own `leftValue` joins the running maximum, so left stays left of right. The `topBottom + middle` line covers width-one rectangles. Cost is N steps for each of M(M-1)/2 row pairs.

**Output tail.** One append per case, then a final flush.

```nim
  appendOutput($(bestValue) & " " & $(bestCount) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The final write clears the tail of fewer than 256 KiB. `setLen 0` reuses the same allocation. Output is one short line per test case.

## Complexity

The work splits into input, prefixes, two scans, and output.

| Phase | Time | Space |
|---|---|---|
| input read | one line pass, then one digit pass per token | input bytes |
| prefix setup | M·N additions | two flat arrays, 80 000 ints |
| single rows | M·N candidates | three scalars |
| row pairs | M(M-1)/2 · N candidates | four scalars |
| output | one write per 256 KiB block | block buffer |

The prefix arrays dominate space; the row-pair scan dominates time.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| time per case | O(M²N) |
| space per case | O(MN) |

Enumerating all O(M²N²) rectangles would check about 4×10^8 borders per full case. The sweep checks each column once per row pair and stays well inside the limit.
