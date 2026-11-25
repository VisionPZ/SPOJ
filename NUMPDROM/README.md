# NUMPDROM — Palindrom of Number (SPOJ)

<https://www.spoj.com/problems/NUMPDROM/>

## Problem

Decide whether one positive integer reads the same from right to left. Print YA when it does and TIDAK when it does not.

The input holds a single integer below 100000. Print one word.

| item | bound |
|---|---|
| integer n | positive, below 100000 |
| judge limit | 1000 ms, 1536 MB |

The bound is small enough for digit-by-digit arithmetic.

Sample input:

```
1221
```

Sample output:

```
YA
```

## Idea

Build the reversed number by peeling digits off the right, like moving beads from one side of an abacus to the other. Each peeled digit is appended to a new number. Comparing that new number with the original settles the question. No text conversion is needed.

## Why It Works

1. Taking the last digit and dividing by ten removes one digit from the right.
2. Appending that digit to a growing value builds the mirror image.
3. Repeating until zero consumes every digit exactly once.
4. Equality of the mirror and the original is the palindrome test.

| term | meaning |
|---|---|
| `originalNumber` | the number read from input |
| `reversedNumber` | value built by appending peeled digits |
| `remainingNumber` | digits still waiting to be peeled |

The loop costs one division per digit.

Script-generated trace for the sample number:

```
step | remaining | peeled | reversed
1 | 1221 | 1 | 1
2 | 122 | 2 | 12
3 | 12 | 2 | 122
4 | 1 | 1 | 1221
```

The reversed value equals 1221, so the program prints YA.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed by a digit scanner.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The scanner skips spaces and line breaks.
One number is all the input contains.
Parsing costs a few digit operations.

**Digit reversal and output.** Peeled digits rebuild the mirror value.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let originalNumber = nextInt(inputData, scanPos)
var remainingNumber = originalNumber
var reversedNumber = 0
while remainingNumber > 0:
  reversedNumber = reversedNumber * 10 + (remainingNumber mod 10)
  remainingNumber = remainingNumber div 10
if reversedNumber == originalNumber:
  appendOutput("YA")
else:
  appendOutput("TIDAK")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Every digit is visited once.
The final comparison chooses one word.
The verdict is written from the block buffer.

## Complexity

One short loop handles the whole input.

| phase | time | space |
|---|---|---|
| input read | one integer | one input string |
| digit reversal | one step per digit | three integers |
| output | one word | block buffer |

No string allocation is needed.

| measure | Big O |
|---|---|
| time | O(number of digits) |
| space | O(1) apart from buffers |

Converting to text and reversing a string would do the same work with extra allocation.
