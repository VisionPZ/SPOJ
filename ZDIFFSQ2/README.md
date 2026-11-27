# ZDIFFSQ2 — What is the next number in the sequence (SPOJ)

<https://www.spoj.com/problems/ZDIFFSQ2/>

## Problem

A sequence `s` has a first difference `d1` made of `s2-s1, s3-s2, ...`. Taking differences again gives `d2`, and so on. Some sequences reach an all-zero difference row. Given such a sequence on one line, print the next three numbers.

| item | bound |
|---|---|
| numbers per line `M` | M < 10 |
| judge limit | 1000 ms, 1536 MB |

The statement's own example:

```
15 32 57 90 131 180
```

```
237 302 375
```

## Idea

Write the sequence, then write its differences underneath, then the differences of those, like a pyramid of subtraction. For the triangular numbers the pyramid works like this.

```
1 3 6 10 15
 2 3 4 5
  1 1 1
   0 0
```

Once a row is all zeros, every number below it stays put. So the next number of the row above equals its last number plus the last number below. To extend the sequence, append one number to each row from bottom to top, three times, and read the three new tops.

## Why It Works

1. Each row is built exactly as the statement defines differences, so the pyramid matches the real `d1, d2, ...`.
2. When a row is all zeros, the row above it is an arithmetic progression: its gaps are the constant row below. Extending it means adding the last gap once more.
3. The append rule `new_upper_last = upper_last + lower_last` is the exact inverse of `lower[i] = upper[i+1] - upper[i]`, so every extended row still has the given row as its difference.
4. If the input is one number, or the differences never hit zero, the program treats the last surviving row (a single number) as constant. That is the same convention the reference oracle uses, so both agree on every test.
5. The sample pyramid is `d1 = [17 25 33 41 49]`, `d2 = [8 8 8 8]`, `d3 = [0 0 0]`. Extending once gives `d2` one more 8, `d1` the new last `49 + 8 = 57`, and the sequence `180 + 57 = 237`. The second extension adds `65` to reach `302`, the third adds `73` to reach `375`.

| term | meaning |
|---|---|
| `differenceRows` | the pyramid, row 0 is the sequence |
| `bottomIndex` | index of the lowest row kept |
| `bottomFill` | value appended to the bottom row each round |
| `termsToAppend` | 3, the number of requested numbers |

## Code

**Input, scanner and output buffer.** This block loads stdin and prepares the writer.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`hasNextNumber` peeks ahead for another digit without moving the position, so the read loop knows when the line ends. `nextInt` accepts a leading minus because sequence entries may be negative.

**Building the pyramid.** This block reads the numbers and stacks difference rows until a row is all zeros or shrinks to one entry.

```nim
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

Numbers are kept as `int64` so extended values cannot overflow a 32-bit int. The zero check stops the pyramid as soon as it is flat.

**Extending and printing.** This block appends one entry per row, three rounds, bottom to top.

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

A flat bottom row fills with 0; a single-entry bottom row fills with its own value, which makes the row above grow by a constant gap. The three newest entries of row 0 are the answers.

## Complexity

| phase | time | space |
|---|---|---|
| pyramid build | O(M^2) rows and entries | O(M^2) |
| extension | 3 rounds over at most M rows | O(M^2) |
| output | 3 numbers | O(1) |

| measure | big O |
|---|---|
| time | O(M^2) |
| space | O(M^2) |

With M < 10 the whole pyramid is at most 45 numbers, so the program is instantaneous.
