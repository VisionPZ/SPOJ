# FUCT_FOR_FNPN — First N Positive Number (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_FNPN/>

## Problem

Print the first N positive numbers on one line, separated by spaces.
A non-positive N produces the word invalid instead.

The first input line is the test count T, with T at most 1000.
Each following line holds one N, with N at most 1000000.
Print one answer line per test.

| Item | Bound |
|---|---|
| Test count T | 1 to 1000 |
| Value N | up to 1000000 |
| Judge limit | 1000 ms |

Output size, not input size, drives the runtime.

Sample input:

```
4
5
8
1
0
```

Sample output:

```
1 2 3 4 5
1 2 3 4 5 6 7 8
1
invalid
```

## Idea

Picture writing a numbered guest list from one upward.

Keep one output buffer and append each number as raw digits.
Write a space before every value after the first.
Flush the buffer to standard output every 128 KiB.

Direct digit writes avoid one formatted string allocation per printed value.

## Why It Works

1. A leading space appears before values two through N, never after value one.
2. Filling digits backward yields the correct order when written in reverse.
3. Each value has at most seven digits at the upper bound.
4. Block flushes keep peak memory fixed while output grows large.

| Term | Meaning |
|---|---|
| `appendInteger` | writes one decimal value into the output buffer |
| `digitStore` | twelve-slot scratch array for reversed digits |
| `flushBlockBytes` | threshold of 131072 bytes |

The buffer sends bytes out in bounded pieces, so output size does not inflate memory.

Script-generated example from `gen.py`:

```
1 1
5 1 2 3 4 5
0 invalid
```

The trace follows the sample order and marks zero as invalid.

## Code

**Scanner.** This block reads all input and parses signed integers by index.

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

Whitespace is skipped before each number.
A leading minus sign is kept for invalid case detection.
The scanner never allocates a token string.

**Output helpers.** This block buffers text and writes integers digit by digit.

```nim
var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendInteger(value: int) =
  var digitStore: array[12, char]
  var digitCount = 0
  var remaining = value
  while remaining > 0:
    digitStore[digitCount] = char(remaining mod 10 + firstDigitValue)
    digitCount += 1
    remaining = remaining div 10
  for index in countdown(digitCount - 1, 0):
    outputBuffer.add digitStore[index]
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendInteger` stores digits in reverse order first.
`countdown` then emits them most significant first.
Both procedures flush at the same block threshold.

**Answer loop.** This block produces the list or the invalid word per test.

```nim
let testCount = nextNumber(inputData, scanPos)
for caseIndex in 0..<testCount:
  let upperBound = nextNumber(inputData, scanPos)
  if upperBound <= 0:
    appendOutput("invalid\n")
  else:
    for value in 1..upperBound:
      if value > 1:
        appendOutput(" ")
      appendInteger(value)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Non-positive values take the invalid branch.
The inner loop runs exactly N times for valid values.
A final flush clears the last partial block.

## Complexity

Cost follows the number of digits printed, not the number of tests alone.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Digit writing | one pass over printed digits | scratch digits |
| Output | one write per 128 KiB block | block buffer |

Peak memory stays bounded even for large output files.

| Measure | Big O |
|---|---|
| Time | O(I + D) |
| Space | O(I + B) |

Formatting each value into its own string allocates once per printed number.
