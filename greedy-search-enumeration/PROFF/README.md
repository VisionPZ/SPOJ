# PROFF — Professor Farouk Question (SPOJ)

<https://www.spoj.com/problems/PROFF/>

## Problem

Count the digit positions that produce a carry when two unsigned integers are added from right to left. Report each count in words and stop when both numbers are zero.

Each input line holds two unsigned integers with fewer than ten digits. The final line holds `0 0` and produces no output. For each earlier line, print `No carry operation.`, `1 carry operation.`, or the count followed by ` carry operations.` The words and the final period are exact.

| Item | Bound |
|---|---|
| Numbers per line | 2 |
| Digits per number | at most 9 |
| Input length | unbounded, ends at 0 0 |
| Judge limit | 2000 ms, 1536 MB |

The digit count drives the work; the number of input lines drives the output size.

Sample input:

```
123 456
555 555
123 594
0 0
```

The sample has three real cases followed by the terminator.

Sample output:

```
No carry operation.
3 carry operations.
1 carry operation.
```

Each answer takes one line in the same order as the input.

## Idea

A carry passes to the next digit like a baton passed down a row of runners. Walk both numbers from the last digit to the first and keep one carry flag.

The algorithm is a right-to-left digit scan. Each step reads two remainders by ten, adds the incoming carry, and records whether the sum reaches ten. Division by ten moves to the next digit. A full big-integer addition would need arbitrary precision storage and a final comparison; this scan needs only a counter and a flag.

Takeaway: count carries while dividing, never while building a sum.

## Why It Works

1. Decimal addition processes digits from least significant to most significant.
2. A position carries exactly when the digit sum plus the incoming carry reaches ten.
3. The outgoing carry is zero or one, so one flag carries all needed history.
4. Dividing both numbers by ten discards the processed digit and advances one place.
5. The scan ends when both numbers reach zero, including any final carry digit.
6. The singular and plural output forms follow the exact count.

| Term | Meaning |
|---|---|
| `digitSum` | two current digits plus `carryDigit` |
| `carryDigit` | one for an outgoing carry, zero otherwise |
| `carryCount` | number of positions that produced a carry |
| `leftNumber` | remaining digits of the first operand |

The table shows that each step needs only two remainders and one flag.

A script-generated trace of the sample:

```
123 + 456: 3+6=9 -> carry 0; 2+5=7 -> carry 0; 1+4=5 -> carry 0; carries 0
555 + 555: 5+5=10 -> carry 1; 5+5+1=11 -> carry 1; 5+5+1=11 -> carry 1; carries 3
123 + 594: 3+4=7 -> carry 0; 2+9=11 -> carry 1; 1+5+1=7 -> carry 0; carries 1
```

The trace reproduces the three sample answers in order.

The largest case adds nine digits of nines plus one, which carries at every position. The counter stays small, so plain integers hold it.

## Code

**Input and scanner.** The reader loads every line, and the scanner skips spaces and line breaks.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`scanPos` advances past each number. The buffer flushes only after many lines. This block runs once.

**Carry scan and formatted output.** Each pair is reduced digit by digit until both operands vanish.

```nim
while scanPos < inputData.len:
  let firstNumber = nextInt(inputData, scanPos)
  let secondNumber = nextInt(inputData, scanPos)
  if firstNumber == 0 and secondNumber == 0:
    break
  var carryCount = 0
  var carryDigit = 0
  var leftNumber = firstNumber
  var rightNumber = secondNumber
  while leftNumber > 0 or rightNumber > 0:
    let digitSum = leftNumber mod 10 + rightNumber mod 10 + carryDigit
    if digitSum >= 10:
      carryCount += 1
      carryDigit = 1
    else:
      carryDigit = 0
    leftNumber = leftNumber div 10
    rightNumber = rightNumber div 10
  if carryCount == 0:
    appendOutput("No carry operation.\n")
  elif carryCount == 1:
    appendOutput("1 carry operation.\n")
  else:
    appendOutput($carryCount)
    appendOutput(" carry operations.\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The pair `0 0` breaks before any output. The plural branch adds the count and the tail text separately. One final flush ends the run.

## Complexity

Each input pair costs one pass over its digits, and output goes through one block buffer.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all lines | one input string |
| Carry scan | up to 9 steps per pair | a few integers |
| Output | one append per case | block buffer |

The phase table shows that cost grows with input size, not with integer size.

| Measure | Big O |
|---|---|
| Time | O(total input digits) |
| Space | O(input size) |

Building arbitrary-precision sums would add storage and a full digit-by-digit result pass. The baton scan stops after counting carries.
