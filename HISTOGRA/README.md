# HISTOGRA — Largest Rectangle in a Histogram (SPOJ)

<https://www.spoj.com/problems/HISTOGRA/>

## Problem

Given `n` adjacent unit-width bars of heights `h_1, ..., h_n` aligned on a common baseline, find the largest axis-aligned rectangle contained inside the histogram.

Input consists of multiple test cases ending with `0`. Each test case starts with `n` followed by `n` non-negative integers on the same line. Output one line per test case with the maximum rectangle area.

This table lists the constraints and judge limits.

| item | bound |
|---|---|
| bar count `n` | 1 <= n <= 100 000 |
| bar height `h_i` | 0 <= h_i <= 10^9 |
| max area | 10^14 (fits in 64-bit integer) |
| judge limit | 800 ms, 1536 MB, 50000 B |

Area can reach `10^14`, so heights and areas must use 64-bit integers.

Sample input:

```
7 2 1 4 5 1 3 3
4 1000 1000 1000 1000
0
```

Sample output:

```
8
4000
```

## Idea

Scanning the histogram is like sliding a horizontal ceiling beam across rooftops until a shorter building blocks it. A monotonic increasing stack (a stack whose heights stay strictly increasing) tracks each active bar's height and the leftmost index where that height can start. When a shorter bar arrives, every taller bar on the stack ends right here, so pop it, score `height * width`, and inherit its start index, taking `O(n)` time.

Testing every left-right interval takes `O(n^2)` time, which times out for `n = 100 000`.

## Why It Works

1. Any optimal rectangle matches the height of some bar `i` and extends as far left and right as bars stay at least `h_i` tall.
2. When a bar on the stack is popped at `barIdx`, `barIdx` is the first index to its right with height `<= stackHeight[stackTop]`.
3. Passing `spanStart = stackStart[stackTop]` to the incoming shorter bar records the furthest left index where the incoming height still fits.
4. Appending a virtual bar of height `0` at `barIdx = barCount` flushes every remaining bar from the stack without a second cleanup loop.

This table maps each stack array to its role.

| term | meaning |
|---|---|
| `stackHeight` | strictly increasing heights of open rectangles |
| `stackStart` | leftmost bar index where each open rectangle begins |
| `spanStart` | inherited left boundary for the current bar |
| `bestArea` | maximum rectangle area seen so far |

Every bar enters and leaves the stack at most once.

Worked example for `2 1 4 5 1 3 3`:

```
idx 0 (h=2): push (2, start=0)
idx 1 (h=1): pop (2,0) area=2*1=2; push (1, start=0)
idx 2 (h=4): push (4, start=2)
idx 3 (h=5): push (5, start=3)
idx 4 (h=1): pop (5,3) area=5*1=5; pop (4,2) area=4*2=8; pop (1,0) area=1*4=4; push (1, start=0)
idx 5 (h=3): push (3, start=5)
idx 6 (h=3): pop (3,5) area=3*1=3; push (3, start=5)
idx 7 (h=0): pop (3,5) area=3*2=6; pop (1,0) area=1*7=7
best area  : 8
```

The maximum popped area is 8 (height 4 across bars 2 and 3).

## Code

**Bulk input, digit scanner, and output buffer.** Reads stdin once, scans non-negative integers directly from the buffer, and flushes output in 128 KiB blocks.

```nim
const flushBlockBytes = 1 shl 17
const maxBars = 100005

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Scanning bars on the fly avoids storing the full input array per test case.

**Monotonic stack pass.** Hoists `stackHeight` and `stackStart`, runs `barCount + 1` steps per test case with a trailing zero sentinel, and updates `bestArea`.

```nim
var stackHeight = newSeq[int64](maxBars)
var stackStart = newSeq[int](maxBars)

while scanPos < inputData.len:
  let barCount = nextInt(inputData, scanPos)
  if barCount == 0:
    break
  var stackTop = 0
  var bestArea: int64 = 0
  for barIdx in 0 .. barCount:
    let currentHeight = if barIdx < barCount: int64(nextInt(inputData, scanPos)) else: 0'i64
    var spanStart = barIdx
    while stackTop > 0 and stackHeight[stackTop - 1] >= currentHeight:
      stackTop -= 1
      let width = int64(barIdx - stackStart[stackTop])
      let area = stackHeight[stackTop] * width
      if area > bestArea:
        bestArea = area
      spanStart = stackStart[stackTop]
    if currentHeight > 0:
      stackHeight[stackTop] = currentHeight
      stackStart[stackTop] = spanStart
      stackTop += 1
  appendOutput($bestArea)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

Skipping pushes when `currentHeight == 0` keeps zero-height bars off the stack and acts as a clean boundary. Both `width` and `stackHeight` are `int64`, preventing 32-bit multiplication overflow.

## Complexity

This table summarizes time and space per test case of `n` bars.

| phase | time | space |
|---|---|---|
| scan and stack updates | O(n) | O(n) |
| emit answer | O(1) | O(1) |

Each bar is pushed once and popped once, so total stack operations stay under `2n`.

This table states the overall Big O bounds per test case.

| measure | big O |
|---|---|
| time | O(n) |
| space | O(n) |

Checking every interval costs `O(n^2)` time, while the monotonic stack clears `n = 100 000` in a few milliseconds.
