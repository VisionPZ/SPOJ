# CNTDO — Count Doubles (SPOJ)

<https://www.spoj.com/problems/CNTDO/>

## Problem

Count the values in an array that have their double somewhere in the same array, and print one count per test case. Values may repeat, and zero counts when present because twice zero is zero.

The first line holds the case count. Each case has a value count followed by that many integers. Print one line per case.

| Item | Bound |
|---|---|
| Cases T | up to 1000 |
| Values per case N | 1 to 1000 |
| Each value | between -10000 and 10000 |
| Judge limit | 500 ms, 1536 MB |

Doubles stay between -20000 and 20000, which fits a fixed lookup table.

The sample array has seven values in its first case:

```
2
7
1 3 4 7 9 2 18
3
1 4 3
```

The expected output is:

```
3
0
```

## Idea

Check each number against a guest list of numbers already seen, like a doorman comparing an invitation against one alphabetical roster. Mark every value in a bounded table, then test twice each value against that table. One lookup costs constant work, while comparing every pair of values costs quadratic work. The small fixed value range makes the table tiny and removes any sorting.

## Why It Works

1. A value x qualifies when 2x appears in the same array.
2. Every value lies in [-10000, 10000], so every double lies in [-20000, 20000].
3. Adding 20000 maps each possible double to an index in [0, 40000].
4. One pass marks the values that appear in the array.
5. A second pass counts values whose doubled index is marked.
6. A single zero is counted because its double is itself.

| Term | Meaning |
|---|---|
| `valueOffset` | shift that maps -20000 to index zero |
| `tableSize` | number of slots for possible doubles |
| `presence` | marks each value that appears in the current case |
| `doubleCount` | number of values whose double is present |

The table is cleared at the start of each case.

Marking the sample values and testing doubles gives this trace:

```
marked:  1 2 3 4 7 9 18
1 -> 2 present
3 -> 6 absent
4 -> 8 absent
7 -> 14 absent
9 -> 18 present
2 -> 4 present
18 -> 36 absent
count: 3
```

The trace matches the first sample answer of three.

## Code

**Input and scanning.** The hand reader supports negative values with a sign branch.

```nim
const flushBlockBytes = 1 shl 17
const valueOffset = 20000
const tableSize = 40001

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value
```

A minus sign before the digits flips the result.
The scanner still skips spaces and line breaks.
Both limits stay fixed for the whole input.

**Output buffer.** The single buffer collects every answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Writes happen only after the buffer passes its block size.
A final write empties any leftover text.

**Mark and count.** Two linear passes answer one case.

```nim
let caseCount = nextInt(inputData, scanPos)
var presence = newSeq[bool](tableSize)
var caseIndex = 1
while caseIndex <= caseCount:
  let valueCount = nextInt(inputData, scanPos)
  for slot in 0 .. tableSize - 1:
    presence[slot] = false
  var values = newSeq[int](valueCount)
  for valueIndex in 0 .. valueCount - 1:
    values[valueIndex] = nextInt(inputData, scanPos)
    presence[values[valueIndex] + valueOffset] = true
  var doubleCount = 0
  for valueIndex in 0 .. valueCount - 1:
    let doubledValue = 2 * values[valueIndex]
    if presence[doubledValue + valueOffset]:
      doubleCount += 1
  appendOutput($doubleCount)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

Clearing the table keeps cases independent.
Marking and counting each take one pass over the values.
Repeated values each add one to the count when their double exists.

## Complexity

The two passes over the values dominate each case.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all values | one input string |
| Mark and count | two passes per case | one table and one value list |
| Output | one line per case | block buffer |

The table size stays constant because value bounds are fixed.

| Measure | Big O |
|---|---|
| Time | O(total values + T × 40001) |
| Space | O(N) per case |

A pairwise search would take O(N²) per case, so direct lookup wins.
