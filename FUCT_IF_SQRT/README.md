# FUCT_IF_SQRT — Square Root (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_SQRT/>

## Problem

You receive integers and print each square root rounded to six decimal places.
The first input line gives the test count T. Each next line gives one number n.
A negative n prints invalid. A perfect square prints an integer with no decimal point.
Other roots print six decimals with trailing zeros removed. The sample prints zero as `0 ` with a space.

| Item | Bound |
|---|---|
| Test cases | 1 to 1000 |
| Value n | 0 to 1000000; sample includes negatives |
| Time limit | 1000 ms |
| Memory | 1536 MB |

The small value range lets one integer search cover every test.

Sample input:

```
7
4
7
0
2
-9
1
-3
```

Sample output:

```
2
2.645751
0 
1.414214
invalid
1
invalid
```

The sample fixes the exact byte shape, including its spaces and line breaks.

## Idea

Binary search for a root is like guessing a page number and halving the range each time.
The program scales n by one million squared, then finds the largest integer root.
A half-step comparison decides whether to round that root upward.
Fraction digits are trimmed, and one output buffer collects the lines.

An exact integer search replaces floating formatting.

## Why It Works

1. Multiplying n by 1000000000 squared moves six decimal places into an integer.
2. The search finds the largest root whose square stays within the target.
3. Comparing the half-step square with the target decides the rounding.
4. Trimming trailing zeros leaves the shortest correct answer.

| Term | Meaning |
|---|---|
| `target` | n scaled up by one million squared |
| `root` | largest integer square root of the target |
| `scaledValue` | root after rounding to six decimals |
| `appendFraction` | writes and trims fraction digits |

Each term stays inside signed 64-bit range for the stated bound.

Script-generated trace from `gen.py`:

```
4 2
7 2.645751
0 0
2 1.414214
```

The trace shows perfect squares, rounded roots, and the zero case.

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
`nextNumber` keeps the minus sign.
Whitespace is skipped by index.

**Output helpers and integer root search.** This block buffers output and finds a root by binary search.

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
proc appendFraction(fraction: int) =
  var digitStore: array[6, char]
  var remaining = fraction
  for index in countdown(5, 0):
    digitStore[index] = char(remaining mod 10 + firstDigitValue)
    remaining = remaining div 10
  var digitCount = 6
  while digitCount > 0 and digitStore[digitCount - 1] == '0':
    digitCount -= 1
  if digitCount > 0:
    outputBuffer.add '.'
    for index in 0..<digitCount:
      outputBuffer.add digitStore[index]
  flushIfReady()

proc appendDecimal(scaledValue: int) =
  appendInteger(scaledValue div 1000000)
  appendFraction(scaledValue mod 1000000)
proc integerSquareRoot(target: int): int =
  var low = 0
  var high = 1000000000
  while low < high:
    let middle = (low + high + 1) div 2
    if middle <= target div middle:
      low = middle
    else:
      high = middle - 1
  return low
```

`integerSquareRoot` runs at most 30 steps.
`appendFraction` removes trailing zeros.
`appendDecimal` splits at six digits.

**Answer loop.** This block handles negatives, zero, and positive values.

```nim
let testCount = nextNumber(inputData, scanPos)
for caseIndex in 0..<testCount:
  let number = nextNumber(inputData, scanPos)
  if number < 0:
    appendOutput("invalid")
  elif number == 0:
    appendOutput("0 ")
  else:
    let target = number * 1000000 * 1000000
    let root = integerSquareRoot(target)
    var scaledValue = root
    if 4 * root * root + 4 * root + 1 <= 4 * target:
      scaledValue += 1
    appendDecimal(scaledValue)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly T times.
Zero keeps its sample trailing space.
The final flush clears the partial block.

## Complexity

Cost follows the number of input bytes and printed digits.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Root search | about 30 steps per case | none |
| Output | one write per 128 KiB block | block buffer |

The search cost stays flat because the value range is fixed.

| Measure | Big O |
|---|---|
| Time | O(T log R), R = 1000000000 |
| Space | O(I + B) |

A formatted floating print builds a string per case, while the integer path emits digits directly.
