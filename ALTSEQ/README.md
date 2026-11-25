# ALTSEQ — Alternating Sequences (SPOJ)

<https://www.spoj.com/problems/ALTSEQ/>

## Problem

Find the longest subsequence whose absolute values grow at every step and whose signs alternate at every step. Nonzero integers arrive in one array, and the answer is a single length.

The first line holds the array size. The next line holds that many integers. Print one integer, the longest valid subsequence length.

| Item | Bound |
|---|---|
| Array size N | 1 to 5000 |
| Each value | nonzero, absolute value at most 1000000000 |
| Judge limit | 1000 ms, 1536 MB |

The sample array has eight values:

```
8
1 2 -2 -3 5 -7 -8 10
```

The expected output is:

```
5
```

## Idea

Pick members like a lineup where each new person must be taller and must wear the opposite jersey, like picking players by height from alternating teams. Keep the best length ending at each position, then extend it from any earlier value with the opposite sign and smaller magnitude. Each extension costs one comparison, while testing every subsequence would cost exponential work. The answer is the largest stored length.

## Why It Works

1. A subsequence keeps the original order of the chosen array values.
2. Only a smaller absolute value may appear before the current value.
3. Only a value of the opposite sign may appear before the current value.
4. The best chain ending at an earlier value is enough to extend, since later choices depend only on that value and its sign.
5. Checking every earlier value covers all legal chain ends, including non-adjacent ones.
6. Starting every length at one handles a subsequence of a single value.

| Term | Meaning |
|---|---|
| `sequenceValues` | the input array, stored as signed 64-bit values |
| `bestLengths` | best alternating length ending at each index |
| `currentMagnitude` | absolute value of the current element |
| `bestLength` | largest length seen so far |

Magnitudes use 64-bit arithmetic so the sign flip of -1000000000 stays exact.

Tracing the sample ends at the chain 1, -2, 5, -7, 10:

```
1   -> length 1
-2  -> 1 then -2, length 2
5   -> 1 then -2 then 5, length 3
-7  -> length 4
10  -> length 5
```

The trace matches the sample output of five.

## Code

**Input and scanning.** The hand reader loads the size and the signed values.

```nim
const flushBlockBytes = 1 shl 17

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

proc magnitudeOf(value: int64): int64 =
  if value < 0:
    return -value
  return value
```

The minus sign stops the skip loop before parsing digits.
The magnitude helper avoids a floating point absolute value.
All input values fit in a signed 64-bit integer.

**Output buffer.** The result is appended once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The block buffer keeps writes rare.
One final write flushes the answer line.

**Length DP.** Each index extends every earlier index of the opposite sign.

```nim
let valueCount = nextInt(inputData, scanPos)
var sequenceValues = newSeq[int64](valueCount)
for valueIndex in 0 .. valueCount - 1:
  sequenceValues[valueIndex] = int64(nextInt(inputData, scanPos))
var bestLengths = newSeq[int](valueCount)
var bestLength = 1
for currentIndex in 0 .. valueCount - 1:
  bestLengths[currentIndex] = 1
  let currentValue = sequenceValues[currentIndex]
  let currentMagnitude = magnitudeOf(currentValue)
  var previousIndex = 0
  while previousIndex < currentIndex:
    let previousValue = sequenceValues[previousIndex]
    let oppositeSign = (previousValue > 0 and currentValue < 0) or (previousValue < 0 and currentValue > 0)
    if oppositeSign and magnitudeOf(previousValue) < currentMagnitude:
      if bestLengths[previousIndex] + 1 > bestLengths[currentIndex]:
        bestLengths[currentIndex] = bestLengths[previousIndex] + 1
    previousIndex += 1
  if bestLengths[currentIndex] > bestLength:
    bestLength = bestLengths[currentIndex]
appendOutput($bestLength)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Every earlier index is tested, not only the previous one.
Strict magnitude comparison rejects equal absolute values.
The running maximum is written after the loop.

## Complexity

The nested loop over index pairs dominates.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the array | one input string |
| Length DP | one comparison per ordered pair | one length per value |
| Output | one line | block buffer |

No subsequence is ever built or stored.

| Measure | Big O |
|---|---|
| Time | O(N²) |
| Space | O(N) |

Enumerating every subsequence would cost O(2ᴺ), so the pair DP wins.
