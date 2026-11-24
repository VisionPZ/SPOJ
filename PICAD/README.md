# PICAD — Crime at Piccadily Circus (SPOJ)

## Problem

Read a time window and a set of people intervals. Each person stays from moment `a` to moment `b`, both ends included. Time flows continuously, so a person leaves immediately after moment `b`. Print the smallest and largest number of people present at any moment of the window.

The spec gives these bounds:

| item | bound |
|---|---|
| window `p`, `k` | 0 ≤ p ≤ k ≤ 100 000 000 |
| people `n` | 3 ≤ n ≤ 5 000 |
| stay endpoints `a`, `b` | 0 ≤ a ≤ b ≤ 1 000 000 000 |
| judge limits | 13 s, 1536 MB |

The window span is large, but the number of moments per case stays small.

Sample input:

```
5 10
4
1 8
5 8
7 10
8 9
```

Sample output:

```
1 4
```

## Idea

The count changes only when someone arrives or leaves. Collect those moments, add the two window ends, sort them, and sweep them once. At each moment, add arrivals, read the count at that exact moment, remove departures, and read the count in the gap that follows. Keep the smallest and largest value seen inside the window. Sorting costs O(n log n) per case, and the sweep visits each moment once. Checking every integer moment would scan up to 100 000 000 values per case.

## Why It Works

Time is a line, not a row of whole seconds. A person with stay (5, 6) is still present at 6, and a person with stay (8, 9) is absent at 7.5. Between two adjacent moments the count cannot change, so one sample per gap covers the whole gap.

The count at an exact moment uses these terms:

| term | meaning |
|---|---|
| arrivals ≤ t | people who appeared at or before moment t |
| departures < t | people who left strictly before moment t |
| arrivals ≤ t − departures < t | people present at moment t |
| arrivals ≤ t − departures ≤ t | people present immediately after moment t |

A departure at t is removed only after the moment is read, so the person still counts at t.

A repeated moment must be removed before the sweep. Without this step, the second pass reads a count from the wrong side of the departures. It can then print a minimum below the true one.

Here is the sample traced by a script. added counts arrivals at the moment, removed counts departures at it, and gap_used marks a gap inside the window.

```
moment  added  at_moment  removed  after  in_window  gap_used
     1      1          1        0      1      False     False
     5      1          2        0      2       True      True
     7      1          3        0      3       True      True
     8      1          4        2      2       True      True
     9      0          2        1      1       True      True
    10      0          1        1      0       True     False
```

The largest value is 4 at moment 8, and the smallest is 1 in the gap after 9.

## Code

**Constants and reader.** `digitBase` is the value of the digit zero. `flushBlockBytes` is the 128 KiB output block.

```nim
import algorithm

const digitBase = 48
const flushBlockBytes = 1 shl 17
```

The reader has two bounds: the buffer length and the end of the digits. The sign branch keeps negative input safe.

```nim
proc skipSpaces(inputData: string, i: var int) =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1

proc hasToken(inputData: string, i: int): bool =
  var j = i
  while j < inputData.len and inputData[j] <= ' ':
    j = j + 1
  return j < inputData.len

proc nextInt(inputData: string, i: var int): int =
  skipSpaces(inputData, i)
  var negative = false
  if i < inputData.len and inputData[i] == '-':
    negative = true
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - digitBase
    i = i + 1
  if negative:
    return -value
  return value
```

`hasToken` checks the rest of the buffer, so the program stops at end of input instead of expecting ten cases. `nextInt` advances `i` by index and builds no token string. The digit loop runs once per digit.

**Input and reusable arrays.** One loop collects every line into `inputData`.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var outputBuffer: string
var arrivalTimes: seq[int] = @[]
var departureTimes: seq[int] = @[]
var criticalTimes: seq[int] = @[]
```

The read loop ends when `readLine` returns false. The three sequences are reused across cases, so no case allocates a new one.

**Case reader and sort.** The outer loop runs once per case while tokens remain.

```nim
while hasToken(inputData, i):
  var crimeStart = nextInt(inputData, i)
  var crimeEnd = nextInt(inputData, i)
  var peopleCount = nextInt(inputData, i)

  arrivalTimes.setLen(peopleCount)
  departureTimes.setLen(peopleCount)
  criticalTimes.setLen(2 * peopleCount + 2)

  for j in 0 ..< peopleCount:
    var arrival = nextInt(inputData, i)
    var departure = nextInt(inputData, i)
    arrivalTimes[j] = arrival
    departureTimes[j] = departure
    criticalTimes[2 * j] = arrival
    criticalTimes[2 * j + 1] = departure

  criticalTimes[2 * peopleCount] = crimeStart
  criticalTimes[2 * peopleCount + 1] = crimeEnd

  sort(arrivalTimes, system.cmp[int])
  sort(departureTimes, system.cmp[int])
  sort(criticalTimes, system.cmp[int])
```

The closed form of the moment count is 2n + 2. The `for` loop bound is `peopleCount`, and each pass reads two integers. `sort` orders all three sequences.

**Deduplication.** The loop bound is the original length of `criticalTimes`.

```nim
  var uniqueCount = 0
  for j in 0 ..< criticalTimes.len:
    if j == 0 or criticalTimes[j] != criticalTimes[j - 1]:
      criticalTimes[uniqueCount] = criticalTimes[j]
      uniqueCount = uniqueCount + 1
  criticalTimes.setLen(uniqueCount)
```

The write goes into the same sequence, so no second array is built. This step removes repeated moments before the sweep reads them.

**Sweep.** The loop bound is the deduplicated length of `criticalTimes`.

```nim
  var presentCount = 0
  var k = 0
  var l = 0
  var minPresent = high(int)
  var maxPresent = -1

  for j in 0 ..< criticalTimes.len:
    var moment = criticalTimes[j]
    while k < peopleCount and arrivalTimes[k] <= moment:
      presentCount = presentCount + 1
      k = k + 1
    if crimeStart <= moment and moment <= crimeEnd:
      if presentCount < minPresent: minPresent = presentCount
      if presentCount > maxPresent: maxPresent = presentCount
    while l < peopleCount and departureTimes[l] <= moment:
      presentCount = presentCount - 1
      l = l + 1
    if j + 1 < criticalTimes.len and moment < crimeEnd and criticalTimes[j + 1] > crimeStart:
      if presentCount < minPresent: minPresent = presentCount
      if presentCount > maxPresent: maxPresent = presentCount
```

Arrivals enter before the window test, and departures leave after it. The gap test needs a following moment and an overlap with the window. The value at the right end then stays inside the answer.

**Output.** The flush bound is `flushBlockBytes`, checked once per case.

```nim
  outputBuffer.add $minPresent
  outputBuffer.add ' '
  outputBuffer.add $maxPresent
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

Each case adds one line, so the buffer holds at most ten lines at the legal limit. The last write emits any remaining bytes.

## Complexity

The phases cost the following:

| phase | time | space |
|---|---|---|
| input read | one line pass, then one digit pass | input bytes |
| per case sort | three sorts of up to 10 002 values | 10 002 ints |
| dedup and sweep | one pass over 10 002 moments | constant |
| output | one write per case | 128 KiB |
| total at ten cases | sorting 100 000 stays and 100 020 moments | input bytes plus 128 KiB |

Sorting dominates each case, and the arrays scale with n, not with the window span.

In Big O terms:

| measure | Big O |
|---|---|
| time | O(n log n) per case, dominated by sorting |
| space | O(n) per case for the moment list |

A scan of every integer moment costs O((k − p) × n) per case, which is far larger.
