## Problem

Read T test cases. Each case gives S sequence values and asks for C following values. Use the lowest-degree polynomial that fits the given values. Print each completed line as C space-separated integers.

The bounds stay small per case, and the case count is large.

| Quantity | Bound |
| --- | --- |
| Test cases T | about 5000 |
| Given values S | 1 to 99 |
| Requested values C | 1 to 99 |
| Sum S + C | at most 100 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The case count dominates the run time. Every answer is non-negative and fits a standard integer.

## Idea

Build a table of consecutive differences until one value remains. The last value of each row holds the state for the next term. Walk from the deepest row to the top, costing O(S) per term instead of solving coefficients again.

## Why It Works

A degree d polynomial has constant d-th differences. The deepest nonzero row of the table is therefore constant. The interpolation polynomial of degree at most S minus one fits all given points, and no polynomial of lower degree fits them. Extending the table by one step evaluates this polynomial at the next integer.

For row k and position i: differenceRow[position] = upperRow[position + 1] - upperRow[position].
For the carried value: carriedValue = lastElements[rowIndex] + carriedValue.

The first line subtracts the current point from the next point. The second line adds the deeper row's change to the row above.

Worked example for 1 2 4 7 11:

| Row | Values | Last |
| --- | --- | --- |
| r0 | 1 2 4 7 11 | 11 |
| r1 | 1 2 3 4 | 4 |
| r2 | 1 1 1 | 1 |
| r3 | 0 0 | 0 |
| r4 | 0 | 0 |

The deepest carried value is zero. Row r2 becomes 1 + 0 = 1, then r1 becomes 4 + 1 = 5. Row r0 becomes 11 + 5 = 16, the next term.

## Code

```
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int64 =
  let dataLength = inputData.len
  while scanPos < dataLength and inputData[scanPos] != '-' and
      (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var negative = false
  if scanPos < dataLength and inputData[scanPos] == '-':
    negative = true
    scanPos += 1
  var value: int64 = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and
      inputData[scanPos] <= '9':
    value = value * 10 + int64(int(inputData[scanPos]) - 48)
    scanPos += 1
  if negative:
    value = -value
  return value
```

The scanner stops at the buffer end, so it runs at most one pass over the input. The minus branch keeps negative sequence values intact. Its cost is one byte check per skipped character.

```
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = int(nextInt(inputData, scanPos))
var outputBuffer = ""
```

The readLine loop appends every line into one buffer. The added newline keeps number boundaries visible. The loop runs once per input line and allocates no token objects.

```
for caseIndex in 0 ..< caseCount:
  let sequenceLength = int(nextInt(inputData, scanPos))
  let completionCount = int(nextInt(inputData, scanPos))
  var differenceTable: seq[seq[int64]] = @[]
  var startingRow: seq[int64] = @[]
  startingRow.setLen(sequenceLength)
  for position in 0 ..< sequenceLength:
    startingRow[position] = nextInt(inputData, scanPos)
  differenceTable.add startingRow
  while differenceTable[differenceTable.high].len > 1:
    let upperRow = differenceTable[differenceTable.high]
    let lowerLength = upperRow.len - 1
    var lowerRow: seq[int64] = @[]
    lowerRow.setLen(lowerLength)
    for position in 0 ..< lowerLength:
      lowerRow[position] = upperRow[position + 1] - upperRow[position]
    differenceTable.add lowerRow
  var lastElements: seq[int64] = @[]
  lastElements.setLen(differenceTable.len)
  for rowIndex in 0 ..< differenceTable.len:
    lastElements[rowIndex] = differenceTable[rowIndex][differenceTable[rowIndex].high]
  for completionIndex in 0 ..< completionCount:
    var carriedValue = lastElements[lastElements.high]
    var rowIndex = lastElements.high - 1
    while rowIndex >= 0:
      carriedValue = lastElements[rowIndex] + carriedValue
      lastElements[rowIndex] = carriedValue
      rowIndex -= 1
    if completionIndex > 0:
      outputBuffer.add ' '
    outputBuffer.add $carriedValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

The table loop stops when the row length reaches one, so it runs S minus one times. Keeping only each row's last value avoids rewriting the full table during extension. The leading-space check keeps the output free of extra separators. The buffer flushes every flushBlockBytes bytes and caps memory.

## Complexity

Table build costs O(S^2) time and O(S^2) space per case, with S below 100.
Extension costs O(C * S) time and O(S) extra space per case.
The whole run costs O(T * (S^2 + C * S)) time and O(S^2) working space.
Solving the full coefficient system for every requested term costs O(S^3) per term.
