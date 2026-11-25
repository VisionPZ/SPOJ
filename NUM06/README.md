# NUM06 — GCD!!! (SPOJ)

<https://www.spoj.com/problems/NUM06/>

## Problem

For each pair of numbers, report their greatest common divisor. Reading stops when both numbers are zero.

The input is a stream of pairs, one pair per line. Print one divisor per pair until the stopping pair.

| item | bound |
|---|---|
| number pair | 1 to 1000000000000000000 |
| stopping pair | 0 0 |
| judge limit | 1000 ms, 1536 MB |

Library gcd functions are not allowed, so the division steps are written by hand.

Sample input:

```
5 6
3 9
10 2
0 0
```

Sample output:

```
1
3
2
```

## Idea

Shrink the pair by division, like trimming a rope to the shorter piece and the leftover cut. Replacing the larger number by the remainder keeps every common divisor and loses nothing else. Repeat until one number is zero. That survivor is the greatest common divisor.

## Why It Works

1. Any common divisor of two numbers also divides their remainder.
2. Replacing a number by the remainder preserves the set of common divisors.
3. The numbers never grow, so the loop must end.
4. When the second number is zero, the first holds the greatest common divisor.

| term | meaning |
|---|---|
| `leftValue` | current first number in the shrinking pair |
| `rightValue` | current second number in the shrinking pair |
| `remainder` | leftover after dividing the first by the second |

The values are int64 because they reach one quintillion.

Script-generated trace for the first sample pair:

```
left | right | remainder
5 | 6 | 5
6 | 5 | 1
5 | 1 | 0
1 | 0 | stop
```

The survivor is 1, matching the first sample answer.

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

All pairs are parsed from one buffer.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Euclid loop and output.** Repeated remainders shrink the pair.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

while true:
  let firstValue = int64(nextInt(inputData, scanPos))
  let secondValue = int64(nextInt(inputData, scanPos))
  if firstValue == 0 and secondValue == 0:
    break
  appendOutput($greatestCommonDivisor(firstValue, secondValue))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The stopping pair ends the loop.
Each step costs one division.
Every answer is one buffered line.

## Complexity

Each division removes at least one binary digit of work.

| phase | time | space |
|---|---|---|
| input read | one pass over all pairs | one input string |
| gcd loop | O(log min value) divisions | two variables |
| output | one line per pair | block buffer |

No table of divisors is built.

| measure | Big O |
|---|---|
| time | O(number of pairs times log value) |
| space | O(1) apart from buffers |

Testing every candidate divisor up to the smaller value would cost O(min value) per pair.
