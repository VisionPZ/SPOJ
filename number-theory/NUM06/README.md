# NUM06 — GCD!!! (SPOJ)

<https://www.spoj.com/problems/NUM06/>

## Problem

Each line holds two positive integers m and n, up to 10^18. Print their greatest common divisor, one answer per line. A line `0 0` ends the input.

| item | bound |
|---|---|
| m, n | 1 ≤ m, n ≤ 10^18 |
| end marker | `0 0` |
| judge limit | 1000 ms, 1536 MB |

Euclid's algorithm needs only a few dozen steps per pair.

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

Shrinking two numbers by trading the bigger for its remainder keeps the common divisor fixed. Euclid's algorithm repeats this trade until the remainder is zero; the last number standing is the gcd.

For 10^18 the chain of remainders is short, so each line is answered almost instantly.

Takeaway: the remainder trade is the fastest known way to a gcd.

## Why It Works

1. Any common divisor of a and b also divides a mod b, and vice versa, so the gcd never changes.
2. The second number strictly shrinks each turn, so the loop ends.
3. When the second number is 0, the first is the gcd.
4. The `0 0` line is checked before any output, so it produces no answer.

For the sample, gcd(5, 6) = 1, gcd(3, 9) = 3, gcd(10, 2) = 2.

A pair where one value is 0 but the other is not still prints the nonzero value, which is the correct gcd.

## Code

**Input and scanning.** The hand reader loads the file and parses integers.

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
On a 64-bit build `int` holds values up to 10^18.

**Buffered output.** One string collects the answer lines.

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

**Euclid loop.** Remainders replace the larger value.

```nim
proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue
```

Each turn swaps in the smaller, smaller pair.
The loop returns when the right side hits zero.

**Line driver.** Pairs are read until the stop marker.

```nim
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

The break happens before any output for `0 0`.
Every other pair writes exactly one line.

## Complexity

Each pair runs a short Euclid chain.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| gcd | remainder steps per pair | none |
| output | one line per pair | one block buffer |

| measure | Big O |
|---|---|
| time | O(P log min(m, n)) for P pairs |
| space | O(P) output, O(1) work |

Trial division up to sqrt would be far too slow for 10^18.

Takeaway: Euclid answers each query in logarithmic steps.
