# AMZSEQ — AMZ Word (SPOJ)

<https://www.spoj.com/problems/AMZSEQ/>

## Problem

Count words of length N over the digits 0, 1, 2 where each neighbouring pair differs by at most one. The input holds one positive integer N, and the output holds one count.

| item | bound |
|---|---|
| word length N | positive integer with answer below 1000000000 |
| judge limit | 100 ms, 1536 MB |

The answer bound keeps N at most 15, since the count passes one billion at N = 16.

Sample input:

```
2
```

Sample output:

```
7
```

## Idea

Track counts by the last digit, like tallying passengers at three exits. A word ending in 0 can follow 0 or 1, so that count is the sum of two previous counts. The middle digit can follow all three digits.

The recurrence updates three numbers per position and costs constant work per letter. Enumerating all three-to-the-N words wastes enormous effort.

Stop after N steps and add the three counts.

## Why It Works

1. A word ending in 0 extends a shorter word ending in 0 or 1.
2. A word ending in 1 extends a shorter word ending in 0, 1, or 2.
3. A word ending in 2 extends a shorter word ending in 1 or 2.
4. Every valid word has exactly one last digit, so the three groups are disjoint.
5. Adding the three groups gives the required total.

| term | meaning |
|---|---|
| `endingZero` | valid words whose last digit is 0 |
| `endingOne` | valid words whose last digit is 1 |
| `endingTwo` | valid words whose last digit is 2 |
| `wordLength` | the requested word length N |

The three buckets partition every valid word by its final digit.

A script-generated trace for N = 3 gives the following counts.

| length | ending in 0 | ending in 1 | ending in 2 | total |
|---|---|---|---|---|
| 1 | 1 | 1 | 1 | 3 |
| 2 | 2 | 3 | 2 | 7 |
| 3 | 5 | 7 | 5 | 17 |

The row for length 3 sums to 17, matching the same recurrence the program uses.

## Code

**Input and scanning.** The hand reader loads the single length value.

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

The scanner skips whitespace and reads digits one at a time.
It needs no sign branch because the input length is positive.
The whole input is read once before any counting starts.

**Counting and output.** Three running totals are updated once per position.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let wordLength = nextInt(inputData, scanPos)
var endingZero: int64 = 1
var endingOne: int64 = 1
var endingTwo: int64 = 1
if wordLength <= 0:
  appendOutput("1")
else:
  var position = 1
  while position < wordLength:
    let nextZero = endingZero + endingOne
    let nextOne = endingZero + endingOne + endingTwo
    let nextTwo = endingOne + endingTwo
    endingZero = nextZero
    endingOne = nextOne
    endingTwo = nextTwo
    position += 1
  appendOutput($(endingZero + endingOne + endingTwo))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs N minus one times with three additions per turn.
Sixty-four-bit intermediates keep every sum safe.
The single answer is written once through the block buffer.

## Complexity

Each position updates three counters, and the input holds one number.

| phase | time | space |
|---|---|---|
| input read | one pass over the input string | one input string |
| counting | one update per position | three counters |
| output | one line | block buffer |

The phases scale linearly with the requested length.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(1) beyond the input string |

Enumerating all words costs O(3^N), while the recurrence costs O(N).
