# G11_4 — Digits Count (SPOJ)

<https://www.spoj.com/problems/G11_4/>

## Problem

Diana writes every integer from A through B in base 10 without leading zeros.
Count how many times each digit appears across that whole list.

Each test case is one line with two integers A and B, where 1 is at most A,
A is at most B, and B is at most 100000000.
A line with two zeros ends the input.
Print ten counts on one line, for digits 0 through 9 in order.

| Item | Bound |
|---|---|
| Endpoints | 1 to 100000000 |
| Test cases | until the 0 0 line |
| Judge limit | 1000 ms |

Counting every written integer cannot work near the upper endpoint.

Sample input:

```
1 9
12 321
5987 6123
12345678 12345679
0 0
```

Sample output:

```
0 1 1 1 1 1 1 1 1 1
61 169 163 83 61 61 61 61 61 61
134 58 28 24 23 36 147 24 27 47
0 2 2 2 2 2 2 2 1 1
```

## Idea

Think of house numbers on a long street, where each digit position has a rhythm.

Fix a position and count how often a chosen digit fills it.
Smaller leading digits leave all lower positions free.
Equal leading digits leave a bounded suffix.
Subtract the count through A minus one from the count through B.

Position counting replaces millions of written integers with a few arithmetic steps.

## Why It Works

1. The count from A through B equals the count through B minus the count before A.
2. Shorter numbers contribute fixed counts based on their digit length.
3. A smaller leading digit frees all remaining positions, giving 10 raised to that remainder.
4. An equal leading digit leaves only the numeric suffix available.

| Term | Meaning |
|---|---|
| `countThrough` | returns ten counts for the range 1 through a limit |
| `remainingPositions` | positions still free after the current digit |
| `suffixValue` | numeric value of digits after the current one |

Every position contributes an exact block of counts, so the sum is exact.

Script-generated example from `gen.py`:

```
9 0 1 1 1 1 1 1 1 1 1
99 9 20 20 20 20 20 20 20 20 20
100 11 21 20 20 20 20 20 20 20 20
```

The trace shows counts from 1 up to each printed limit.

## Code

**Scanner and powers.** This block reads each endpoint and prepares powers of ten.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0.int64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var powersOfTen: array[12, int64]
powersOfTen[0] = 1
for exponent in 1..11:
  powersOfTen[exponent] = powersOfTen[exponent - 1] * 10
```

`nextNumber` skips non-digits and builds a 64-bit value.
`powersOfTen` holds 10 raised to exponents up to 11.
The zero line is detected in the main loop below.

**Counting function.** This block counts digits from one up to a given limit.

```nim
proc countThrough(limit: int64): array[10, int64] =
  for digit in 0..9:
    result[digit] = 0
  if limit < 1:
    return
  var boundDigits: array[12, int]
  var digitCount = 0
  var remaining = limit
  while remaining > 0:
    boundDigits[digitCount] = int(remaining mod 10)
    digitCount += 1
    remaining = remaining div 10
  for length in 1..<digitCount:
    for digit in 1..9:
      result[digit] += powersOfTen[length - 1]
    if length >= 2:
      for digit in 0..9:
        result[digit] += int64(length - 1) * 9 * powersOfTen[length - 2]
  for position in 0..<digitCount:
    let remainingPositions = digitCount - position - 1
    let currentDigit = boundDigits[digitCount - 1 - position]
    let smallestDigit = if position == 0: 1 else: 0
    for smallerDigit in smallestDigit..<currentDigit:
      result[smallerDigit] += powersOfTen[remainingPositions]
      if remainingPositions >= 1:
        for digit in 0..9:
          result[digit] += int64(remainingPositions) * powersOfTen[remainingPositions - 1]
    let suffixValue = limit mod powersOfTen[remainingPositions]
    result[currentDigit] += suffixValue + 1
```

The first loop handles all shorter digit lengths.
The second loop splits each position into smaller and equal leading digits.
All arithmetic stays in 64-bit integers.

**Answer loop.** This block prints ten differences per test case.

```nim
var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let lowerBound = nextNumber(inputData, scanPos)
  let upperBound = nextNumber(inputData, scanPos)
  if lowerBound == 0 and upperBound == 0: break
  let before = countThrough(lowerBound - 1)
  let through = countThrough(upperBound)
  for digit in 0..9:
    if digit > 0:
      appendOutput(" ")
    appendOutput($(through[digit] - before[digit]))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

`before` counts through A minus one, and `through` counts through B.
Spaces appear between counts but not after the last one.
The buffer flushes every 128 KiB.

## Complexity

Each endpoint triggers only a short fixed-length calculation.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Counting | ten positions times ten digits | one count array |
| Output | one write per 128 KiB block | block buffer |

Work per case does not grow with the numeric endpoints.

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(I) |

Writing and scanning every integer costs O(B - A + 1) per case instead.
