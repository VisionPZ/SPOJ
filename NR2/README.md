# NR2 — Bhagat The Bit Man (SPOJ)

<https://www.spoj.com/problems/NR2/>

## Problem

Given a list of admission numbers, report the bitwise OR of the XOR of every pair of numbers in the list. One integer is printed on one line.

Input begins with the count N, followed by N numbers, one per line. Output one line holding the computed integer.

| item | bound |
|---|---|
| number count N | 2 to 1000000 |
| each number | 0 to 1000000000000000000 |
| judge limit | 1000 ms, 1536 MB |

The large count makes a single buffered read important.

Sample input:

```
3
10
15
17
```

Sample output:

```
31
```

The three pair XOR values are 5, 27 and 30, and their OR is 31.

## Idea

A bit lights up in a pair XOR when two switches disagree, and the final OR collects every lit bit across all pairs. Compute the OR and the AND of the whole list, then XOR those two results. Each number costs two bitwise operations in one pass. A pairwise scan would build O(N^2) XOR values, which is far slower. One sweep gives the answer.

## Why It Works

1. A bit in a XOR is set exactly when its two operands differ at that bit.
2. Some pair differs at a bit when the list holds both a zero and a one there.
3. A bit set in the global OR appears in at least one number.
4. A bit clear in the global AND is absent from at least one number.
5. Both conditions hold for exactly the bits that vary, which is the required answer.

The main terms:

| term | meaning |
|---|---|
| `numberCount` | how many numbers the input holds |
| `unionBits` | bitwise OR accumulated over all numbers |
| `intersectionBits` | bitwise AND accumulated over all numbers |
| `scanPos` | current byte position in the input buffer |

The two accumulators together describe every bit that varies.

A script trace of the sample in binary:

```
numbers      01010 01111 10001
unionBits    11111 = 31
intersectionBits 00000 = 0
answer       11111 = 31
```

The bit pattern 11111 matches the sample answer 31.

## Code

**Input and scanning.** The hand reader loads every line into one buffer.

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

The scanner skips separators and builds one value digit by digit.
The loop ends when the input buffer is exhausted.
A million numbers need only one pass over the bytes.

**Single sweep and output.** Two accumulators replace all pair XOR values.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberCount = nextInt(inputData, scanPos)
var unionBits = 0
var intersectionBits = 0
if numberCount > 0:
  let firstNumber = nextInt(inputData, scanPos)
  unionBits = firstNumber
  intersectionBits = firstNumber
for numberIndex in 1 .. numberCount - 1:
  let currentNumber = nextInt(inputData, scanPos)
  unionBits = unionBits or currentNumber
  intersectionBits = intersectionBits and currentNumber
appendOutput($(unionBits xor intersectionBits))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first number seeds both accumulators before the loop.
Each later number updates them with one operation each.
The final XOR is written once through the block buffer.

## Complexity

The sweep reads each number once and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over the input bytes | one input string |
| bitwise sweep | two operations per number | two integers |
| output | one line | block buffer |

The input string dominates memory use.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) for the input buffer |

Enumerating all pairs would take O(N^2) time, while this sweep stays linear.
A single pass over the list is the whole algorithm.
