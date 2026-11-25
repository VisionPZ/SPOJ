# MOWGLI — Time for Revenge (SPOJ)

<https://www.spoj.com/problems/MOWGLI/>

## Problem

A river holds A stones one metre apart, and Mowgli jumps from the near bank to the far bank. Each jump skips at most K stones, so it advances at most K + 1 stone positions. Report the number of distinct crossings for each river, modulo 1000000007.

The input starts with the test count T. Each test gives the river count N and the skip limit K, followed by N stone counts A. Print one line per river, in input order.

| item | bound |
|---|---|
| tests T | at most 10 |
| rivers N per test | 1 to 100 |
| skip limit K | 0 to 50 |
| stones A | 0 to 100000 |
| judge limit | 1000 ms, 1536 MB |

Stone counts and skip limits stay inside these bounds.

Sample input:

```
1
2 1
1 2
```

Sample output:

```
2
3
```

The two lines answer the two rivers in that test.

## Idea

Treat the far bank as one extra stone, like counting stair climbs with strides of at most K + 1 steps. A crossing becomes a composition of A + 1 whose parts are legal jump lengths. A sliding-window DP evaluates the part-sum recurrence in constant time per value. Listing every composition would grow exponentially with A, so the DP replaces enumeration. Compute each distinct skip limit once and reuse its table for all rivers.

## Why It Works

1. Positions run from 0 at the near bank to A + 1 at the far bank.
2. A jump of length L skips L - 1 stones, so L stays between 1 and K + 1.
3. A crossing is an ordered composition of A + 1 with parts in that range.
4. Let ways[n] count those compositions. The last part has L choices, so ways[n] is the sum of ways[n - L].
5. A sliding window holds that sum and drops the part leaving the range.

| term | meaning |
|---|---|
| `skipLimits` | stored skip limit for each river |
| `maxSkip` | skip limit read from the current test |
| `stoneCounts` | stored stone count for each river |
| `ways` | composition counts for one skip limit |
| `windowTotal` | running sum of the last K + 1 counts |
| `answers` | final count for each river |

The table below expands the second sample river, where K = 1 and A = 2.

| quantity | value |
|---|---|
| parts allowed | 1, 2 |
| target A + 1 | 3 |
| compositions | 1+1+1, 1+2, 2+1 |
| answer | 3 |

All three compositions match the three choices in the statement.

## Code

**Input and scanner.** One pass loads the tests, and the hand reader walks the buffer.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const maxSkipAllowed = 50

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

Each river is stored as a skip limit plus a stone count.
The maximum stone count fixes every table length.
The scanner ignores spaces and line breaks.

**Sliding-window DP and buffered output.** Each distinct skip limit gets one table.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
var skipLimits = newSeq[int]()
var stoneCounts = newSeq[int]()
var maxStoneCount = 0
for testIndex in 0 .. testCount - 1:
  let riverCount = nextInt(inputData, scanPos)
  let maxSkip = nextInt(inputData, scanPos)
  for riverIndex in 0 .. riverCount - 1:
    let stoneCount = nextInt(inputData, scanPos)
    skipLimits.add maxSkip
    stoneCounts.add stoneCount
    if stoneCount > maxStoneCount:
      maxStoneCount = stoneCount

var skipSeen = newSeq[bool](maxSkipAllowed + 1)
for queryIndex in 0 .. skipLimits.len - 1:
  skipSeen[skipLimits[queryIndex]] = true

var answers = newSeq[int](stoneCounts.len)
for skipValue in 0 .. maxSkipAllowed:
  if not skipSeen[skipValue]:
    continue
  var ways = newSeq[int](maxStoneCount + 2)
  ways[0] = 1
  var windowTotal: int64 = 1
  for totalStones in 1 .. maxStoneCount + 1:
    ways[totalStones] = int(windowTotal mod int64(answerModulus))
    windowTotal += int64(ways[totalStones])
    let dropIndex = totalStones - (skipValue + 1)
    if dropIndex >= 0:
      windowTotal -= int64(ways[dropIndex])
  for queryIndex in 0 .. skipLimits.len - 1:
    if skipLimits[queryIndex] == skipValue:
      answers[queryIndex] = ways[stoneCounts[queryIndex] + 1]

for answerIndex in 0 .. answers.len - 1:
  appendOutput($answers[answerIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The window adds one new count and drops the oldest one.
The modulus keeps every stored count in range.
Buffered writes emit one answer per river.

## Complexity

The DP is shared across rivers with the same skip limit.

| phase | time | space |
|---|---|---|
| input read | one pass over all rivers | two lists of rivers |
| DP precompute | one step per value per distinct skip | one table of counts |
| output | one line per river | block buffer |

At most 51 distinct skip limits exist.

| measure | Big O |
|---|---|
| time | O(D times maxA + R) |
| space | O(maxA + R) |

Here D counts distinct skip limits and R counts all rivers.

Listing each composition would take exponential time and never finish for large A.
The DP and the shared tables keep the work bounded by the input size.
