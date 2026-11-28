# GLASNICI — Glasnici (SPOJ)

<https://www.spoj.com/problems/GLASNICI/>

## Problem

Messengers stand along a straight road, and only the first knows the news. Everyone can run at speed one and shout within distance `K`. Report the least time until every messenger knows.

The first input line gives the test count `T`. Each test starts with real `K` and integer `N`, followed by `N` sorted real positions. Print one real number per test; answers within 0.01 of the official value pass.

| item | bound |
|---|---|
| tests T | 1 to 25 |
| hearing range K | 0 to 1000000 |
| messengers N | 1 to 100000 |
| position D | 0 to 1000000000, sorted ascending |
| judge limit | 2443 ms, 1536 MB |

The messenger count drives the need for a linear scan.

Sample input:

```
2
3.000 2
0.000
6.000
2.000 4
0.000
4.000
4.000
8.000
```

Sample output:

```
1.500
1.000
```

## Idea

Picture each messenger walking on a moving walkway that shifts left by `K` units per position. After that shift, the largest drop from any earlier messenger is twice the answer. One left-to-right pass tracks the lowest earlier shifted position. Binary search with a full simulation would test many candidate times. Take the shifted-drop rule as the whole algorithm.

## Why It Works

1. Write each final position as its start plus an offset in `[-t, t]`.
2. The first messenger uses the largest offset `t`, which maximises later reach.
3. Messenger `i` can gain at most `K` offset over messenger `i-1`, minus their starting gap.
4. Repeated caps at `t` mean the best offset for `i` uses some earlier messenger `j` as a fresh start.
5. For that pair, the needed time is half of `(d_i - d_j) - (i-j)*K`.
6. Rewriting gives `(d_i - i*K) - (d_j - j*K)`, so tracking the smallest earlier shifted value suffices.

| term | meaning |
|---|---|
| `shiftedPosition` | `d_i - i*K`, the position after the walkway shift |
| `smallestPast` | smallest `shiftedPosition` seen before the current messenger |
| `reachNeeded` | current shifted position minus `smallestPast` |
| `minimumTime` | half the largest positive `reachNeeded` |

These four terms reduce the whole propagation problem to one scan.

For `K = 3` and positions `0, 6`, the shifted values are `0` and `3`. The drop from `0` to `3` gives time `1.500`. For `K = 2` and positions `0, 4, 4, 8`, the shifted values are `0, 2, 0, 2`; the largest drop is `2`, giving `1.000`.

Both traces match the sample output.

## Code

**Input and scanning.** The hand reader stores stdin once and parses integers and reals.

```nim
import strutils

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

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.':
    pos += 1
  var whole = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    whole = whole * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var fraction = 0.0
    var scale = 10.0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fraction = fraction + float64(int(data[pos]) - 48) / scale
      scale = scale * 10.0
      pos += 1
    whole = whole + fraction
  return whole
```

The real parser handles both `3.000` and plain integers.
Positions are read in the given sorted order.
No sorting step is needed.

**Output buffer.** One string collects answers and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer keeps write calls rare across many tests.
A final write empties the remaining text.

**Shifted scan.** Each messenger updates the lowest earlier shifted value and the best time.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let hearingRange = nextReal(inputData, scanPos)
  let messengerCount = nextInt(inputData, scanPos)
  var positions = newSeq[float64](messengerCount)
  for messengerIndex in 0 .. messengerCount - 1:
    positions[messengerIndex] = nextReal(inputData, scanPos)
  var minimumTime = 0.0
  var smallestPast = positions[0]
  for messengerIndex in 1 .. messengerCount - 1:
    let shiftedPosition = positions[messengerIndex] - float64(messengerIndex) * hearingRange
    let reachNeeded = shiftedPosition - smallestPast
    if reachNeeded > 0.0 and reachNeeded / 2.0 > minimumTime:
      minimumTime = reachNeeded / 2.0
    if shiftedPosition < smallestPast:
      smallestPast = shiftedPosition
  appendOutput(formatFloat(minimumTime + 1e-9, ffDecimal, 3))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

One messenger needs one iteration.
The past minimum is updated after the current answer is tested.
The tiny epsilon aligns rounding at exact half-thousandths.

## Complexity

The scan touches each messenger once per test, so cost follows total messenger count.

| phase | time | space |
|---|---|---|
| input read | one pass over positions | one input string |
| shifted scan | one subtraction per messenger | one position array |
| output | one write per buffer block | block buffer |

The position array is the largest working structure.

| measure | Big O |
|---|---|
| time | O(N) per test |
| space | O(N) |

Simulating candidate times with binary search scans the array many times. The shifted rule scans it once.
