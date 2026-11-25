# ZDIFFSQ2 — What is the next number in the sequence (SPOJ)
<https://www.spoj.com/problems/ZDIFFSQ2/>

## Problem

A list of integers has a zero row somewhere in its repeated differences. Continue that list by three terms.

Input is one line holding M space-separated integers, with M below 10. Output is one line holding the next three integers, separated by spaces.

| item | bound |
|---|---|
| count M | less than 10 |
| values | integers, sign allowed |
| extra terms | exactly 3 |
| judge limit | 1000 ms, 1536 MB |

The zero row makes the continuation unique.

Sample input:

```
15 32 57 90 131 180
```

Sample output:

```
237 302 375
```

## Idea

Let the zero row pull three new terms back up the table, like filling a staircase from its top step down. The method is a finite-difference table extended one column at a time. Each row costs one subtraction per entry. Rebuilding the table for every new term repeats those subtractions three times. Grow the existing table once and read its last three entries.

## Why It Works

1. A difference row is built from the row above by subtracting neighbours.
2. A zero row stays zero when extended.
3. Each row above gains a term equal to its last term plus the new term below it.
4. Repeating this three times appends exactly three sequence terms.
5. The first row after extension holds the required continuation.

| term | meaning |
|---|---|
| `differenceRows` | the original list plus every difference row |
| `allZero` | marks the row that stops the table |
| `termsToAppend` | fixed count of three new terms |
| `bottomFill` | value added at each step to the bottom row |
| `firstNextIndex` | start of the three answers in the first row |

The sample table is built by the worked example below.

| row | values |
|---|---|
| s | 15 32 57 90 131 180 |
| d1 | 17 25 33 41 49 |
| d2 | 8 8 8 8 |
| d3 | 0 0 0 |

The zero row receives 0, 0 and 0. Then d2 receives 8, 8 and 8, d1 receives 57, 65 and 73, and s receives 237, 302 and 375.

No rounding occurs, since every value stays an integer.

## Code

**Input and scanning.** The hand reader accepts signed integers and stops at the last digit.

```nim
const flushBlockBytes = 1 shl 17
const termsToAppend = 3

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc hasNextNumber(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len and (data[checkPos] < '0' or data[checkPos] > '9'):
    checkPos += 1
  return checkPos < data.len

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

A leading minus sign is kept.
Blank space between numbers is ignored.

**Difference table.** Rows shrink until one row is all zeros or holds a single value.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var sequence = newSeq[int64]()
while hasNextNumber(inputData, scanPos):
  sequence.add int64(nextInt(inputData, scanPos))
if sequence.len == 0:
  sequence.add 0

var differenceRows = newSeq[seq[int64]]()
differenceRows.add sequence
while true:
  let previousRow = differenceRows[differenceRows.len - 1]
  if previousRow.len <= 1:
    break
  var nextRow = newSeq[int64](previousRow.len - 1)
  for index in 0 .. previousRow.len - 2:
    nextRow[index] = previousRow[index + 1] - previousRow[index]
  differenceRows.add nextRow
  var allZero = true
  for value in nextRow:
    if value != 0:
      allZero = false
      break
  if allZero:
    break
```

Every row is one entry shorter than the row above.
Nine input values produce at most nine rows.
Sums and products stay in 64-bit integers.

**Extension and output.** Three new columns travel from the bottom row to the first row.

```nim
let bottomIndex = differenceRows.len - 1
let bottomRow = differenceRows[bottomIndex]
var bottomFill: int64 = 0
if bottomRow.len == 1:
  bottomFill = bottomRow[0]
for step in 0 .. termsToAppend - 1:
  differenceRows[bottomIndex].add bottomFill
  var upperIndex = bottomIndex - 1
  while upperIndex >= 0:
    let upperLast = differenceRows[upperIndex][differenceRows[upperIndex].len - 1]
    let lowerLast = differenceRows[upperIndex + 1][differenceRows[upperIndex + 1].len - 1]
    differenceRows[upperIndex].add upperLast + lowerLast
    upperIndex -= 1

let resultRow = differenceRows[0]
let firstNextIndex = resultRow.len - termsToAppend
for step in 0 .. termsToAppend - 1:
  if step > 0:
    appendOutput(" ")
  appendOutput($resultRow[firstNextIndex + step])
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

A one-value bottom row repeats its constant at each step.
An all-zero bottom row keeps adding zero.
The last three values of the first row are the answer.
The buffer flushes once after the line is complete.

## Complexity

The table has at most M rows, and each row has fewer entries than the one above.

| phase | time | space |
|---|---|---|
| input read | one pass over M integers | one input string |
| difference table | one subtraction per pair | one entry per pair |
| extension | one addition per row per step | same table |
| output | one line | block buffer |

The table costs less than twice the input length in entries.

| measure | Big O |
|---|---|
| time | O(M^2) |
| space | O(M^2) |

Rebuilding the table for each new term would cost O(M^3).

A zero row fixes the continuation without any guessing.
