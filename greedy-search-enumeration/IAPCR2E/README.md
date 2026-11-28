# IAPCR2E — Ballons Revisited (SPOJ)
<https://www.spoj.com/problems/IAPCR2E/>

## Problem

Four balloons make one student happy, but the four must not share a single color. Given counts for white, red, green, and blue balloons, find the largest number of happy students.

Input begins with the case count `T`. Each case holds four integers `w r g b` on one line. Output one line per case as `Case k: S`.

| item | bound |
|---|---|
| cases T | up to 20000 |
| each color count | 0 to 1000000000 |
| balloons per student | exactly 4 |
| judge limit | 1000 ms, 1536 MB |

The largest color count drives the answer, together with the total balloon count.

Sample input:

```
2
2 2 1 3
1 1 4 1
```

Sample output:

```
Case 1: 2
Case 2: 1
```

## Idea

Think of the biggest color as a pile that can supply at most three balloons to each student. Two limits decide the answer: four balloons per student, and enough other colors to mix into every group.

The program computes the total and the largest color count. It takes the smaller of `total div 4` and `total - largestColor`. Each case costs O(1) with four comparisons.

Trying every possible four-balloon group explodes with the color counts. The two limits capture the same constraint without building any group.

Takeaway: count groups by the two global limits, not by enumerating groups.

## Why It Works

1. Each group uses four balloons, so at most `total div 4` groups exist.
2. A group cannot use four balloons of one color, so each group takes at most three of the dominant color.
3. If S groups are formed, at least `total - 4S` balloons remain unused.
4. The dominant color contributes at most `3S` balloons, so at least `largest - 3S` of it remain.
5. The two leftover bounds combine into `total - S >= largest`, or `S <= total - largest`.
6. Both bounds are reachable together, so the minimum of them is the exact answer.

| term | meaning |
|---|---|
| `totalBalloons` | sum of the four color counts |
| `largestColor` | largest single color count |
| `happyStudents` | the computed answer |
| `spareLimit` | `totalBalloons - largestColor` |

The sample has 8 balloons and largest color 3, so the answer is min(2, 5) = 2.

```
sample 1: w=2 r=2 g=1 b=3
total = 8, largest = 3
total div 4 = 2, total - largest = 5
answer = min(2, 5) = 2

sample 2: w=1 r=1 g=4 b=1
total = 7, largest = 4
total div 4 = 1, total - largest = 3
answer = min(1, 3) = 1
```

Counts of one billion fit in signed 64-bit integers, so the total never overflows.

## Code

**Input and scanner.** One read pass and an index scanner feed all cases.

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

The scanner skips whitespace between numbers. Every input value is nonnegative. Reading once keeps the driver independent of line breaks.

**Output helper.** All answer lines share one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes in large blocks. Twenty thousand cases produce far fewer than one flush in typical runs. One final write emits the tail.

**Answer loop.** Four integers give the total and the dominant color.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let whiteBalloons = int64(nextInt(inputData, scanPos))
  let redBalloons = int64(nextInt(inputData, scanPos))
  let greenBalloons = int64(nextInt(inputData, scanPos))
  let blueBalloons = int64(nextInt(inputData, scanPos))
  let totalBalloons = whiteBalloons + redBalloons + greenBalloons + blueBalloons
  var largestColor = whiteBalloons
  if redBalloons > largestColor:
    largestColor = redBalloons
  if greenBalloons > largestColor:
    largestColor = greenBalloons
  if blueBalloons > largestColor:
    largestColor = blueBalloons
  var happyStudents = totalBalloons div 4
  let spareLimit = totalBalloons - largestColor
  if spareLimit < happyStudents:
    happyStudents = spareLimit
  appendOutput("Case ")
  appendOutput($(caseIndex + 1))
  appendOutput(": ")
  appendOutput($happyStudents)
  outputBuffer.add '\n'
```

Values are widened to `int64` before summing. Three comparisons find the dominant color. The smaller limit becomes the printed answer.

## Complexity

Each case runs in constant time.

| phase | time | space |
|---|---|---|
| input read | one pass over the stream | input string |
| per case arithmetic | four comparisons and two sums | a few integers |
| output | one line per case | block buffer |

The per-case arithmetic dominates and uses a fixed number of operations.

| measure | Big O |
|---|---|
| time per case | O(1) |
| total time | O(T) |
| working space | O(1) beyond input |

Enumerating balloon groups would cost time proportional to the color counts. The two global limits replace that work entirely.

Takeaway: the dominant color and the total decide every case.
