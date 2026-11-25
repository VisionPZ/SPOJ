# MULTIPLY — Fast Multiplication Again (SPOJ)

<https://www.spoj.com/problems/MULTIPLY/>

## Problem

Multiply two integers and print the product. The limit is tight, so even input and output must stay lean.

Read two positive integers per pair and print their product on its own line. The judge supplies one pair per run. Stress data can hold several pairs.

The product stays below 10000.

The bounds and judge limits:

| Quantity | Bound |
| --- | --- |
| Input | two positive integers per pair |
| Product | less than 10000 |
| Time limit | 200 ms |
| Memory limit | 1536 MB |

The small product keeps every value inside a 64-bit integer, so the design focuses on I/O speed.

The sample case:

```
1
2
```

```
2
```

## Idea

Read the whole input once, parse digits by hand, then multiply each pair in one operation.

Think of a cashier who reads each price tag once and totals the bill without extra steps. A hand scanner builds each integer from its digits. One growable output buffer flushes in 256 KiB blocks instead of writing per answer.

Each pair costs one digit parse per number and one multiplication. Repeated addition costs O(firstValue) per pair, and per-number stream writes dominate a 200 ms limit. One bulk read and one buffered write remove both costs.

## Why It Works

Five facts prove the program correct and fast.

1. A digit scan builds a value left to right with `value = value * 10 + digit`. Each step shifts the running value by ten and adds the next digit, so the digits rebuild the integer exactly.
2. The scanner skips line feeds and spaces, so one-line and two-line layouts parse the same way.
3. The `i >= inputData.len` guard stops a stray zero after trailing whitespace. A missing second number ends the loop cleanly.
4. One buffer accumulates every answer and flushes at `flushBlockBytes`, so writes stay infrequent.
5. The oracle uses doubling and halving instead of multiplying. It gives 9999 for `101 * 99`, which confirms the product bound.

The values and their roles:

| Term | Meaning |
| --- | --- |
| `inputData` | one string holding the whole input |
| `nextInt` | hand scanner building an int64 from digits |
| `outputBuffer` | one growable buffer for all answers |
| `appendOutput` | appends text and flushes at the block size |
| `firstDigitValue` | character code of digit zero |
| `flushBlockBytes` | 256 KiB flush threshold |

These six names cover the entire program state.

A script traces the oracle on `101 * 99`:

```
start: left=101 right=99 total=0
1 odd  99: total=101  left=202   right=49
2 odd  49: total=303  left=404   right=24
3 even 24: total=303  left=808   right=12
4 even 12: total=303  left=1616  right=6
5 even  6: total=303  left=3232  right=3
6 odd   3: total=3535 left=6464  right=1
7 odd   1: total=9999 left=12928 right=0
```

Both methods give 9999, which stays below the stated bound.

## Code

**Setup and scanner.** One read loads the stream, and a hand scanner parses digits.

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

**Buffered output.** One string holds pending answers and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) {.inline.} =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 256 KiB and reuses its memory. Each flush costs one write call. No string is allocated per pair.

**Pair loop.** Consecutive numbers form pairs, and one multiplication gives each answer.

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

The loop advances `i` through the buffer. The guard prevents a stray zero after trailing whitespace. The final flush emits the remaining bytes.

## Complexity

Input and output dominate a case that holds only one multiplication.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(N) | one input buffer |
| Digit scan | O(N) | O(1) extra |
| Multiplication | O(1) per pair | O(1) |
| Output flush | O(N) | one output block |

Here `N` counts input or output bytes.

| Measure | Big O |
| --- | --- |
| Time | O(N) |
| Space | O(N) for the two buffers, O(1) working space |

Repeated addition costs O(firstValue) per pair, which is slower for larger operands.
