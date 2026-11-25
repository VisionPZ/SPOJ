# PRF01IF02 — IF (SPOJ)
<https://www.spoj.com/problems/PRF01IF02/>

## Problem

Read one integer and report whether it is odd, even, or zero using three fixed messages. The prompt prints first and ends without a newline.

Input holds integers separated by whitespace; each integer gets one answer. Output holds the prompt, then "Thank you." for an odd number, "X is zero." for zero, or "X isn't an odd number." for an even number. Here X stands for the parsed integer printed in the message.

| item | bound |
|---|---|
| integer | signed integer, 32-bit range |
| answers per input | one per integer |
| judge limit | 1000 ms, 1536 MB |

The statement prints typed numbers in its examples; those numbers come from the terminal echo.

Statement Example 1 appears verbatim here:

    Please enter an odd number:1Thank you.

The judge feeds only the typed number and compares only program output.

Sample input:

    1

Sample output:

    Please enter an odd number:Thank you.

## Idea

Sort each number into odd, even, or zero, like separating left socks from right socks and finding the odd pair first.

The program scans an integer, tests its remainder on division by two, then appends one message. Each number costs a few comparisons and one buffered append. Scanning every digit again for a second test would add work without changing the answer. Check the remainder once, choose a message, repeat.

## Why It Works

1. A zero value needs its own line before the parity test.
2. An odd value leaves remainder one when divided by two.
3. Every other integer prints the failure line with its value.
4. A minus sign in the input flips the sign before the test.
5. The prompt never emits a newline, so the message follows it on the same line.

| term | meaning |
|---|---|
| `enteredNumber` | parsed integer from input |
| `promptText` | fixed question printed before the answer |
| `successMessage` | fixed reply for an odd value |
| `failureSuffix` | text appended after an even value |

The generator checks these exact values before writing test data:

    1    -> Thank you.
    2    -> 2 isn't an odd number.
    0    -> 0 is zero.
    -8   -> -8 isn't an odd number.

Negative values follow the same rule because parity depends only on the remainder.

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

**Classification and answer.** One branch chooses among the three fixed replies.

```nim
const promptText = "Please enter an odd number:"
const successMessage = "Thank you."
const zeroSuffix = " is zero."
const failureSuffix = " isn't an odd number."

while hasNextNumber(inputData, scanPos):
  let enteredNumber = nextInt(inputData, scanPos)
  appendOutput(promptText)
  if enteredNumber == 0:
    appendOutput($enteredNumber & zeroSuffix)
  elif enteredNumber mod 2 != 0:
    appendOutput(successMessage)
  else:
    appendOutput($enteredNumber & failureSuffix)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Zero is handled before the parity test.
The failure line includes the parsed value.
One newline ends each answer.

## Complexity

Each integer needs one digit scan and one branch.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| classification | constant work per integer | one integer |
| output | one buffered write per block | one output string |

| measure | Big O |
|---|---|
| time | O(total input characters) |
| space | O(total input characters) |

Printing each fragment with a separate write would multiply system calls per answer. A single branch and one buffer keep the reply linear in the input size.
