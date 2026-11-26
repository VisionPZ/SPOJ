# NUMPDROM — Palindrom of Number (SPOJ)

<https://www.spoj.com/problems/NUMPDROM/>

## Problem

Read one integer and decide whether it reads the same backwards. Print `YA` for yes and `TIDAK` for no.

The input is a single integer n with n < 100000. The output is one word on its own line.

| item | bound |
|---|---|
| n | n < 100000 |
| output | `YA` or `TIDAK` |
| judge limit | 1000 ms, 1536 MB |

Reversing the digits once answers the question.

Sample input:

```
1221
```

Sample output:

```
YA
```

## Idea

A word is a palindrome when it matches its mirror image. The program builds the digit-reverse of the number by peeling the last digit onto the front of a new value, then compares the two.

No string handling or array storage is needed; plain arithmetic does the mirror.

Takeaway: reverse by arithmetic, then compare.

## Why It Works

1. `remaining mod 10` gives the current last digit.
2. Shifting the reversed value left by one place and adding that digit grows the mirror correctly.
3. `remaining div 10` drops the digit that was just copied.
4. The loop ends when every digit has been copied, so the mirror is complete.
5. Equal numbers mean the digit sequence reads the same both ways.

For the sample, 1221 reverses to 1221, so the answer is `YA`.

A number ending in zero, such as 10, reverses to 1 and is not a palindrome, which the comparison catches.

## Code

**Input and scanning.** The hand reader loads the file and parses one integer.

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

The scanner skips spaces and newlines.
Every value is positive, so no minus branch is needed.

**Buffered output.** One string collects the answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Digit mirror.** The reverse is built one digit at a time.

```nim
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

Each turn moves one digit from the back of the source to the back of the mirror.
The loop stops when the source is empty.
The two words are the exact answers from the statement.

## Complexity

The mirror loop runs once per digit.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| reverse | one step per digit | none |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O(digits of n) |
| space | O(1) |

Comparing digit by digit from both ends would need the number stored as text.

Takeaway: one arithmetic reversal settles the question.
