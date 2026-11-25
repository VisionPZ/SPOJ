# DNEQ — Denver and Emma (SPOJ)

<https://www.spoj.com/problems/DNEQ/>

## Problem

Each case gives a group of men, a gain per man, and one man's old weight. The answer is the old weight plus the total gain over the whole group.

Input starts with the number of cases. Each following line holds N, A and B. The value A may be a decimal such as 1.5. Output one integer per line.

The bounds keep every case tiny.

| item | bound |
|---|---|
| cases t | 1 to 10 |
| men N | 1 to 102 |
| gain A | 1 to 99, possibly one decimal place |
| old weight B | 1 to 99 |
| judge limit | 2000 ms, 1536 MB |

A gain of 1.5 means fifteen tenths, so fixed-point arithmetic keeps the maths exact.

Sample input:

```
2
8 1.5 65
6 3 80
```

Sample output:

```
77
98
```

## Idea

Measure the gain in tenths, like pricing in cents instead of dollars. Multiply the integer count by N, divide back once, then add B.

The real algorithm is fixed-point integer arithmetic. A float product can drift for decimal gains, while scaling stays exact. Only one multiply and one divide are needed per case. The takeaway is to remove the decimal before doing any work.

## Why It Works

1. Write A as a whole count `increaseScaled` over a divisor `increaseDivisor`.
2. For 1.5 the count is 15 and the divisor is 10.
3. Multiplying by N gives the total gain in the same scaled units.
4. Integer division by the divisor returns the whole kilograms gained.
5. Adding `replacedWeight` gives the new man's weight.

| term | meaning |
|---|---|
| `increaseScaled` | gain written as an integer count of tenths |
| `increaseDivisor` | power of ten that turns the count back into kilograms |
| `totalIncrease` | whole kilograms gained by the group |
| `newWeight` | old weight plus the total increase |

The scaled count keeps every step free of rounding error.

For the first sample case N is 8, A is 1.5 and B is 65. The count is 15 and the divisor is 10. Then 8 times 15 is 120, and 120 divided by 10 is 12. Finally 12 plus 65 is 77.

Division truncates any fractional kilogram, which matches the integer output contract. The `int64` product stays safe even at the largest bounds.

## Code

**Input and decimal parsing.** The reader loads the stream and turns A into a scaled integer.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc parseScaledDecimal(data: string, pos: var int, divisorValue: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  var fractionPart = 0
  divisorValue = 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionPart = fractionPart * 10 + int(data[pos]) - firstDigitValue
      divisorValue = divisorValue * 10
      pos += 1
  return wholePart * divisorValue + fractionPart
```

The divisor grows once per fractional digit.
A plain integer A yields a divisor of one.
The scanner skips spaces and line breaks by itself.

**Case loop and buffered output.** Each case produces one line of answer text.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let menCount = nextInt(inputData, scanPos)
  var increaseDivisor = 1
  let increaseScaled = parseScaledDecimal(inputData, scanPos, increaseDivisor)
  let replacedWeight = nextInt(inputData, scanPos)
  let totalIncrease = int64(menCount) * int64(increaseScaled) div int64(increaseDivisor)
  let newWeight = totalIncrease + int64(replacedWeight)
  appendOutput($newWeight)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The product uses `int64` to avoid overflow.
One buffer holds all answers and flushes in blocks.
The final write emits whatever remains.

## Complexity

Each case uses a fixed amount of work.

| phase | time | space |
|---|---|---|
| input read | one pass over the stream | one input string |
| decimal parse | one pass over each A token | constant |
| case loop | one multiply per case | one output buffer |

The counts below describe the whole run.

| measure | Big O |
|---|---|
| time | O(t) |
| space | O(input size) |

Checking every tenth by repeated addition would take far more steps than one multiply. Scaling gives the exact answer with constant work per case.
