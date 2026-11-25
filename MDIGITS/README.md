# MDIGITS — Counting Digits (SPOJ)

<https://www.spoj.com/problems/MDIGITS/>

## Problem

Write every integer from a to b inclusive, then count how many times each digit 0 through 9 appears. The two endpoints arrive in either order, as the sample shows.

Each line contains two integers a and b. A line 0 0 ends the input. For every other line, print ten counts separated by single spaces, starting with the count for digit 0.

| Item | Bound |
|---|---|
| Endpoints a and b | greater than 0 and less than 100000000 |
| Input lines | up to 500 |
| Output per line | ten counts with single spaces |
| Judge limit | 1000 ms, 1536 MB |

Brute printing of every number cannot handle ranges near one hundred million.

Sample input:

```
1 10
44 497
346 542
1199 1748
1496 1403
1004 503
1714 190
1317 854
1976 494
1001 1960
0 0
```

Sample output:

```
1 2 1 1 1 1 1 1 1 1
85 185 185 185 190 96 96 96 95 93
40 40 40 93 136 82 40 40 40 40
115 666 215 215 214 205 205 154 105 106
16 113 19 20 114 20 20 19 19 16
107 105 100 101 101 197 200 200 200 200
413 1133 503 503 503 502 502 417 402 412
196 512 186 104 87 93 97 97 142 196
398 1375 398 398 405 499 499 495 488 471
294 1256 296 296 296 296 287 286 286 247
```

## Idea

Counting digits across a range works like counting page labels in a book by place value, one digit column at a time.

For one place value, split numbers from 1 to n into complete cycles and a partial cycle. Each full cycle contributes a fixed count per digit. The leftover digits depend on the current digit and the lower part. Compute the count up to b, subtract the count up to a-1, and repeat for all ten digits. Scanning every number would cost a hundred million string conversions.

## Why It Works

1. At place value p, digits repeat in cycles of length 10p.
2. The higher part gives the number of full cycles before the current digit.
3. A digit below the current digit gains one extra full block of size p.
4. A digit equal to the current digit gains the lower part plus one.
5. For digit 0, the first cycle has no leading zeros, so its block count drops by one.
6. Subtracting the prefix at a-1 turns a prefix count into a range count.

| Term | Meaning |
|---|---|
| `placeValue` | current decimal column, starting at one |
| `higherPart` | number of complete digit cycles above the column |
| `currentDigit` | digit sitting in the column at the prefix limit |
| `lowerPart` | digits below the current column |

The table names the four values that decide one column's contribution.

A script trace for the range 1 to 10:

```
limit 10, digit 0, place 1: higher 1, current 0 -> 1 zero
limit 10, digit 1, place 1: higher 1, current 0 -> 1 one
limit 10, digit 1, place 10: higher 0, current 1 -> 1 one
prefix difference at a - 1 = 0 gives counts 1 2 1 1 1 1 1 1 1 1
```

The trace matches the first sample line.

## Code

**Input and scanner.** All lines enter one buffer, and the scanner reads positive integers.

```nim
const flushBlockBytes = 1 shl 17
const digitKinds = 10

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

There is no minus branch because endpoints stay positive.
Spacing and line breaks are skipped as non-digits.
The sentinel line ends the parse loop.

**Prefix counting.** One pass over decimal columns counts a single digit from 1 to n.

```nim
proc countDigitUpTo(limitValue: int64, digitValue: int): int64 =
  if limitValue <= 0:
    return 0
  var placeValue: int64 = 1
  while placeValue <= limitValue:
    let higherPart = limitValue div (placeValue * 10)
    let currentDigit = (limitValue div placeValue) mod 10
    let lowerPart = limitValue mod placeValue
    if digitValue == 0:
      if higherPart != 0:
        if currentDigit == 0:
          result += (higherPart - 1) * placeValue + lowerPart + 1
        else:
          result += (higherPart - 1) * placeValue + placeValue
    else:
      result += higherPart * placeValue
      if currentDigit > int64(digitValue):
        result += placeValue
      elif currentDigit == int64(digitValue):
        result += lowerPart + 1
    placeValue *= 10
```

Zero is special because leading zeros are never written.
All counts use int64 to hold totals near one billion.
The loop visits at most eight columns for this bound.

**Range output.** The driver swaps endpoints, takes prefix differences, and writes one line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let firstValue = int64(nextInt(inputData, scanPos))
  let secondValue = int64(nextInt(inputData, scanPos))
  if firstValue == 0 and secondValue == 0:
    break
  var lowLimit = firstValue
  var highLimit = secondValue
  if lowLimit > highLimit:
    let previousLow = lowLimit
    lowLimit = highLimit
    highLimit = previousLow
  var digitCounts = newSeq[int64](digitKinds)
  for digitValue in 0 .. digitKinds - 1:
    digitCounts[digitValue] = countDigitUpTo(highLimit, digitValue) - countDigitUpTo(lowLimit - 1, digitValue)
  for digitValue in 0 .. digitKinds - 1:
    if digitValue > 0:
      appendOutput " "
    appendOutput($digitCounts[digitValue])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The swap makes reversed pairs behave like the sample cases.
Twenty prefix calls produce the ten answers for one line.
Block buffering keeps the 500-line output cheap.

## Complexity

Each input line runs a fixed number of short prefix scans.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Prefix scans | ten digits times two limits | ten counters |
| Output | buffered writes | block buffer |

The table shows that work depends on digit length, not range width.

| Measure | Big O |
|---|---|
| Time | O(10 log b) per line |
| Space | O(1) |

Writing every number in the range would cost O(b-a) time per line.
