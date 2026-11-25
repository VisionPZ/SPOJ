# PRF0101 — Positive, negative or zero (SPOJ)

<https://www.spoj.com/problems/PRF0101/>

## Problem

Read one integer and report whether it is positive, negative, or zero. The answer follows a fixed prompt printed at the start of the line.

| item | bound |
|---|---|
| input value t | greater than -100 and at most 100 |
| output lines | 1 |
| judge limit | 1000 ms, 1536 MB |

Positive and negative answers repeat the entered value.
The zero answer names zero without repeating the value.

Sample input:

```
1
```

Sample output:

```
Please enter any integer: 1 is a positive number
```

## Idea

Sorting letters into three trays works the same way: one number lands in the positive tray, the negative tray, or the zero tray. The program scans the integer, finds its sign, and joins the matching phrase to the prompt. Each step costs a fixed number of operations. Comparing the number with zero twice already decides all three cases. A single line of output finishes the run.

## Why It Works

1. The scanner skips non-digit bytes and keeps a leading minus sign.
2. Digits build the magnitude, and the minus sign negates it.
3. A value above zero selects the positive phrase.
4. A value below zero selects the negative phrase.
5. Zero selects the phrase that names zero.

| term | meaning |
|---|---|
| `inputData` | text read from stdin |
| `scanPos` | current index inside `inputData` |
| `enteredNumber` | signed integer from the input |
| `outputBuffer` | pending output bytes |

A short script checks the three cases:

| input | sign | printed line |
|---|---|---|
| 1 | positive | Please enter any integer: 1 is a positive number |
| -9 | negative | Please enter any integer: -9 is a negative number |
| 0 | zero | Please enter any integer: The number entered is zero |

The bounds keep the magnitude small, so no wider type is needed.

## Code

**Input and scanning.** The sign-aware scanner handles negative values.

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
  var isNegative = false
  if pos < data.len and data[pos] == '-':
    isNegative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if isNegative:
    return -value
  return value
```

The minus sign is kept while other non-digits are skipped.
Each digit shifts the total by ten before it is added.
The scan stops at the first non-digit after the number.

**Classification and output.** Three branches select one fixed phrase.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let enteredNumber = nextInt(inputData, scanPos)
appendOutput("Please enter any integer: ")
if enteredNumber > 0:
  appendOutput($enteredNumber & " is a positive number")
elif enteredNumber < 0:
  appendOutput($enteredNumber & " is a negative number")
else:
  appendOutput("The number entered is zero")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The prompt is appended before the branch.
Positive and negative phrases include the number.
One write sends the completed line.

## Complexity

The scan touches each input byte once.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| parse | one pass over the number digits | constant |
| classification and output | three branches | one buffer string |

| measure | Big O |
|---|---|
| time | O(L), where L is input length |
| space | O(L) |

Building a lookup table for three cases would cost more than two comparisons.

Two comparisons and one write cover the whole problem.
