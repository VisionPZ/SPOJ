# PRF01IF04 — IF (SPOJ)
<https://www.spoj.com/problems/PRF01IF04/>

## Problem

Read one integer and print whether it is a nonzero multiple of both five and two. The prompt prints first and ends without a newline.

Input holds integers separated by whitespace; each integer gets one answer. Output holds the prompt, then "Thank you." for a passing value or "X isn't a number divisible by 5 and divisible by 2." for a failing value. Here X stands for the parsed integer printed in the message.

| item | bound |
|---|---|
| integer | signed integer, 32-bit range |
| answers per input | one per integer |
| judge limit | 1000 ms, 1536 MB |

The statement prints typed numbers in its examples; those numbers come from the terminal echo.

Statement Example 2 appears verbatim here:

    Please enter a number divisible by 5 and divisible by 2:10Thank you.

The judge feeds only the typed number and compares only program output.

Sample input:

    10

Sample output:

    Please enter a number divisible by 5 and divisible by 2:Thank you.

## Idea

Treat the test like a gate with two badges, one for five and one for two; a value with no badges at all cannot enter.

The program scans an integer and checks two remainders plus the zero guard. Each number costs two divisions and one buffered append. Testing every smaller multiple would grow with the value instead of staying constant. Combine the tests, choose a message, repeat.

## Why It Works

1. Remainder zero on division by five marks a multiple of five.
2. Remainder zero on division by two marks a multiple of two.
3. Both remainders vanish for a multiple of ten.
4. Statement Example 4 rejects zero, so the guard excludes it.
5. A minus sign in the input flips the sign before both tests.

| term | meaning |
|---|---|
| `enteredNumber` | parsed integer from input |
| `promptText` | fixed question printed before the answer |
| `successMessage` | fixed reply for a passing value |
| `failureSuffix` | text appended after a failing value |

The generator checks these exact values before writing test data:

    10   -> Thank you.
    0    -> 0 isn't a number divisible by 5 and divisible by 2.
    11   -> 11 isn't a number divisible by 5 and divisible by 2.
    -20  -> Thank you.
    15   -> 15 isn't a number divisible by 5 and divisible by 2.

The oracle checks the last digit of the value to reach the same decision by another route.

## Code

**Input and buffer setup.** One read loop collects stdin, and the hand scanner yields signed integers.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var numberValue = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    numberValue = numberValue * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * numberValue

proc hasNextNumber(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and (data[scanIndex] < '0' or data[scanIndex] > '9') and data[scanIndex] != '-':
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips whitespace and honors a leading minus.
The lookahead detects the end of the number list.
The buffer keeps writes in large blocks.

**Two-part test and answer.** One combined branch chooses the reply.

```nim
const promptText = "Please enter a number divisible by 5 and divisible by 2:"
const successMessage = "Thank you."
const failureSuffix = " isn't a number divisible by 5 and divisible by 2."

while hasNextNumber(inputData, scanPos):
  let enteredNumber = nextInt(inputData, scanPos)
  appendOutput(promptText)
  if enteredNumber != 0 and enteredNumber mod 5 == 0 and enteredNumber mod 2 == 0:
    appendOutput(successMessage)
  else:
    appendOutput($enteredNumber & failureSuffix)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero guard appears before both remainder tests.
The failure line includes the parsed value.
One newline ends each answer.

## Complexity

Each integer needs one digit scan and two remainder tests.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| classification | constant work per integer | one integer |
| output | one buffered write per block | one output string |

| measure | Big O |
|---|---|
| time | O(total input characters) |
| space | O(total input characters) |

Checking each smaller multiple would grow with the value size. Two remainder tests and one buffer keep the reply linear in the input size.
