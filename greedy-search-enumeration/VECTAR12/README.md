# VECTAR12 — Garden of Mangu (SPOJ)

<https://www.spoj.com/problems/VECTAR12/>

## Problem

Count walks of exactly `n` king moves from `(0,0)` to `(n,k)` that never leave the non-negative quadrant. Report the count modulo 1000000007.

Input starts with `T`, followed by `T` lines with `n` and `k`. Both coordinates are non-negative and k ≤ n. Output one count per query.

| Item | Bound |
|---|---|
| Queries T | fewer than 100000 |
| Steps n | 0 to 6999 |
| Target height k | 0 to n |
| Judge limit | 1000 ms, 1536 MB |

Many queries share the same step count, so one shared precomputation serves them all.

The sample asks for two short walks:

```
2
1 1
2 0
```

The expected output is:

```
1
2
```

The first walk is one diagonal step; the second has two level-and-diagonal variants.

## Idea

The x-coordinate must rise by one on every step, like climbing one stair per move to reach step `n` in `n` moves. That leaves three choices per move: go up, stay, or go down in y. Count non-negative walks with those three moves, and reuse one growing table for all queries. A fresh walk enumeration per query would be exponential.

## Why It Works

1. A king move changes x by at most one, and x must gain `n` in `n` moves.
2. Therefore every step has x-delta equal to one.
3. The y-delta is then one of `-1`, `0`, or `1`.
4. A walk stays legal when the running y never drops below zero.
5. Let `dp[t][h]` be the count after `t` moves at height `h`.
6. Then `dp[t][h] = dp[t-1][h-1] + dp[t-1][h] + dp[t-1][h+1]`, with negative heights skipped.

| Term | Meaning |
|---|---|
| `querySteps` | step count n for one query |
| `queryHeights` | target height k for one query |
| `previousHeights` | counts after the current step count |
| `bucketHeads` | linked lists of queries grouped by step count |

The table names the structures that drive the sweep.

A script-traced run on the sample:

```
t=0: heights  [1]
t=1: heights  [1, 1]        answer for (1,1) is 1
t=2: heights  [2, 2, 1]     answer for (2,0) is 2
```

The two answers match the sample output.

## Code

**Input and query buckets.** The hand reader loads all pairs and groups them by step count.

```nim
const flushBlockBytes = 1 shl 17
const pathModulus: int64 = 1000000007

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

The scanner ignores whitespace and line breaks.
Buckets avoid sorting up to 100000 queries.
Each query appears in exactly one bucket.

**Bucket setup.** Linked lists hold queries at the step where they are answered.

```nim
let queryCount = nextInt(inputData, scanPos)
var querySteps = newSeq[int](queryCount)
var queryHeights = newSeq[int](queryCount)
var nextInBucket = newSeq[int](queryCount)
var maxSteps = 0
for queryIndex in 0 .. queryCount - 1:
  querySteps[queryIndex] = nextInt(inputData, scanPos)
  queryHeights[queryIndex] = nextInt(inputData, scanPos)
  if querySteps[queryIndex] > maxSteps:
    maxSteps = querySteps[queryIndex]

var bucketHeads = newSeq[int](maxSteps + 1)
for stepIndex in 0 .. maxSteps:
  bucketHeads[stepIndex] = -1
for queryIndex in 0 .. queryCount - 1:
  let stepIndex = querySteps[queryIndex]
  nextInBucket[queryIndex] = bucketHeads[stepIndex]
  bucketHeads[stepIndex] = queryIndex
```

The largest step sets the sweep length.
Each bucket head stores one query index.
The next link chains the rest of that bucket.

**Height sweep.** Two arrays hold the current and previous height counts.

```nim
var answers = newSeq[int](queryCount)
var previousHeights = newSeq[int64](maxSteps + 2)
var currentHeights = newSeq[int64](maxSteps + 2)
previousHeights[0] = 1

var cursor = bucketHeads[0]
while cursor >= 0:
  answers[cursor] = int(previousHeights[queryHeights[cursor]])
  cursor = nextInBucket[cursor]

var stepIndex = 1
while stepIndex <= maxSteps:
  for heightIndex in 0 .. stepIndex:
    var pathTotal = previousHeights[heightIndex]
    if heightIndex > 0:
      pathTotal = pathTotal + previousHeights[heightIndex - 1]
    if heightIndex + 1 < stepIndex:
      pathTotal = pathTotal + previousHeights[heightIndex + 1]
    currentHeights[heightIndex] = pathTotal mod pathModulus
  swap previousHeights, currentHeights
  cursor = bucketHeads[stepIndex]
  while cursor >= 0:
    answers[cursor] = int(previousHeights[queryHeights[cursor]])
    cursor = nextInBucket[cursor]
  stepIndex += 1

for queryIndex in 0 .. queryCount - 1:
  appendOutput($answers[queryIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Step zero has one walk at height zero.
The guard `heightIndex + 1 < stepIndex` blocks negative-height moves.
Answers land in input order, so output needs no sorting.

## Complexity

The sweep runs once up to the largest requested step count.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all query pairs | one input string |
| Height sweep | one pass over a triangle of heights | two height arrays |
| Output | one line per query | block buffer |

Work depends on the largest step, not on the query count alone.

| Measure | Big O |
|---|---|
| Time | O(max n squared + T) |
| Space | O(max n + T) |

Enumerating all walks would grow exponentially, so the shared height sweep wins.
