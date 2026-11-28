# MOZMTF — Mozahid the forgetful (SPOJ)

<https://www.spoj.com/problems/MOZMTF/>

## Problem

Mozahid wrote 10 of the 11 digits of an 11-digit number, keeping their order, and he remembers the sum of all 11 digits. The original number was the largest one that fits. Print it.

Input holds the 10 written digits on one line, then the digit total on the next line. Output holds the restored 11-digit number.

| Item | Bound |
|---|---|
| Written number | 10 digits, may start with 0 |
| Digit total m | m ≥ sum of the 10 written digits |
| Original number | 11 digits, no leading zero, largest that fits |
| Judge limit | 1000 ms, 1536 MB |

One pass over 10 digits is enough.

The sample case:

```
1234567890
50
```

```
51234567890
```

## Idea

The missing digit is forced: it is m minus the sum of the written digits. Only its position is free. Slide it left while doing so makes the number bigger, and stop in front of the first digit that is smaller than it; otherwise put it at the end. Think of inserting a new card into a row of cards so the row reads as large as possible: push it left until it meets a bigger card. That costs one pass over 10 digits. Testing all 11 slots and comparing the results costs 11 big-number comparisons.

## Why It Works

1. The missing digit equals `m - (sum of written digits)`, and a valid input keeps it in 0..9, so it is unique.
2. Two 11-digit numbers compare by their first differing digit; the one with the bigger digit there is larger.
3. Dropping the missing digit in front of a smaller digit makes the number larger at that spot, and nothing before that spot changes.
4. While the next digit is at least as big as the missing digit, moving left cannot help, because it would put the smaller digit earlier. So the first strictly smaller digit is the right spot.
5. If no digit is smaller, the end is the best spot.
6. A leading zero never appears: only a 0 placed first would create one, and 0 is never smaller than a digit, so 0 always goes to the end.

| Term | Meaning |
|---|---|
| `writtenNumber` | the 10 digits Mozahid wrote |
| `targetDigitSum` | m, the sum of all 11 digits |
| `digitSum` | sum of the 10 written digits |
| `missingDigitValue` | `targetDigitSum - digitSum`, the forgotten digit |
| `insertPos` | where the missing digit goes |

The spot found by the scan is the whole answer.

A script-traced example from `gen.py`:

```
written 1234567890
digit sum 45, target 50, missing 5
insert 5 before the first digit smaller than 5 -> 51234567890
```

The trace matches the sample answer.

## Code

**Input, scanner, and token reader.** This block loads stdin and reads the digit string plus the total.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var tokenEnd = position
  while tokenEnd < data.len and data[tokenEnd] > ' ':
    tokenEnd += 1
  var tokenText = ""
  while position < tokenEnd:
    tokenText.add data[position]
    position += 1
  return tokenText
```

One readLine loop collects all input bytes.
`nextToken` keeps the written number as text, so leading zeros survive.
`nextInt` reads the digit total.

**Buffered output.** This block collects finished answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Restore loop.** This block finds the digit, finds its spot, and writes the answer.

```nim
while scanPos < inputData.len:
  let writtenNumber = nextToken(inputData, scanPos)
  if writtenNumber.len == 0:
    break
  let targetDigitSum = nextInt(inputData, scanPos)
  var digitSum = 0
  for digitIndex in 0..<writtenNumber.len:
    digitSum += ord(writtenNumber[digitIndex]) - firstDigitValue
  let missingDigitValue = targetDigitSum - digitSum
  var insertPos = writtenNumber.len
  for digitIndex in 0..<writtenNumber.len:
    if ord(writtenNumber[digitIndex]) - firstDigitValue < missingDigitValue:
      insertPos = digitIndex
      break
  var restoredNumber = ""
  for digitIndex in 0..<insertPos:
    restoredNumber.add writtenNumber[digitIndex]
  restoredNumber.add chr(firstDigitValue + missingDigitValue)
  for digitIndex in insertPos..<writtenNumber.len:
    restoredNumber.add writtenNumber[digitIndex]
  appendOutput(restoredNumber)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop keeps reading digit-total pairs until the input ends, so extra cases also work.
The insert scan stops at the first digit strictly smaller than the missing one.
Each answer costs two short passes over 10 characters.

## Complexity

The cost splits into input, one scan per case, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Restore | O(10) per case | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(cases) |
| Space | O(N) for the input buffer |

Trying all 11 slots and comparing whole numbers costs 11 × 11 digit compares per case; the single scan stays at about 20 steps.
