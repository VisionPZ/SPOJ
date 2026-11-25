# RG11 — Sort Frequency of Integer Grado 11 (SPOJ)

<https://www.spoj.com/problems/RG11/>

## Problem

Read a line whose first number gives the count of following integers.
For each integer value, measure how often it appears.
Print those frequencies from largest to smallest on one line.
Repeat the process if more lines follow.

The first number is a size marker and never counts as data.

| Item | Bound |
|---|---|
| Input | a count followed by that many integers |
| Output | frequencies in descending order |
| Judge limit | 1000 ms |

The number of distinct values stays below the array length.

Sample input:

```
9 4 80 80 30 4 4 80 4 4
```

Sample output:

```
5 3 1
```

The value 4 appears five times, 80 three times, and 30 once.

## Idea

Think of sorting a pile of playing cards by rank, then counting each rank.
Once equal cards sit together, one pass measures each run.
The run lengths are the frequencies we need.

A quicksort groups equal values into contiguous runs.
A second array counts how many runs have each length.
Walking that array backward prints frequencies in descending order.

## Why It Works

1. Sorting places every equal value in one contiguous run.
2. A run length equals the frequency of that value.
3. Counting run lengths gives a frequency-of-frequency table.
4. Visiting lengths from high to low sorts all frequencies.

| Term | Meaning |
|---|---|
| `values` | the scanned integers for one case |
| `sortValues` | in-place quicksort with a middle pivot |
| `frequencySlots` | how many values have a given frequency |
| `printed` | number of frequencies already written |

Script-generated example from `gen.py`:

```
4 5 5 5 5 -> 4
3 1 2 3 -> 1 1 1
```

The first case has one run of length four.

## Code

**Input scanner and sorting.** This block reads signed integers and groups equal values.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInteger(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var magnitude = int64(0)
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    magnitude = magnitude * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  if negative:
    return -magnitude
  return magnitude

proc hasMoreInteger(data: string, pos: int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9') and data[probe] != '-':
    probe += 1
  return probe < data.len

proc sortValues(values: var seq[int64], leftIndex: int, rightIndex: int) =
  if leftIndex >= rightIndex: return
  var low = leftIndex
  var high = rightIndex
  let pivot = values[(leftIndex + rightIndex) div 2]
  while low <= high:
    while values[low] < pivot: low += 1
    while values[high] > pivot: high -= 1
    if low <= high:
      swap values[low], values[high]
      low += 1
      high -= 1
  if leftIndex < high: sortValues(values, leftIndex, high)
  if low < rightIndex: sortValues(values, low, rightIndex)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts an optional minus sign.
The pivot is the middle element, which handles sorted input well.
Each partition swaps values in place without extra arrays.

**Frequency output.** This block counts run lengths and prints them.

```nim
while hasMoreInteger(inputData, scanPos):
  let declaredCount = nextInteger(inputData, scanPos)
  if declaredCount <= 0:
    outputBuffer.add '\n'
    continue
  var values = newSeq[int64](int(declaredCount))
  var stored = 0
  while stored < int(declaredCount) and hasMoreInteger(inputData, scanPos):
    values[stored] = nextInteger(inputData, scanPos)
    stored += 1
  values.setLen(stored)
  if stored > 0:
    sortValues(values, 0, stored - 1)
    var frequencySlots = newSeq[int](stored + 1)
    var runStart = 0
    for index in 1..stored:
      if index == stored or values[index] != values[runStart]:
        let runLength = index - runStart
        frequencySlots[runLength] += 1
        runStart = index
    var printed = 0
    var frequency = stored
    while frequency >= 1:
      for occurrence in 0..<frequencySlots[frequency]:
        if printed > 0: outputBuffer.add ' '
        appendOutput($(frequency))
        printed += 1
      frequency -= 1
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each run increments one frequency slot.
The descending loop emits repeated values without a trailing space.
A newline ends each case.

## Complexity

Sorting dominates the work for large arrays.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sorting | O(n log n) expected | O(log n) stack |
| Run counting | O(n) | O(n) |
| Output | one write per 128 KiB block | block buffer |

n is the declared count for one case.

| Measure | Big O |
|---|---|
| Time | O(n log n) expected per case |
| Space | O(n) |

A frequency map with nested comparisons would cost O(n^2).
Sorting once reduces the work to linear time after the sort.
