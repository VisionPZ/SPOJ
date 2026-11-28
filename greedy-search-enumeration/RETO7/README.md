# RETO7 — Infinite Hotel (SPOJ)

<https://www.spoj.com/problems/RETO7/>

## Problem

Groups enter a hotel one after another. Each group has one more member than the previous group and stays for as many days as it has members. Find the group present on a given day.

Each input line gives the starting size and the requested day. Print the size of the group staying that day. Input ends at end of file.

| Item | Bound |
|---|---|
| Starting size | 1 to 10000 |
| Requested day | 1 to 10^15 - 1 |
| Answer | below 10^15 |
| Judge limit | 1000 ms, 1536 MB |

Days are counted from one, so the first group occupies days one through its size.

The statement shows one sample:

```
1 6
3 10
3 14
```

```
3
5
6
```

A group of three starting on day four covers days four through six.

## Idea

Think of counting seats in theater rows, where each row has one more seat than the row before. The requested day falls inside one row.

The first k groups occupy k(2S + k - 1)/2 days, where S is the starting size. This total grows with k, so binary search finds the largest k whose total is still before the requested day. The answer is S + k. Each line takes about 30 steps.

Walking through days one by one would take as long as the answer, up to millions of steps. The closed total jumps straight to the right group.

## Why It Works

1. Group sizes form a run S, S + 1, S + 2, and so on.
2. The first k groups fill k(2S + k - 1)/2 days.
3. The group on day D is the first one whose prefix reaches D.
4. Binary search on k works because the prefix grows strictly.
5. The 64-bit product stays small for the stated bound.

The main terms and their meanings:

| Term | Meaning |
|---|---|
| `initialGroupSize` | size S of the first group |
| `requestedDay` | day D to identify |
| `elapsedDays` | days filled by the first k groups |
| `lowerGroupCount` | largest k with fewer than D days filled |
| `searchUpperBound` | fixed high end of the binary search |

The terms follow the search bounds in the program.

A trace from `gen.py` on the sample:

```
start 1, day 6: first 2 groups fill 3 days, group 3 has 3 members
start 3, day 10: first 2 groups fill 7 days, group 3 has 5 members
start 3, day 14: first 3 groups fill 12 days, group 4 has 6 members
next group starts after 7 days for start size 3
```

Each prefix stops immediately before the requested day.

## Code

**Input and helpers.** The scanner reads integers, and the pair test handles end of file.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const searchUpperBound = 1000000000'i64

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

proc hasMorePairs(inputData: string, scanPos: var int): bool =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  return scanPos < inputData.len
```

The upper bound keeps the product inside 64-bit range. Trailing spaces do not create an extra pair.

**Output buffer.** Answers enter one growable buffer.

```nim
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

The final write empties any remainder. No output happens inside the search loop.

**Binary search.** Each line finds the finished groups before the requested day.

```nim
while hasMorePairs(inputData, scanPos):
  let initialGroupSize = nextInteger(inputData, scanPos)
  let requestedDay = nextInteger(inputData, scanPos)
  var lowerGroupCount = 0'i64
  var upperGroupCount = searchUpperBound
  while lowerGroupCount < upperGroupCount:
    let middleGroupCount = (lowerGroupCount + upperGroupCount + 1'i64) div 2'i64
    let elapsedDays = middleGroupCount * (2'i64 * initialGroupSize + middleGroupCount - 1'i64) div 2'i64
    if elapsedDays < requestedDay:
      lowerGroupCount = middleGroupCount
    else:
      upperGroupCount = middleGroupCount - 1'i64
  appendOutput($(initialGroupSize + lowerGroupCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
```

The loop uses an upper midpoint, so it always makes progress. Each step halves the search interval.

## Complexity

The search cost multiplies by the number of input lines.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input buffer |
| Binary search | about 30 steps per line | three counters |
| Output | one write per 128 KiB block | output buffer |

The line count sets the total time.

The asymptotic bounds are:

| Measure | Big O |
|---|---|
| Time | O(L log 10^9) for L lines |
| Space | O(input bytes) |

Counting days one at a time could run for millions of steps per line. The prefix formula needs only a short search.
