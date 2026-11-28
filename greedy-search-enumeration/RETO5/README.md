# RETO5 — Juicer (SPOJ)

<https://www.spoj.com/problems/RETO5/>

## Problem

Kolya squeezes oranges in a fixed order and counts how often he empties the waste bin. Oversized oranges never enter the juicer.

The input gives the orange count, the largest size that fits, and the bin capacity. The next line gives each orange size. Print the number of times the bin is emptied.

| Item | Bound |
|---|---|
| Orange count | 1 to 100000 |
| Largest fitting size | 1 to 10^6 |
| Bin capacity | 1 to 10^6, at least the largest fitting size |
| Orange size | 1 to 10^6 |
| Judge limit | 2000 ms, 1536 MB |

The final nonempty bin also needs one empty, even when no oranges remain.

The statement shows two samples:

```
2 7 10
5 6
```

```
1
```

```
1 5 10
7
```

```
0
```

The second orange in the first sample makes the total exceed 10.

## Idea

Think of a bin that tips over when its load passes a mark. The orange causing the tip falls out with the waste.

Keep a running total of accepted orange sizes. Add each size, and when the total passes the capacity, count one empty and reset the total to zero. The orange that caused the overflow does not join the new total. At the end, a positive total adds one more empty.

Each orange costs one addition and one comparison, so the work is O(n). Trying every possible group of oranges would take exponential time. A single running sum records the answer.

## Why It Works

1. An orange larger than the fitting limit never reaches the bin.
2. A bin total above capacity triggers exactly one empty and resets the total.
3. The triggering orange is discarded, so the next bin starts empty.
4. A nonempty bin at the end must be emptied once more.

The main terms and their meanings:

| Term | Meaning |
|---|---|
| `wasteSum` | current total of waste in the bin |
| `emptyCount` | number of empties already counted |
| `largestFittingSize` | upper limit for an orange to enter the juicer |
| `wasteCapacity` | total that the bin can hold |

The four terms cover the whole state of the process.

The trace from `gen.py` covers four chosen sizes.

```
accepted sizes [5, 6, 3, 2], capacity 10
prefix sums [0, 5, 11, 14, 16]
block starts at 0, threshold 10, overflow at 2
block starts at 2, threshold 21, overflow at 5
final block from 2 emptied once
answer 2
```

Sizes 5 and 6 fill the first bin; size 6 tips it, and size 3 fills the last bin.

## Code

**Input and output helpers.** All values are read once and scanned by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInteger(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos += 1
  var parsedValue = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return signValue * parsedValue

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

The buffer holds output until it reaches 128 KiB. The scanner skips spaces and line breaks.

**Waste sweep.** One pass handles fitting, overflow, and the final empty.

```nim
let orangeCount = int(nextInteger(inputData, scanPos))
let largestFittingSize = nextInteger(inputData, scanPos)
let wasteCapacity = nextInteger(inputData, scanPos)
var emptyCount = 0'i64
var wasteSum = 0'i64
for orangeIndex in 0 ..< orangeCount:
  let orangeSize = nextInteger(inputData, scanPos)
  if orangeSize > largestFittingSize:
    continue
  wasteSum += orangeSize
  if wasteSum > wasteCapacity:
    emptyCount += 1
    wasteSum = 0
if wasteSum > 0'i64:
  emptyCount += 1

appendOutput($emptyCount)
outputBuffer.add '\n'
stdout.write outputBuffer
```

The loop visits each orange once. Resetting to zero discards the orange that overflowed the bin.

## Complexity

One sweep over the orange list gives the full answer.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input buffer |
| Waste sweep | one pass over n sizes | two counters |
| Output | one write per 128 KiB block | output buffer |

No orange list is stored, so memory stays small.

The asymptotic bounds are:

| Measure | Big O |
|---|---|
| Time | O(n) |
| Space | O(input bytes) |

Enumerating groups of oranges would waste time; the running total decides each empty as it happens.
