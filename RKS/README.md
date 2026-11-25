# RKS — RK Sorting (SPOJ)

<https://www.spoj.com/problems/RKS/>

## Problem

A message is a list of numbers. Reorder it so numbers with higher frequency come first, and equal frequencies follow first appearance in the original list.

Input gives a first line with N and C, then a line holding N integers no larger than C. Output is one line with the N reordered integers.

| item | bound |
|---|---|
| message length N | 1 to 1000 |
| bound C | 1 to 1e9 |
| each message value | at most C |
| judge limit | 1000 ms, 1536 MB |

The value bound is large, so values cannot index an array of size C.

Sample input:

```
9 3
1 3 3 3 2 2 2 1 1
```

Sample output:

```
1 1 1 3 3 3 2 2 2
```

All three values occur three times, so their first appearances decide the order.

## Idea

Count ballots, then line up candidates by vote count with earlier arrivals breaking ties.

The program stores each distinct value once with its frequency and first position. It insertion-sorts the distinct indices by falling frequency and rising first position. It then writes each value as many times as its frequency. A naive approach compares all N output slots and rescans the input for every comparison. The distinct-value table removes that repeated scanning.

## Why It Works

1. Frequency depends only on the original list and never changes during output.
2. A value's first position is fixed when it is first read.
3. Equal frequencies require first appearance order, which the comparator enforces.
4. Sorting distinct values instead of all N entries keeps the sort small.
5. Writing each value frequency times reproduces every original occurrence.

| term | meaning |
|---|---|
| `distinctValues` | one copy of each value seen in the message |
| `frequencies` | occurrence count for each distinct value |
| `firstPositions` | input index where each distinct value first appeared |
| `sortOrder` | distinct indices arranged by the required rule |

The table holds at most N rows, one per distinct value.

A script traces the sample table:

```
value  first  count
1      0      3
3      1      3
2      4      3
order: 1, 3, 2
output: 1 1 1 3 3 3 2 2 2
```

The trace shows equal counts resolved by first position 0, then 1, then 4.

## Code

**Input and scanner.** The reader loads stdin once and parses integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The loop appends a newline for every input line.
The scanner skips every character outside the digit range.

**Buffered output.** One string collects all output and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The block size is 131072 bytes.
The final flush happens once after the main loop.

**Distinct-value table.** Each input value is matched against stored values.

```nim
let messageLength = nextInt(inputData, scanPos)
let upperBound = nextInt(inputData, scanPos)
var distinctValues = newSeq[int](0)
var frequencies = newSeq[int](0)
var firstPositions = newSeq[int](0)
for valueIndex in 0 .. messageLength - 1:
  let currentValue = nextInt(inputData, scanPos)
  var matchIndex = -1
  for distinctIndex in 0 .. distinctValues.len - 1:
    if distinctValues[distinctIndex] == currentValue:
      matchIndex = distinctIndex
      break
  if matchIndex < 0:
    distinctValues.add currentValue
    frequencies.add 1
    firstPositions.add valueIndex
  else:
    frequencies[matchIndex] += 1
```

The bound C is read but does not affect the table.
A match increments frequency, a miss adds a new row.

**Ordering and writing.** Insertion sort arranges indices, then values are emitted.

```nim
var sortOrder = newSeq[int](distinctValues.len)
for orderIndex in 0 .. sortOrder.len - 1:
  sortOrder[orderIndex] = orderIndex
for rightIndex in 1 .. sortOrder.len - 1:
  let movingIndex = sortOrder[rightIndex]
  var leftIndex = rightIndex - 1
  while leftIndex >= 0 and (frequencies[sortOrder[leftIndex]] < frequencies[movingIndex] or (frequencies[sortOrder[leftIndex]] == frequencies[movingIndex] and firstPositions[sortOrder[leftIndex]] > firstPositions[movingIndex])):
    sortOrder[leftIndex + 1] = sortOrder[leftIndex]
    leftIndex -= 1
  sortOrder[leftIndex + 1] = movingIndex

var writtenAny = false
for orderIndex in 0 .. sortOrder.len - 1:
  let valueIndex = sortOrder[orderIndex]
  for repeatIndex in 0 .. frequencies[valueIndex] - 1:
    if writtenAny:
      appendOutput " "
    appendOutput($distinctValues[valueIndex])
    writtenAny = true
appendOutput "\n"
stdout.write outputBuffer
outputBuffer.setLen 0
```

The comparator checks frequency first, then first position.
Spaces are written only between values, never after the last one.
Counts and values stay in signed 32-bit range, so plain integers suffice.

## Complexity

The table is built once, then sorted once, then written once.

| phase | time | space |
|---|---|---|
| input read | one pass over N values | one input string |
| table build | up to N times D comparisons | three arrays of D entries |
| ordering | insertion sort over D indices | one index array |
| output | N integer writes | block buffer |

Distinct values never outnumber input values.

| measure | Big O |
|---|---|
| time | O(N * D + D^2), at most O(N^2) |
| space | O(N) |

A naive scan of all N values per comparison costs O(N^3) and loses to the table.
The distinct-value table is the takeaway.
