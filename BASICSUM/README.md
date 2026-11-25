# BASICSUM — Bas1c and the game of sum (SPOJ)

<https://www.spoj.com/problems/BASICSUM/>

## Problem

An array of `n` values repeats forever on a screen. Each question asks for the sum of `K` shown numbers starting at screen position `B`.

The first line gives `n` and `Q`. The second line holds the `n` array values. Each of the next `Q` lines holds two integers, `K` then `B`. Print one answer per question, in order. Positions start at 1, and `K` values are counted from that position across array boundaries.

| item | bound |
|---|---|
| array length `n` | 1 to 1000000 |
| questions `Q` | 1 to 1000000 |
| array value | 1 to 999999999 |
| span `K` | 1 to 1000000 |
| start `B` | 1 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

Every needed screen position lies below two million, so a bounded prefix table covers all questions.

Sample input:

```
5 2
4 2 6 1 7
3 2
3 9
```

Sample output:

```
9
12
```

The second question walks positions 9, 10, 11 and wraps into the array start.

## Idea

A circular running track lets a runner pass the start line and keep going; the repeating array behaves the same way. Build prefix sums over enough copies, then answer each question with one subtraction. The algorithm costs one table build plus O(1) per question. A naive scan adds `K` numbers for every question and repeats the same additions. Extend the array once, then subtract two prefix values.

## Why It Works

1. Screen position `p` shows array element `(p - 1) mod n`.
2. The largest position any question reads is `B + K - 1`.
3. Both `B` and `K` are at most one million, so that position stays under two million.
4. Prefix entry prefixSums[t] holds the total of the first `t` generated elements.
5. The sum from start `s` over `K` values is prefixSums[s + K] - prefixSums[s].

| term | meaning |
|---|---|
| `arrayLength` | number of values in one array copy |
| `queryStarts` | zero-based start position of each question |
| `copiesNeeded` | number of array copies required by the largest question |
| `prefixSums` | running total at each generated position |

The table holds one more slot than the largest position, so every end index is in range.

For the sample, `n` is 5 and the values are 4, 2, 6, 1, 7. The question `3 9` starts at zero-based position 8. Positions 8, 9, 10 map to array indexes 3, 4, 0. Those values are 1, 7, 4, and their sum is 12.

Sums reach at most one million times one billion, so `int64` holds every answer.

## Code

**Input and scanning.** The reader loads the array and all questions before any arithmetic.

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

Digits build each value directly from character codes.
The scanner skips spaces and line breaks.
One output string buffers every answer.

**Prefix build.** The code repeats the array only as far as the last question needs.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let arrayLength = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var baseNumbers = newSeq[int](arrayLength)
for arrayIndex in 0 .. arrayLength - 1:
  baseNumbers[arrayIndex] = nextInt(inputData, scanPos)
var querySpans = newSeq[int](queryCount)
var queryStarts = newSeq[int](queryCount)
var maxEndIndex = 0
for queryIndex in 0 .. queryCount - 1:
  querySpans[queryIndex] = nextInt(inputData, scanPos)
  queryStarts[queryIndex] = nextInt(inputData, scanPos) - 1
  let endIndex = queryStarts[queryIndex] + querySpans[queryIndex] - 1
  if endIndex > maxEndIndex:
    maxEndIndex = endIndex
let copiesNeeded = (maxEndIndex + 1 + arrayLength - 1) div arrayLength
let totalSlots = arrayLength * copiesNeeded
var prefixSums = newSeq[int64](totalSlots + 1)
for slotIndex in 0 .. totalSlots - 1:
  prefixSums[slotIndex + 1] = prefixSums[slotIndex] + int64(baseNumbers[slotIndex mod arrayLength])
```

Reading the questions first fixes the table size.
The `mod` operation maps a generated slot back to one array value.
Each prefix entry adds one value to the previous entry.

**Answer pass.** Each question becomes two table lookups and one line.

```nim
for queryIndex in 0 .. queryCount - 1:
  let startIndex = queryStarts[queryIndex]
  let endIndex = startIndex + querySpans[queryIndex] - 1
  let answerValue = prefixSums[endIndex + 1] - prefixSums[startIndex]
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The subtraction covers the whole span, including wrapped copies.
Buffered lines are written in blocks.
One final flush writes any remaining bytes.

## Complexity

Reading and table building dominate the work; each answer is constant time.

| phase | time | space |
|---|---|---|
| input read | one pass over the input string | input string and question arrays |
| prefix build | one pass over generated slots | prefix table |
| answer pass | two lookups per question | block output buffer |

| measure | Big O |
|---|---|
| time | O(n + Q + R), where R is the largest end position |
| space | O(n + Q + R) |

A naive answer loop adds `K` values per question and grows with `Q` times `K`.

The prefix table turns every question into one subtraction after a single build.
