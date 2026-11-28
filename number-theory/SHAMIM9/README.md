# SHAMIM9 — Antik the Numerologist (SPOJ)
<https://www.spoj.com/problems/SHAMIM9/>

## Problem

For each input integer N, print the last digit of 9 times N.

The statement bounds N below 10 to the power of 40, so values can exceed machine integers.
Input values appear as decimal tokens, one per line or separated by whitespace.
One digit is printed per value.

| Item | Value |
|---|---|
| Input | decimal integers with up to 40 digits |
| Output | one digit per integer |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Only the final decimal digit can affect the answer.

The statement gives two sample cases verbatim.

```
3
```

```
7
```

```
99
```

```
1
```

## Idea

Think of a multiplication table where only the final column survives.
The units digit of a product uses only the units digits of the factors.
The program keeps the last digit while scanning each token and computes nine times that digit modulo ten.
Multiplying the whole 40-digit value would need big-integer arithmetic.

One digit per token is enough.

## Why It Works

1. Decimal multiplication takes its units digit from the units digits alone.
2. The scanner overwrites the current digit, so it ends with the last digit of the token.
3. Multiplying that digit by nine and taking the remainder mod ten gives the units digit.
4. Skipping non-digits lets any whitespace separate the values.
5. No full integer is built, so 40-digit inputs cannot overflow.

The main names and values:

| Term | Meaning |
|---|---|
| `nextLastDigit` | scans a token and keeps its final digit |
| `digitValue` | current digit of the token being scanned |
| `resultDigit` | last digit of nine times the token |
| `appendOutput` | adds text and flushes a full block |

The scanner stores a single digit, never the whole value.

A script trace of the second sample case shows the product.

```
N: 99
9 times N: 891
last digit: 1
```

The final digit of 891 matches the sample answer.

## Code

**Read the whole stream.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

All input bytes sit in one string. The digit offset and flush size are named constants.

**Keep only the last digit.**
```nim
proc nextLastDigit(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var digitValue = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    digitValue = int(data[pos]) - firstDigitValue
    pos += 1
  return digitValue
```

The scan skips separators first. Each digit replaces the previous one.

**Buffer output in blocks.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 128 KiB. A reset reuses the string.

**Print one digit per case.**
```nim
var scanPos = 0

while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let lastDigit = nextLastDigit(inputData, scanPos)
  let resultDigit = (9 * lastDigit) mod 10
  appendOutput($(resultDigit))
  outputBuffer.add '\n'
```

The loop ends when no tokens remain. Multiplication by nine stays tiny.

**Emit the final partial block.**
```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

The last write clears the buffer. Each answer ends with a newline.

## Complexity

The program reads each digit once and writes one digit per token.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Last digit | one step per digit | constant |
| Output | one write per full block | block buffer |

Cost grows with the number of input digits.

| Measure | Big O |
|---|---|
| Time | O(input digits) |
| Space | O(input bytes) |

Multiplying full 40-digit integers would cost more per case, so digit-only scanning wins.
