# FUCT_IF_CHECKNUM — Check Number (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_CHECKNUM/>

## Problem

You receive several integers and label each one positive, negative, or zero.
The first input line gives the test count T. Each next line gives one integer n.
Print one result line per test using the sample wording. Every line but the last ends with one space.

| Item | Bound |
|---|---|
| Test cases | 1 to 1000 |
| Value n | -1000000 to 1000000 |
| Time limit | 1000 ms |
| Memory | 1536 MB |

The 1000-case cap keeps the whole program linear.

Sample input:

```
5
-7
9
0
4
-3
```

Sample output:

```
-7 is negative number 
9 is positive number 
n is zero 
4 is positive number 
-3 is negative number
```

The sample fixes the exact byte shape, including its spaces and line breaks.

## Idea

Think of a clerk stamping each number with one of three labels.
The program reads all input into one string and scans digits by index.
It appends the wording and the original digits into one output buffer.
Blocks of 128 KiB go to standard output, so each test needs no write call.

One scan and one buffer handle every case.

## Why It Works

1. The scanner skips whitespace and keeps a leading minus sign.
2. Zero takes the fixed zero message without an integer write.
3. A positive or negative value is written as digits with its sign.
4. A trailing space is added until the final answer line.

| Term | Meaning |
|---|---|
| `inputData` | one string holding all input bytes |
| `scanPos` | index of the next unread byte |
| `appendInteger` | writes nonnegative digits into the buffer |
| `flushBlockBytes` | 131072 bytes per output block |

The sign test and the digit write both cost constant time.

Script-generated trace from `gen.py`:

```
-7 negative
9 positive
0 zero
```

The trace follows the sample order and shows the three labels.

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
`nextNumber` skips whitespace by index.
No token string is allocated.

**Output helpers.** This block buffers text and writes integer digits directly.

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
```

`appendInteger` stores digits backward, then emits them forward.
`flushIfReady` writes at 131072 bytes.
`appendOutput` adds literal text.

**Answer loop.** This block selects the wording for each signed value.

```nim
let testCount = nextNumber(inputData, scanPos)
for caseIndex in 0..<testCount:
  let number = nextNumber(inputData, scanPos)
  if number == 0:
    appendOutput("n is zero")
  elif number > 0:
    appendInteger(number)
    appendOutput(" is positive number")
  else:
    appendOutput("-")
    appendInteger(-number)
    appendOutput(" is negative number")
  if caseIndex < testCount - 1:
    appendOutput(" ")
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly T times.
Zero skips the digit writer.
The final flush clears the partial block.

## Complexity

Cost follows the number of input bytes and printed digits.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sign handling | one comparison per case | none |
| Output | one write per 128 KiB block | block buffer |

All three phases grow with the size of the input and output text.

| Measure | Big O |
|---|---|
| Time | O(I + D) |
| Space | O(I + B) |

Writing each answer directly calls the stream once per line, while block flushing amortizes that cost.
