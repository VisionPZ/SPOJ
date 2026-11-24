## Problem

Read two positive integers from input and print their product, followed by a line feed. The product is smaller than 10000, so both operands are small. One pair is supplied per run, and the scanner also handles stress data that holds several pairs.

| Quantity | Bound |
| --- | --- |
| Input | two positive integers per pair |
| Product | less than 10000 |
| Time limit | 200 ms |
| Memory limit | 1536 MB |

The small product bound keeps every value inside a 64-bit integer, so the design focuses on input and output speed.

## Idea

Read the whole input once, parse digits with a hand scanner, then multiply each pair with one multiplication. This skips stream layers and per-number writes, which would dominate a 200 ms limit. Cost per pair: one digit parse for each number and one multiplication.

## Why It Works

A digit scan builds a value left to right with `value = value * 10 + int64(int(data[position]) - firstDigitValue)`. Each step multiplies the running value by ten and adds the new digit, so the digits rebuild the integer exactly. The scanner skips line feeds and spaces, so one-line and two-line layouts parse the same way. The final loop pairs consecutive numbers and prints one product per line.

The oracle doubles and halves instead of multiplying, which gives an independent check. The table traces the largest legal product, and `gen.py` confirms the final total.

| Step | left | right | total |
| --- | --- | --- | --- |
| start | 101 | 99 | 0 |
| 1 | 202 | 49 | 101 |
| 2 | 404 | 24 | 303 |
| 3 | 808 | 12 | 303 |
| 4 | 1616 | 6 | 303 |
| 5 | 3232 | 3 | 303 |
| 6 | 6464 | 1 | 3535 |
| 7 | 12928 | 0 | 9999 |

Both methods give 9999, which stays below the stated bound.

## Code

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, position: var int): int64 {.inline.} =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(int(data[position]) - firstDigitValue)
    position += 1
  return value
```

The read loop runs once per input line and stops at end of file. The scanner skips separators before each number, which avoids blank-line bugs. Parsing costs O(N) over N input bytes.

```nim
var outputBuffer = ""

proc appendOutput(text: string) {.inline.} =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One buffer holds all pending output and flushes at 256 KiB. The buffer is reused, so no new string is allocated per pair. Each flush costs one write call.

```nim
while i < inputData.len:
  let firstValue = nextInt(inputData, i)
  if i >= inputData.len: break
  let secondValue = nextInt(inputData, i)
  appendOutput($(firstValue * secondValue))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop advances `i` through the buffer and stops when a second number is missing. The guard prevents a stray zero after trailing whitespace. The final flush emits the remaining bytes.

## Complexity

Reading costs O(N) time for N input bytes, and scanning also costs O(N). Multiplication costs O(1) per pair, and writing costs O(N) for N output bytes. Total time is O(N), total space is O(N) for the two buffers, and working space is O(1). Repeated addition would cost O(firstValue) per pair, which is slower for larger operands.
