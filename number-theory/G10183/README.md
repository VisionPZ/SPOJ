# G10183 — Divide Grado 10 (SPOJ)

<https://www.spoj.com/problems/G10183/>

## Problem

For each number, print a chain of shrinking values and say whether the original number is divisible by 11. Each step deletes the last digit and subtracts that digit from what remains.

Input holds one positive integer per line of at most 50 digits, and a line containing 0 ends the input. For every number, print the number, then each shrunken value while it has more than two digits, then a Spanish verdict line. Put a blank line after each case.

| Item | Bound |
|---|---|
| Digits per number | at most 50 |
| Input | one number per line, ending at 0 |
| Judge limit | 1000 ms, 1536 MB |

The 50-digit bound rules out native integer types, so the digits stay as text.

Sample input:

```
12345678901234567900
896245630004
0
```

Sample output:

```
12345678901234567900
1234567890123456790
123456789012345679
12345678901234558
1234567890123447
123456789012337
12345678901226
1234567890116
123456789005
12345678895
1234567884
123456784
12345674
1234563
123453
12342
1232
121
11
El numero 12345678901234567900 es divisible por 11.

896245630004
89624562996
8962456293
896245626
89624556
8962449
896235
89618
8953
892
87
El numero 896245630004 no es divisible por 11.

```

## Idea

Peel the last digit off each number and subtract it, like stripping layers from an onion. The work stays in decimal text with a borrow-based helper, one step per printed line. Each step shortens the text by at least one digit, so 50 digits cost at most 48 steps. Converting the whole number to a native integer would overflow long before 50 digits. One helper handles both the shrink and the final remainder.

## Why It Works

1. Removing the last digit and subtracting it preserves the remainder modulo 11.
2. The peel stops once the decimal text holds two digits or fewer.
3. Each peel removes one digit, so a 50-digit number takes at most 48 steps.
4. Borrow subtraction handles cases such as 10 minus 9, which becomes 1 after a leading zero is dropped.
5. An alternating digit sum from the right gives the remainder modulo 11; for 11 it is 1 minus 1, or 0.

The terms used by the peel:

| Term | Meaning |
|---|---|
| `nextDigitText` | reads one run of digits from the input |
| `canonicalDigits` | strips leading zeros and keeps one digit for zero |
| `subtractDigit` | subtracts one digit from a decimal string with borrow |
| `isDivisibleByEleven` | tests the alternating digit sum against `divisorValue` |
| `remainingText` | the current shrunken value as decimal text |
| `stepLines` | every printed value for the current case |

Each term maps to one step of the string-only arithmetic.

A script-traced example:

```
start 121
peel: 12 - 1 = 11
stop: 11 has two digits
alternating sum right to left: 1 - 1 = 0
0 mod 11 = 0, so the verdict is divisible
```

The trace matches the tail of the first sample case.

## Code

**Input and digit helpers.** These declarations load stdin and normalize digit runs.

```nim
const flushBlockBytes = 1 shl 17
const divisorValue = 11

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDigitText(data: string, pos: var int): string =
  result = ""
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result.add data[pos]
    pos += 1

proc canonicalDigits(rawText: string): string =
  var start = 0
  while start < rawText.len - 1 and rawText[start] == '0':
    start += 1
  result = rawText[start .. rawText.len - 1]
```

The scanner returns digits as text, so 50 digits stay exact. Leading zeros never reach the peel.

**Borrow subtraction and divisibility.** These helpers replace big-integer arithmetic.

```nim
proc subtractDigit(numberText: string, digitValue: int): string =
  var digits = newSeq[int](numberText.len)
  for index in 0 .. numberText.len - 1:
    digits[index] = int(numberText[index]) - 48
  var borrow = 0
  var position = digits.len - 1
  var difference = digits[position] - digitValue
  if difference < 0:
    difference += 10
    borrow = 1
  digits[position] = difference
  position -= 1
  while position >= 0 and borrow > 0:
    difference = digits[position] - borrow
    if difference < 0:
      difference += 10
      borrow = 1
    else:
      borrow = 0
    digits[position] = difference
    position -= 1
  var start = 0
  while start < digits.len - 1 and digits[start] == 0:
    start += 1
  result = ""
  for index in start .. digits.len - 1:
    result.add chr(digits[index] + 48)

proc isDivisibleByEleven(numberText: string): bool =
  var alternating = 0
  var position = 0
  var index = numberText.len - 1
  while index >= 0:
    let digitValue = int(numberText[index]) - 48
    if position mod 2 == 0:
      alternating += digitValue
    else:
      alternating -= digitValue
    position += 1
    index -= 1
  return alternating mod divisorValue == 0
```

The borrow walks left until it is spent. The alternating sum needs no division of the full number.

**Peeling loop and output.** This block emits every step and the final verdict.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseCount = 0
while true:
  let rawNumber = nextDigitText(inputData, scanPos)
  if rawNumber.len == 0:
    break
  if rawNumber == "0":
    break
  let originalText = canonicalDigits(rawNumber)
  var stepLines: seq[string] = @[]
  stepLines.add originalText
  var remainingText = originalText
  while remainingText.len > 2:
    let lastDigit = int(remainingText[remainingText.len - 1]) - 48
    let truncatedText = canonicalDigits(remainingText[0 .. remainingText.len - 2])
    remainingText = subtractDigit(truncatedText, lastDigit)
    stepLines.add remainingText
  if caseCount > 0:
    appendOutput("\n")
  for stepText in stepLines:
    appendOutput(stepText)
    appendOutput("\n")
  if isDivisibleByEleven(remainingText):
    appendOutput("El numero " & originalText & " es divisible por 11.\n")
  else:
    appendOutput("El numero " & originalText & " no es divisible por 11.\n")
  caseCount += 1
if caseCount > 0:
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop guard is the two-digit text length. A blank line separates each case, including the last.

## Complexity

The peel and the string helpers set the cost per case.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input string |
| Peeling | at most 48 steps per number | one step list |
| Output | one line per step and verdict | block buffer |

The number of cases multiplies the bounded per-case peel work.

| Measure | Big O |
|---|---|
| Time | O(lines × digits) |
| Space | O(N) for the input string |

A divisibility test at every step would add work the statement never asks for, so one final test wins.
