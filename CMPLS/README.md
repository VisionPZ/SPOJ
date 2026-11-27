# CMPLS — Complete the Sequence! (SPOJ)

<https://www.spoj.com/problems/CMPLS/>

## Problem

A sequence of S integers comes from a polynomial of least possible degree. Compute the next C values of that polynomial.

Input: one integer for the case count, then one case per block. Each block starts with S (given values) and C (requested values), followed by the S given integers.

Output: each completed line as C space-separated integers on its own line.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Test cases T | about 5000 |
| Given values S | 1 to 99 |
| Requested values C | 1 to 99 |
| Sum S + C | at most 100 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

Every answer is non-negative and fits a standard integer.

The sample input and output:

```
4
6 3
1 2 3 4 5 6
8 2
1 2 4 7 11 16 22 29
10 2
1 1 1 1 1 1 1 1 1 2
1 10
3
```

```
7 8 9
37 46
11 56
3 3 3 3 3 3 3 3 3 3
```

## Idea

Extend a table of differences, like continuing a column of numbers by copying the last change down. Each new row subtracts neighboring values from the row above.

The program builds rows until one value remains, then keeps only each row's last value. Walking from the deepest row upward adds one change at a time and produces the next term.

Each extension costs O(S) work, where S is the number of given values. Solving for polynomial coefficients from scratch would cost O(S³) per term.

The table turns extrapolation into repeated addition.

## Why It Works

A polynomial of degree d has constant d-th differences.

1. The deepest nonzero row of the difference table is therefore constant.
2. The interpolation polynomial (the unique lowest-degree fit) of degree at most S minus one matches every given point.
3. No polynomial of lower degree matches all points unless a shallower row is already constant.
4. Adding the deepest change to each row above evaluates that same polynomial at the next integer.

The table uses two formulas per row:

| Term | Formula |
| --- | --- |
| `lowerRow[k]` | `upperRow[k + 1] - upperRow[k]` |
| carried value | `lastElements[k] + carriedValue` |
| stop condition | upper row length equals 1 |

The first line subtracts the current point from the next point. The second line adds the deeper change to the row above.

A script extends the first sample case, `1 2 3 4 5 6`:

```
r0: 1 2 3 4 5 6   last 6
r1:   1 1 1 1 1   last 1
r2:     0 0 0 0   last 0
next 1: 6 + (1 + 0) = 7
next 2: 7 + (1 + 0) = 8
next 3: 8 + (1 + 0) = 9
```

The three next terms are 7, 8, and 9, which match the sample output.

## Code

**Scanner.** The hand scanner keeps a minus sign, so negative sequence values survive.

```nim
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, i: var int): int64 =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] != '-' and
      (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var negative = false
  if i < dataLength and inputData[i] == '-':
    negative = true
    i += 1
  var value: int64 = 0
  while i < dataLength and inputData[i] >= '0' and
      inputData[i] <= '9':
    value = value * 10 + int64(int(inputData[i]) - 48)
    i += 1
  if negative:
    value = -value
  return value
```

The scan stops at the buffer end, so it makes at most one pass. The minus branch runs before the digit loop. Each skipped byte costs one check.

**Input setup.** The readLine loop builds one buffer, and each appended newline keeps boundaries visible.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = int(nextInt(inputData, i))
var outputBuffer = ""
```

The loop runs once per input line and allocates no token objects. The first parsed integer is the case count. The output buffer starts empty.

**Table build and extension.** Rows are built once, then only their last values are carried forward.

```nim
for j in 0 ..< caseCount:
  let sequenceLength = int(nextInt(inputData, i))
  let completionCount = int(nextInt(inputData, i))
  var differenceTable: seq[seq[int64]] = @[]
  var startingRow: seq[int64] = @[]
  startingRow.setLen(sequenceLength)
  for k in 0 ..< sequenceLength:
    startingRow[k] = nextInt(inputData, i)
  differenceTable.add startingRow
  while differenceTable[differenceTable.high].len > 1:
    let upperRow = differenceTable[differenceTable.high]
    let lowerLength = upperRow.len - 1
    var lowerRow: seq[int64] = @[]
    lowerRow.setLen(lowerLength)
    for k in 0 ..< lowerLength:
      lowerRow[k] = upperRow[k + 1] - upperRow[k]
    differenceTable.add lowerRow
  var lastElements: seq[int64] = @[]
  lastElements.setLen(differenceTable.len)
  for k in 0 ..< differenceTable.len:
    lastElements[k] = differenceTable[k][differenceTable[k].high]
  for l in 0 ..< completionCount:
    var carriedValue = lastElements[lastElements.high]
    var k = lastElements.high - 1
    while k >= 0:
      carriedValue = lastElements[k] + carriedValue
      lastElements[k] = carriedValue
      k -= 1
    if l > 0:
      outputBuffer.add ' '
    outputBuffer.add $carriedValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

The table loop stops when a row reaches length one. Keeping only last values avoids rewriting the table for every requested term. The leading-space check keeps the output free of extra separators.

## Complexity

Table build costs O(S²) time and space per case, and each extension costs O(S) time.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Difference table | O(S²) per case | O(S²) rows |
| Last values | O(S) per case | O(S) |
| Extension | O(C × S) per case | O(S) |
| Output | one write per 128 KiB block | 128 KiB |
| Total per case | O(S² + C × S) | O(S²) |

With S below 100, one table holds fewer than 5000 integers.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(T × (S² + C × S)) for T cases |
| Space | O(S²) working space |

Solving the full coefficient system for every term would cost O(S³) each time.
