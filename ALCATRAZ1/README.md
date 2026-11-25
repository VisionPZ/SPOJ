# ALCATRAZ1 — Sum of Digits (SPOJ)

<https://www.spoj.com/problems/ALCATRAZ1/>

## Problem

We are given T numbers, each with up to 51 digits. Print the sum of the decimal digits of each number.

Input: the first line contains T, followed by T lines with one number each. Output: T lines, each holding the digit sum of the matching number.

| Item | Bound |
|---|---|
| Test count T | less than 10 |
| Number N | 1 to 10^50 |
| Judge limit | 1000 ms |

The number can exceed every fixed-width integer type, so it must be read as text.

Sample input:

```
3
123123123
3434
1234567890
```

Sample output:

```
18
14
45
```

## Idea

Think of counting pips on a row of dominoes, one tile at a time. Read each number as a whitespace-separated token, then visit its characters in order. A digit character has code 48 through 57, so subtracting 48 yields its numeric value. Add those values into one sum and print it. Each character costs one subtraction and one addition, so the work is linear in the total digit count.

## Why It Works

1. A decimal digit character has code from 48 to 57 in order.
2. Subtracting 48 maps each character to its numeric digit value.
3. Summing those values gives the digit sum regardless of number size.
4. Token reading keeps all 51 digits intact, avoiding integer overflow.

| Term | Meaning |
|---|---|
| `numberText` | the number read as a string token |
| `firstDigitValue` | character code 48 |
| `digitSum` | running sum of digit values |

The scanner advances by index, so no parsing helper is needed.

Script-generated example from `gen.py`:

```
number 123123123 digits 1 2 3 1 2 3 1 2 3 sum 18
number 3434 digits 3 4 3 4 sum 14
number 1234567890 digits 1 2 3 4 5 6 7 8 9 0 sum 45
```

The traced sums match the sample output `18 14 45`.

## Code

**Input scanner and output buffer.** This block reads input into one string and provides digit and token scanners.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextInt` reads the small test count. `nextToken` reads each large number as text. The buffer flushes at 128 KiB.

**Digit summation.** This block visits each number and prints its digit sum.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0..<testCount:
  let numberText = nextToken(inputData, scanPos)
  var digitSum = 0
  for charIndex in 0..<numberText.len:
    digitSum += int(numberText[charIndex]) - firstDigitValue
  appendOutput($(digitSum))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop visits exactly one token per test. No digit is converted to a machine integer.

## Complexity

The scanner reads each input byte once and each digit once more during summation.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Digit sum | one pass over each number | one number token |
| Output | one write per 128 KiB block | block buffer |

The input string dominates memory use.

| Measure | Big O |
|---|---|
| Time | O(D) |
| Space | O(D) |

Converting each number to a fixed-width integer would overflow at 10^50; string scanning avoids that.
