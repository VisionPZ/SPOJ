# FUCT_IF_DIVIDE — Divide (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_DIVIDE/>

## Problem

You receive pairs m and n and print the quotient m divided by n.
The first input line gives the test count T. Each next line gives m and n separated by a space.
A zero denominator prints the fixed error message. Other answers print six decimals, rounded and trimmed.
An integer answer prints no decimal point.

| Item | Bound |
|---|---|
| Test cases | 1 to 1000 |
| Operands | not bounded in the statement |
| Time limit | 1000 ms |
| Memory | 1536 MB |

One integer division per case keeps the work linear.

Sample input:

```
7
5 2
-15 -5
8 4
50 0
7 3
-6 2
18 -3
```

Sample output:

```
2.5
3
2
denominator cannot be zero
2.333333
-3
-6
```

The sample fixes the exact byte shape, including its spaces and line breaks.

## Idea

Scaling by one million is like measuring a length in millionths, then shortening the label.
The program takes absolute values, scales the numerator, and rounds with half the denominator.
It applies the sign after computing the magnitude.
One output buffer writes the digits and trims the fraction.

Exact integer arithmetic removes floating format differences.

## Why It Works

1. Absolute values make the division and the rounding straightforward.
2. Adding half the denominator rounds the scaled quotient to the nearest value.
3. The sign is applied after magnitude, so -15 divided by -5 prints 3.
4. Fraction digits are trimmed after the decimal point.

| Term | Meaning |
|---|---|
| `absoluteNumerator` | magnitude of the numerator |
| `absoluteDenominator` | magnitude of the denominator |
| `scaledValue` | quotient multiplied by one million |
| `appendFraction` | writes and trims fraction digits |

The scaled product stays inside signed 64-bit range for int-sized operands.

Script-generated trace from `gen.py`:

```
5 2 2.5
7 3 2.333333
-15 -5 3
50 0 denominator cannot be zero
```

The trace matches the sample and shows the zero-denominator case.

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

**Output helpers.** This block buffers output, writes digits, and trims fractions.

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
```

`appendInteger` writes integer digits.
`appendFraction` trims zero digits.
`flushIfReady` caps memory at 128 KiB.

**Answer loop.** This block handles zero denominators and signs.

```nim
let testCount = nextNumber(inputData, scanPos)
for caseIndex in 0..<testCount:
  let numerator = nextNumber(inputData, scanPos)
  let denominator = nextNumber(inputData, scanPos)
  if denominator == 0:
    appendOutput("denominator cannot be zero")
  else:
    var negativeResult = (numerator < 0) != (denominator < 0)
    var absoluteNumerator = numerator
    if absoluteNumerator < 0:
      absoluteNumerator = -absoluteNumerator
    var absoluteDenominator = denominator
    if absoluteDenominator < 0:
      absoluteDenominator = -absoluteDenominator
    let scaledValue = (absoluteNumerator * 1000000 + absoluteDenominator div 2) div absoluteDenominator
    if negativeResult and scaledValue > 0:
      appendOutput("-")
    appendDecimal(scaledValue)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly T times.
The sign is applied after magnitude.
The final flush clears the partial block.

## Complexity

Cost follows the number of input bytes and printed digits.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Division | one integer division per case | none |
| Output | one write per 128 KiB block | block buffer |

The division dominates the arithmetic work, and it costs one operation.

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(I + B) |

Decimal string formatting allocates per case, while the integer path emits digits into one buffer.
