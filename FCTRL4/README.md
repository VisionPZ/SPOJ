# FCTRL4 — Last Non-Zero Digit of Factorials (SPOJ)

<https://www.spoj.com/problems/FCTRL4/>

## Problem

Read decimal integers from standard input and print the last non-zero decimal digit of each factorial. The input has no count, so processing runs until end of input.

| item | bound |
|---|---|
| each input value | positive integer below 10^100 |
| values per file | until end of input |
| judge limit | 500 ms, 1536 MB |

A trailing zero comes from one factor 2 paired with one factor 5. Groups of five drive the whole computation.

Sample input:

```
1
2
3
4
5
6
7
8
```

Sample output:

```
1
2
6
4
2
2
4
2
```

## Idea

Peel off factors of five in groups, like removing matched pairs from a stack until the last card shows. The recursive reduction by five uses a four-entry table for the small factorials and a four-cycle for powers of two. Each division scans at most 100 digits, and the chain has about 143 steps. Building the factorial would need astronomically many digits, so the reduction wins.

## Why It Works

1. Every trailing zero removes one paired 2 and 5 from the product.
2. Dividing the index by five counts the fives that form those pairs.
3. The untouched remainder contributes only one of four small factorial digits.
4. Each discarded five frees one factor 2, whose last digit cycles 2, 4, 8, 6.
5. Recursing on the quotient applies the same rule until the quotient is zero.

The equalities below use `divisorValue`, `smallFactorials`, and `powerPattern` from the source.

| term | meaning |
|---|---|
| `quotientText` | the input number after one division by five |
| `remainderValue` | the remainder of that division, from 0 to 4 |
| `exponentParity` | the quotient modulo four, indexing the power cycle |
| `answerDigit` | the final last non-zero digit, from 0 to 9 |

This table replaces the factorial with three small lookups per level.

The reduction for N = 25, produced by the oracle in gen.py:

| level | number | quotient | remainder | power factor | returned digit |
|---|---|---|---|---|---|
| 0 | 25 | 5 | 0 | 2 | 4 |
| 1 | 5 | 1 | 0 | 2 | 2 |
| 2 | 1 | empty | 1 | none | 1 |

The chain returns 4, the last non-zero digit of 25 factorial.

## Code

**Input and digit scanner.** The reader loads all lines and extracts digit strings.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const divisorValue = 5
const smallFactorials = [1, 1, 2, 6, 4]
const powerPattern = [6, 2, 4, 8]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDigits(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let firstDigitPos = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  return data[firstDigitPos ..< pos]
```

The scanner skips whitespace one byte at a time.
Digit strings stay as text because they exceed machine integers.
The pass costs one visit per input byte.

**Recursive reduction.** Long division by five drives the recurrence.

```nim
proc divideByFive(numberText: string, quotientText: var string): int =
  quotientText = ""
  var remainderValue = 0
  for digitChar in numberText:
    let partialValue = remainderValue * 10 + int(digitChar) - firstDigitValue
    let quotientDigit = partialValue div divisorValue
    remainderValue = partialValue mod divisorValue
    if quotientText.len > 0 or quotientDigit > 0:
      quotientText.add chr(quotientDigit + firstDigitValue)
  return remainderValue

proc remainderModFour(numberText: string): int =
  var remainderValue = 0
  for digitChar in numberText:
    remainderValue = (remainderValue * 10 + int(digitChar) - firstDigitValue) mod 4
  return remainderValue

proc lastNonZeroDigit(numberText: string): int =
  var quotientText = ""
  let remainderValue = divideByFive(numberText, quotientText)
  if quotientText.len == 0:
    return smallFactorials[remainderValue]
  let exponentParity = remainderModFour(quotientText)
  return (lastNonZeroDigit(quotientText) * smallFactorials[remainderValue] * powerPattern[exponentParity]) mod 10
```

Leading zeros never enter the quotient string.
The base case returns one of the four small factorial digits.
Each level multiplies three single-digit values, so no overflow occurs.

**Buffered output loop.** Digits are appended and flushed in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let numberText = nextDigits(inputData, scanPos)
  if numberText.len == 0:
    break
  let answerDigit = lastNonZeroDigit(numberText)
  appendOutput($answerDigit)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops when no more digits remain.
One newline follows every answer digit.
A final flush closes the output path.

## Complexity

Let d be the number of decimal digits in one input value, at most 100.

| phase | time | space |
|---|---|---|
| input read | one pass over all input bytes | one input string |
| reduction by five | about 143 divisions of d digits | quotient strings on the stack |
| output | one append per answer digit | one block buffer |

The work per number grows with the square of its digit count.

| measure | Big O |
|---|---|
| time per number | O(d^2) |
| space per number | O(d^2) |

Computing each factorial in full would need billions of digits, while this reduction touches a few hundred.
