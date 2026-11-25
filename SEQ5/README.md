# SEQ5 — How many subsequences (SPOJ)

<https://www.spoj.com/problems/SEQ5/>

## Problem

A row of positive integers offers many contiguous subsequences, and each one has a number of distinct values. Count the subsequences whose distinct-value count lies between a lower and an upper bound.

The first input line holds `N`, `L`, and `U`. The next `N` lines each hold one positive integer. The output is one integer: the count of contiguous subsequences with at least `L` and at most `U` distinct values.

The bounds from the statement:

| item | bound |
|---|---|
| length N | 1 to 220 |
| bounds L and U | 1 to L at most U at most N |
| item value | 1 to 2 to the power 32 minus 1 |
| judge limit | 100 ms, 1536 MB |

The length bound keeps a repeated scan affordable, while values need a 64-bit slot.

Sample input:

```
4 1 2
231
19
7
19
```

Sample output:

```
8
```

## Idea

Slide a frame along the row and track which colours sit inside it, like counting pictures with two or three colours. For a fixed left end, grow the right end until the frame holds too many distinct values.

The algorithm scans every left end and extends a right end incrementally. A new value adds one to the distinct count only on its first appearance in the current window. Each extension costs a short search over earlier positions in that window.

Rebuilding a set from scratch for every window would repeat work and allocate memory for each of the roughly N squared windows. The incremental check reuses the values already scanned and stops as soon as the upper bound is broken.

Counting every window once from each left end yields the exact total.

## Why It Works

1. Every contiguous subsequence has a unique left end and right end, so scanning left ends visits each one once.
2. While extending a window, a value is new exactly when it is absent from the earlier part of that window.
3. The distinct count changes only when a new value appears, so the running count stays correct.
4. Once the distinct count passes `upperDistinct`, longer windows from the same left end also pass it.
5. A window is counted exactly when its distinct count lies from `lowerDistinct` through `upperDistinct`.

The main terms and formulas:

| term | meaning |
|---|---|
| `seriesValues` | the input numbers in row order |
| `distinctCount` | distinct values in the current window |
| `seenBefore` | whether the new value already appeared in the window |
| `subsequenceCount` | running total of qualifying windows |

The table lists the only state kept during the scan.

The gen.py oracle counts windows with at most U distinct values and subtracts those with at most L minus 1. On the sample it produces these numbers:

```
windows with at most 2 distinct = 8
windows with at most 0 distinct = 0
answer = 8 - 0 = 8
```

The trace agrees with the eight subsequences counted by hand in the sample.

## Code

**Input and scanner.** One read gathers all lines, and the parser skips whitespace.

```nim
const flushBlockBytes = 1 shl 17

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
```

The reader accepts values on separate lines or packed together.
The scanner needs no sign branch because all values are positive.
A 64-bit `int` holds the largest allowed value.

**Window scan.** Each left end grows a window until it holds too many distinct values.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let seriesLength = nextInt(inputData, scanPos)
let lowerDistinct = nextInt(inputData, scanPos)
let upperDistinct = nextInt(inputData, scanPos)
var seriesValues = newSeq[int](seriesLength)
for valueIndex in 0 .. seriesLength - 1:
  seriesValues[valueIndex] = nextInt(inputData, scanPos)

var subsequenceCount: int64 = 0
for leftIndex in 0 .. seriesLength - 1:
  var distinctCount = 0
  for rightIndex in leftIndex .. seriesLength - 1:
    var seenBefore = false
    for checkIndex in leftIndex ..< rightIndex:
      if seriesValues[checkIndex] == seriesValues[rightIndex]:
        seenBefore = true
        break
    if not seenBefore:
      distinctCount += 1
    if distinctCount > upperDistinct:
      break
    if distinctCount >= lowerDistinct:
      subsequenceCount += 1

appendOutput($subsequenceCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The break stops work once the upper bound is crossed.
The count uses `int64` even though 220 values give a small total.
One buffered write emits the answer line.

## Complexity

The scan repeats a short search for each pair of window ends.

| phase | time | space |
|---|---|---|
| input read | one pass over N values | one array of N integers |
| window scan | up to N squared extensions | a few counters |
| output | one line | block buffer |

The inner duplicate search dominates when windows are long.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(N cubed) worst case |
| space | O(N) |

Rebuilding a distinct-value set for every window would also cost cubic time, with extra allocation on each window.

The incremental scan keeps those allocations out of the hot loop.
