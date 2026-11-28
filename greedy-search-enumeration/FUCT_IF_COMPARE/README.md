# FUCT_IF_COMPARE — Compare Two Numbers (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_COMPARE/>

## Problem

You receive pairs of integers and report which value is larger.
The first input line gives the test count T. Each next line holds two integers separated by a space.
A larger first value prints `is greater than`. A smaller first value prints `is smaller than`.
Equal values print `n is equal m:` followed by the shared value.

| Item | Bound |
|---|---|
| Test cases | 1 to 1000 |
| Values | not bounded in the statement |
| Time limit | 1000 ms |
| Memory | 1536 MB |

A three-way comparison settles each case immediately.

Sample input:

```
5
9 2
-3 -5
5 28
0 0
19 13
```

Sample output:

```
9 is greater than 2
-3 is greater than -5
5 is smaller than 28
n is equal m: 0
19 is greater than 13
```

The sample fixes the exact byte shape, including its spaces and line breaks.

## Idea

It works like a referee comparing two scorecards and naming the higher score.
The program scans both integers, then takes one of three branches.
A signed digit writer handles negative values without string conversion.
All answer text accumulates in one buffer with block flushes.

One comparison and one buffered write handle each pair.

## Why It Works

1. The scanner keeps a leading minus sign for each value.
2. The greater, smaller, and equal branches cover every possible pair.
3. `appendSignedInteger` writes the minus sign before the digits.
4. The equal branch prints the first value after the fixed wording.

| Term | Meaning |
|---|---|
| `firstValue` | the left number in a pair |
| `secondValue` | the right number in a pair |
| `appendSignedInteger` | writes a signed decimal value |
| `outputBuffer` | one growing block of answer text |

Each term maps directly to one line of the answer loop.

Script-generated trace from `gen.py`:

```
9 2 1
5 28 -1
0 0 0
```

The trace records the comparison result for three sample pairs.

## Code

**Input scanner.** This block reads stdin once and parses signed integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value
```

The read loop ends at end of input.
`nextNumber` keeps each minus sign.
Whitespace is skipped by index.

**Output helpers.** This block buffers text and writes signed integer digits.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

proc appendInteger(value: int) =
  if value == 0:
    outputBuffer.add '0'
    flushIfReady()
    return
  var digitStore: array[20, char]
  var digitCount = 0
  var remaining = value
  while remaining > 0:
    digitStore[digitCount] = char(remaining mod 10 + firstDigitValue)
    digitCount += 1
    remaining = remaining div 10
  for index in countdown(digitCount - 1, 0):
    outputBuffer.add digitStore[index]
  flushIfReady()

proc appendSignedInteger(value: int) =
  if value < 0:
    outputBuffer.add '-'
    appendInteger(-value)
  else:
    appendInteger(value)
```

`appendSignedInteger` writes a minus then digits.
`appendInteger` handles the magnitude.
`flushIfReady` caps memory at 128 KiB.

**Answer loop.** This block chooses one of three result wordings per pair.

```nim
let testCount = nextNumber(inputData, scanPos)
for caseIndex in 0..<testCount:
  let firstValue = nextNumber(inputData, scanPos)
  let secondValue = nextNumber(inputData, scanPos)
  if firstValue > secondValue:
    appendSignedInteger(firstValue)
    appendOutput(" is greater than ")
    appendSignedInteger(secondValue)
  elif firstValue < secondValue:
    appendSignedInteger(firstValue)
    appendOutput(" is smaller than ")
    appendSignedInteger(secondValue)
  else:
    appendOutput("n is equal m: ")
    appendSignedInteger(firstValue)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly T times.
Equality uses the first value.
The final flush clears the partial block.

## Complexity

Cost follows the number of input bytes and printed digits.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Comparison | one three-way branch per case | none |
| Output | one write per 128 KiB block | block buffer |

No phase looks at any case more than once.

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(I + B) |

Writing each result line directly calls the stream once per case, while block flushing batches those calls.
