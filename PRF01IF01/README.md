# PRF01IF01 — IF (SPOJ)
<https://www.spoj.com/problems/PRF01IF01/>

## Problem

Read one integer and report whether it is even, odd, or zero using three fixed messages. The prompt prints first and ends without a newline.

Input holds integers separated by whitespace; each integer gets one answer. Output holds the prompt, then "Thank you." for an even number, "X is zero." for zero, or "X isn't an even number." for an odd number. Here X stands for the parsed integer printed in the message.

| item | bound |
|---|---|
| integer | signed integer, 32-bit range |
| answers per input | one per integer |
| judge limit | 1000 ms, 1536 MB |

The statement prints typed numbers in its examples; those numbers come from the terminal echo.

Statement Example 1 appears verbatim here:

    Please enter an even number:2Thank you.

The judge feeds only the typed number and compares only program output.

Sample input:

    2

Sample output:

    Please enter an even number:Thank you.

## Idea

Split incoming numbers into three bins, like sorting mail into even, odd, and zero slots before stamping each piece.

The program scans an integer, tests its remainder on division by two, then appends one message. Each number costs a few comparisons and one buffered append. Testing every bit of the number would add work without changing the answer. Check the remainder once, choose a message, repeat.

## Why It Works

1. A zero value needs its own line before the parity test.
2. An even value leaves remainder zero when divided by two.
3. Every other integer prints the failure line with its value.
4. A minus sign in the input flips the sign before the test.
5. The prompt never emits a newline, so the message follows it on the same line.

| term | meaning |
|---|---|
| `enteredNumber` | parsed integer from input |
| `promptText` | fixed question printed before the answer |
| `successMessage` | fixed reply for an even value |
| `failureSuffix` | text appended after an odd value |

The generator checks these exact values before writing test data:

    2    -> Thank you.
    1    -> 1 isn't an even number.
    0    -> 0 is zero.
    -7   -> -7 isn't an even number.

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
const promptText = "Please enter an even number:"
const successMessage = "Thank you."
const zeroSuffix = " is zero."
const failureSuffix = " isn't an even number."

while hasNextNumber(inputData, scanPos):
  let enteredNumber = nextInt(inputData, scanPos)
  appendOutput(promptText)
  if enteredNumber == 0:
    appendOutput($enteredNumber & zeroSuffix)
  elif enteredNumber mod 2 == 0:
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
