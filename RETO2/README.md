# RETO2 — Time Together, Grade 10 (SPOJ)

<https://www.spoj.com/problems/RETO2/>

## Problem

Sonya the owl is awake from minute `L1` through minute `R1`, inclusive. During minute `k` she preens and cannot see anyone. Filya the hedgehog visits from minute `L2` through minute `R2`, inclusive. Count the minutes when both are available together.

The only input line holds the five integers `L1`, `R1`, `L2`, `R2`, and `k`. Print one integer, the number of shared minutes.

| Item | Bound |
|---|---|
| `L1`, `R1`, `L2`, `R2`, `k` | 1 to 10<sup>18</sup> |
| Order | `L1` <= `R1` and `L2` <= `R2` |
| Judge limit | 1000 ms, 1536 MB |

The first sample input:

```
1 10 9 20 1
```

The first sample output:

```
2
```

The second sample input:

```
1 100 50 200 75
```

The second sample output:

```
50
```

## Idea

Think of two opening windows on a calendar and one hour blocked out for grooming. The shared time is the calendar overlap, minus that blocked hour if it falls inside.

The program clips the two inclusive intervals to their intersection. When the clipped start passes the clipped end, the answer is zero. Otherwise it takes the inclusive length and subtracts one if `k` lies inside. Every step uses a fixed number of integer operations.

## Why It Works

1. They can meet only at minutes when both are present.
2. Sonya is present throughout `[L1, R1]` except at minute `k`.
3. Filya is present throughout `[L2, R2]`.
4. The shared minutes form the intersection of those two intervals.
5. An inclusive interval `[a, b]` contains `b - a + 1` minutes.
6. The preening minute affects the count only when it lies in the intersection.

| Term | Meaning |
|---|---|
| `sonyaStart` | first awake minute `L1` |
| `sonyaEnd` | last awake minute `R1` |
| `filyaStart` | first visiting minute `L2` |
| `filyaEnd` | last visiting minute `R2` |
| `preenMoment` | minute `k` when Sonya is busy |
| `overlapStart` | later of the two interval starts |
| `overlapEnd` | earlier of the two interval ends |

A script-generated trace of both samples:

```
sample 1: intersection [9, 10], length 2, k=1 outside -> 2
sample 2: intersection [50, 100], length 51, k=75 inside -> 50
disjoint check: [1, 10] and [20, 30] have no common minute -> 0
```

Both traced answers match the sample outputs.

## Code

**Input and scanner.** Read all lines once and parse the five large values as 64-bit integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner builds values directly in `int64`. The bounds reach 10<sup>18</sup>, beyond a 32-bit integer.

**Driver.** Clip the intervals, then account for the busy minute.

```nim
let sonyaStart = nextInt64(inputData, scanPos)
let sonyaEnd = nextInt64(inputData, scanPos)
let filyaStart = nextInt64(inputData, scanPos)
let filyaEnd = nextInt64(inputData, scanPos)
let preenMoment = nextInt64(inputData, scanPos)
var overlapStart = sonyaStart
if filyaStart > overlapStart:
  overlapStart = filyaStart
var overlapEnd = sonyaEnd
if filyaEnd < overlapEnd:
  overlapEnd = filyaEnd
if overlapStart > overlapEnd:
  appendOutput("0\n")
else:
  var answer = overlapEnd - overlapStart + 1
  if preenMoment >= overlapStart and preenMoment <= overlapEnd:
    answer -= 1
  appendOutput($answer & "\n")
stdout.write outputBuffer
```

The larger start and smaller end define the intersection. A crossed interval returns zero before any subtraction.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Interval clip | O(1) comparisons | O(1) |
| Output | one short write | one output string |

| Measure | Big O |
|---|---|
| Time | O(input size) |
| Space | O(1) beyond input |

Walking every minute would take up to 10<sup>18</sup> steps. The intersection formula needs only a few comparisons.
