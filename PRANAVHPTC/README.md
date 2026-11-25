# PRANAVHPTC — A hard problem to crack (SPOJ)

<https://www.spoj.com/problems/PRANAVHPTC/>

## Problem

Two people stand at seats on a circle of N seats. Report the shorter of the two arc distances between them. Print one answer line per test case.

The first line gives the case count. Each following line gives N, A and B, where N runs up to 10^14. Seats are numbered from one to N.

| item | bound |
|---|---|
| test cases | 1 to 1000 |
| seats N | 1 to 10^14 |
| positions A, B | positive integers |
| judge limit | 1000 ms, 1536 MB |

Both directions around the circle are always available.

Sample input:

```
4
9 1 3
8 4 5
5 1 2
8 2 4
```

Sample output:

```
2
1
1
2
```

## Idea

Imagine walking around a circular track from one friend to the other. Going forward covers one arc, and going backward covers the other arc. The answer is the smaller arc length.

The real algorithm reduces each position modulo N, then takes the gap in both directions. Each case costs constant time with int64 arithmetic. Simulating every seat would cost O(N) per case and cannot handle N up to 10^14. The takeaway is that reducing modulo N handles any positive position.

## Why It Works

1. The seats form a circle with N equally spaced positions.
2. Reducing a position modulo N maps it onto that circle.
3. Walking forward gives one gap, and walking backward gives the other gap.
4. Both gaps lie between zero and N minus one after normalization.
5. The smaller of those two gaps is the shortest distance.

| term | meaning |
|---|---|
| `totalSeats` | number of seats around the circle |
| `firstSeat` | position of the first person |
| `secondSeat` | position of the second person |
| `forwardGap` | forward steps from first seat to second seat |
| `backwardGap` | backward steps from first seat to second seat |
| `directDistance` | shorter of the two gaps |

For the first sample, seats 1 and 3 on a nine-seat circle are two seats apart forward. The backward gap is seven, so the answer is two.

All gaps are differences of int64 values, so large seat counts stay exact.

## Code

**Input and scanner.** The hand reader loads the case count and each triple of values.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Whitespace between numbers is skipped automatically.
Each parsed value advances the scan position.
Buffered output collects every answer line.

**Arc comparison.** Both directed gaps are normalized and compared once per case.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let totalSeats = int64(nextInt(inputData, scanPos))
  let firstSeat = int64(nextInt(inputData, scanPos))
  let secondSeat = int64(nextInt(inputData, scanPos))
  var forwardGap = (secondSeat - firstSeat) mod totalSeats
  if forwardGap < 0:
    forwardGap += totalSeats
  var backwardGap = (firstSeat - secondSeat) mod totalSeats
  if backwardGap < 0:
    backwardGap += totalSeats
  var directDistance = forwardGap
  if backwardGap < directDistance:
    directDistance = backwardGap
  appendOutput($directDistance)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each modulo result is shifted into the non-negative range.
The smaller gap is appended once.
Positions beyond N wrap onto the circle correctly.
The final write empties the buffer.

## Complexity

Each test case reads three numbers and performs a fixed number of comparisons.

| phase | time | space |
|---|---|---|
| input read | one pass over all numbers | one input string |
| arc comparison | constant work per case | constant extra space |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time | O(t) for t test cases |
| space | O(1) beyond input and output |

Walking seat by seat would cost O(N) per case and would fail for large N.
The two directed gaps keep every case constant time.
