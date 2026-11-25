# IIC12345545 — COMP (SPOJ)

<https://www.spoj.com/problems/IIC12345545/>

## Problem

Read one integer and print its most significant digit. The input contains a single number between 2 and 999.

The contract fixes one number in and one digit out.

| item | bound |
|---|---|
| input | one integer N, with 1 < N < 1000 |
| output | one digit followed by a newline |
| judge limit | 1000 ms, 1536 MB |

Three digits is the widest input the statement allows.

Leading whitespace is harmless because the scanner skips non-digit bytes.

Sample input:

```
123
```

The sample holds one three-digit number.

Sample output:

```
1
```

The output is the first digit of that number.

## Idea

Peel digits off a number like removing onion layers until one digit stays. Division by ten removes the rightmost layer each round.

The real algorithm is repeated integer division. Each round costs one division, so work grows with the digit count. Converting the number to text and inspecting characters adds parsing work that division avoids.

A short loop settles the whole task.

## Why It Works

1. A positive integer holds d digits, and d is at most three here.
2. Dividing by ten drops the rightmost digit and keeps the rest.
3. Repeating that step leaves one digit, the most significant one.
4. The loop stops when the value falls below ten.

Each name below maps to one part of the loop.

| term | meaning |
|---|---|
| `inputNumber` | the integer read from the input |
| `leadingDigit` | the shrinking value that ends as the answer |
| `firstDigitValue` | forty-eight, the code offset for digit zero |

These names keep the loop easy to follow.

Script-generated example:

```
123 -> 12 -> 1
999 -> 99 -> 9
```

The last value in each row is the printed digit.

No rounding occurs because every division drops a whole digit. The guard at ten stops the loop before the value reaches zero.

## Code

**Input and buffered output.** The reader collects all stdin, then the scanner picks the first integer.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips every non-digit byte. It builds the value one digit at a time. Output waits in one buffer until the final write.

**Leading digit and final write.** Division strips digits until one remains.

```nim
let inputNumber = nextInt(inputData, scanPos)
var leadingDigit = inputNumber
while leadingDigit >= 10:
  leadingDigit = leadingDigit div 10
appendOutput($leadingDigit)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs at most three times for this input. The answer is written with one trailing newline. The final flush empties the buffer.

## Complexity

The division loop is the only repeated work.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| leading digit | one division per digit | constant |
| output | one line | block buffer |

Every phase stays tiny because N has at most three digits.

| measure | Big O |
|---|---|
| time | O(d) for d input digits |
| space | O(I) for I input bytes |

I counts the bytes read from stdin.

Scanning text and comparing characters would add work this loop never needs. The division loop alone gives the answer.
