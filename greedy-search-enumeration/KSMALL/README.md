# KSMALL — K-th smallest number (SPOJ)

<https://www.spoj.com/problems/KSMALL/>

## Problem

A C-style generator produces five million 32-bit values from four parameters. Report the `K`-th smallest generated value.

Input: one line with `a b mod K`. Output: one integer, the `K`-th smallest value.

| item | bound |
|---|---|
| seeds `a`, `b` | 0 to 65535 |
| modulus `mod` | 2 to 2^32 - 1 |
| rank `K` | 1 to 5000000 |
| values generated | 5000000 |
| judge limit | 100 ms, 1536 MB |

Sample input:

```
2 3 100000007 23
```

Sample output:

```
434
```

## Idea

Sort five million values and the judge clock runs out. Count their high 16 bits instead, like sorting mail by postcode before sorting by house number. The first pass finds which postcode holds the answer. The second pass counts house numbers inside that postcode only.

The generator advances two linear congruential states with 32-bit wraparound. Each value is `((a << 16) + b) mod mod`. The solution stores the values once and builds a 65536-slot histogram of high halves. A cumulative scan locates the high half containing rank `K`. A second histogram over low halves finishes the job.

`nth_element` still compares values across the whole array several times. Sorting costs about 115 million comparisons. The histogram uses two linear passes and no comparisons between values.

The takeaway: split each value into two 16-bit digits and count, then recurse into one bucket.

## Why It Works

1. Every generated value is below `2^32`, so it has one high 16-bit digit and one low 16-bit digit.
2. Sorting by high digit first, then by low digit, equals sorting the whole 32-bit value.
3. The high histogram gives the number of values in each high bucket.
4. The cumulative count identifies one bucket whose range contains rank `K`.
5. Inside that bucket, the low histogram identifies the exact value at rank `K`.
6. Duplicates are counted in the same slot, so repeated values need no special case.

| term | meaning |
|---|---|
| `stateFirst` | first generator state, wrapped to 32 bits |
| `stateSecond` | second generator state, wrapped to 32 bits |
| `highCounts` | frequency of each high 16-bit digit |
| `lowCounts` | frequency of low digits inside the chosen bucket |
| `targetRank` | requested rank, counted from one |

Worked example with four values, using the same two-digit split:

| value | high digit | low digit |
|---|---|---|
| 5 | 0 | 5 |
| 261 | 0 | 261 |
| 7 | 0 | 7 |
| 260 | 1 | 4 |

For rank 3, the high histogram is `{0: 3, 1: 1}`. Bucket 0 holds ranks 1 through 3, so rank 3 becomes rank 3 inside that bucket. The low digits there are `5, 261, 7`, which sort to `5, 7, 261`. The answer is 7.

Nim's `uint32` arithmetic wraps on overflow, matching the C generator exactly.

## Code

**Input and scanner.** Four numbers are read from one input string.

```nim
const flushBlockBytes = 1 shl 17
const sequenceLength = 5000000
const histogramSize = 1 shl 16
const lowMask = 65535'u32

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

The constants match the statement's array size and 16-bit digit width.

**Buffered output.** One small result still goes through the shared buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

**Generation and high histogram.** States wrap and values are stored once.

```nim
let firstSeed = uint32(nextInt(inputData, scanPos))
let secondSeed = uint32(nextInt(inputData, scanPos))
let modulus = uint32(nextInt(inputData, scanPos))
let targetRank = nextInt(inputData, scanPos)

var generated = newSeq[uint32](sequenceLength)
var highCounts = newSeq[int32](histogramSize)
var stateFirst = firstSeed
var stateSecond = secondSeed
for valueIndex in 0 .. sequenceLength - 1:
  stateFirst = 31014'u32 * (stateFirst and 65535'u32) + (stateFirst shr 16)
  stateSecond = 17508'u32 * (stateSecond and 65535'u32) + (stateSecond shr 16)
  let generatedValue = ((stateFirst shl 16) + stateSecond) mod modulus
  generated[valueIndex] = generatedValue
  highCounts[int(generatedValue shr 16)] += 1
```

The low 16 bits of the shifted state survive the shift, exactly as in C.

**Bucket selection.** A cumulative scan finds one high digit.

```nim
var selectedHigh = 0
var seenBefore = 0
for highPart in 0 .. histogramSize - 1:
  let nextSeen = seenBefore + int(highCounts[highPart])
  if nextSeen >= targetRank:
    selectedHigh = highPart
    break
  seenBefore = nextSeen
let withinRank = targetRank - seenBefore
```

`withinRank` is relative to the chosen bucket.

**Low histogram and answer.** A second scan touches only the stored values.

```nim
var lowCounts = newSeq[int32](histogramSize)
for valueIndex in 0 .. sequenceLength - 1:
  let generatedValue = generated[valueIndex]
  if int(generatedValue shr 16) == selectedHigh:
    lowCounts[int(generatedValue and lowMask)] += 1

var selectedLow = 0
var lowSeen = 0
for lowPart in 0 .. histogramSize - 1:
  let nextSeen = lowSeen + int(lowCounts[lowPart])
  if nextSeen >= withinRank:
    selectedLow = lowPart
    break
  lowSeen = nextSeen

let answer = (uint32(selectedHigh) shl 16) + uint32(selectedLow)
appendOutput($int64(answer))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Joining the two digits reconstructs the full 32-bit value.

## Complexity

| phase | time | space |
|---|---|---|
| generation | 5000000 steps | 20 MB of values |
| high histogram | folded into generation | 256 KiB |
| high scan | at most 65536 steps | constant |
| low histogram | 5000000 checks | 256 KiB |
| low scan and output | at most 65536 steps | small buffer |

| measure | Big O |
|---|---|
| time | O(n + 2^16), with n = 5000000 |
| space | O(n) |
| comparisons between values | zero |

Full sorting costs O(n log n) comparisons and exceeds the 100 ms budget. Two digit counts finish in two linear passes.
