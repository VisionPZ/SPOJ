# G11184 — Jolly Grado 11 (SPOJ)

<https://www.spoj.com/problems/G11184/>

## Problem

A sequence of n integers is a jolly jumper when the absolute differences between neighbours cover every value from 1 to n−1. Decide each sequence in the input and print its verdict.

Input holds one case per line: n, then n integers. A line with n = 0 ends the input. Output one line per case: `Jolly` when the differences cover the full range, otherwise `Not jolly`.

| item | bound |
|---|---|
| sequence length n | 1 to 2999 |
| sequence elements | signed integers |
| terminating value | n = 0 ends input |
| judge limit | 1000 ms, 1536 MB |

The length bound fixes the size of the marking table used by the program.

Sample input:

```
4 1 4 2 3
5 1 4 2 -1 6
0
```

Sample output:

```
Jolly
Not jolly
```

## Idea

Treat the differences as stepping stones that must include every distance from 1 to n−1, like checking names off a guest list. The difference-marking algorithm visits each neighbour pair once and ticks off the distance it finds. A naive approach would sort all differences and compare the sorted list with 1 through n−1, costing O(n log n) per case. Marking keeps the work linear and resets the table between cases.

## Why It Works

1. A sequence of one element has no neighbour pairs, so it passes by default.
2. Each neighbour pair contributes one absolute difference.
3. A valid jolly jumper needs every difference from 1 to n−1 exactly once.
4. A difference outside that range or a repeated difference makes the answer negative.
5. The marking table records which distances have appeared; a final count confirms full coverage.
6. Clearing the table after each case prevents marks from leaking into the next case.

| term | meaning |
|---|---|
| `caseLength` | n, the number of integers in the current case |
| `sequenceValues` | the stored integers of the current case |
| `seenDifferences` | table marking each distance already found |
| `distinctCount` | number of distinct valid distances found |
| `isJolly` | verdict for the current case |

The verdict depends only on the difference set, never on the order of the integers.

A script-generated trace from the generator:

```
seq [1, 4, 2, 3]
abs diffs [3, 2, 1]
want [1, 2, 3]
bad diffs [3, 2, 3, 7] missing [1, 4]
```

The good sequence marks 3, 2 and 1 with no gaps; the bad sequence misses 1 and 4.

## Code

**Input and scanning.** One buffer holds all input; the hand scanner accepts negatives.

```nim
const flushBlockBytes = 1 shl 17
const maxSequenceLength = 3000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int, value: var int64): bool =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return false
  var negative = false
  if data[pos] == '-':
    negative = true
    pos += 1
  var magnitude: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    magnitude = magnitude * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    value = -magnitude
  else:
    value = magnitude
  return true
```

The scanner stops when no token remains, which handles the trailing zero case.
The minus branch covers the signed integers allowed by the statement.
Magnitude accumulation stays in `int64` before the sign is applied.

**Difference marking.** Each case is read, checked and written before the next one starts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var seenDifferences = newSeq[bool](maxSequenceLength)
var sequenceValues = newSeq[int64](maxSequenceLength)

while true:
  var caseLengthValue: int64 = 0
  if not nextInt(inputData, scanPos, caseLengthValue):
    break
  if caseLengthValue == 0:
    break
  let caseLength = int(caseLengthValue)
  var allValuesRead = true
  for valueIndex in 0 .. caseLength - 1:
    if not nextInt(inputData, scanPos, sequenceValues[valueIndex]):
      allValuesRead = false
      break
  var isJolly = allValuesRead
  var distinctCount = 0
  for valueIndex in 0 .. caseLength - 2:
    var difference = sequenceValues[valueIndex + 1] - sequenceValues[valueIndex]
    if difference < 0:
      difference = -difference
    if difference < 1 or difference > int64(caseLength - 1) or seenDifferences[int(difference)]:
      isJolly = false
    else:
      seenDifferences[int(difference)] = true
      distinctCount += 1
  if distinctCount != caseLength - 1:
    isJolly = false
  if isJolly:
    appendOutput("Jolly\n")
  else:
    appendOutput("Not jolly\n")
  for differenceIndex in 1 .. caseLength - 1:
    seenDifferences[differenceIndex] = false

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop visits exactly `caseLength - 1` neighbour pairs per case.
Out-of-range and repeated distances are rejected at the moment they appear.
The marking table is cleared for indices 1 through `caseLength - 1` after output.

## Complexity

Each case scans its neighbour pairs once and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | input string |
| difference marking | one visit per neighbour pair | two arrays of 3000 slots |
| output | one line per case | block buffer |

Total running time grows with the input size, not with the number of cases alone.

| measure | Big O |
|---|---|
| time | O(N) over all input integers |
| space | O(3000) fixed working arrays |

Sorting every difference list would cost O(n log n) per case; marking keeps each case linear.
