# LOCKER — Magic of the locker (SPOJ)
<https://www.spoj.com/problems/LOCKER/>

## Problem

Cut a rope of length n into integer pieces and report the largest product of the piece lengths, modulo 1000000007. The locker multiplies each new piece length into the running total, so the final money equals the product of the pieces.

Input starts with t, the number of test cases. Each of the next t lines holds one integer n. Print one answer per line.

| item | bound |
|---|---|
| test cases t | below 100000 |
| rope length n | 1 to 999999999999 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
2
4
5
```

Sample output:

```
4
6
```

## Idea

Pieces of length three earn the most, like cutting a ribbon into the longest useful segments that still fit. The optimal split uses only twos and threes, since a piece of five or more can be split into better pieces. Compute the power of three with binary exponentiation, then handle the remainder with a small correction. Each test costs O(log n) multiplications, while trying every split would cost O(n). The takeaway is to trade a long search for one power and one correction.

## Why It Works

1. A piece of length five or more improves when cut into a three and a smaller piece.
2. A remainder of one makes a lone one, so replace three plus one with two plus two.
3. A remainder of two calls for a single two beside the threes.
4. Binary exponentiation computes the large power of three in a few steps.

| term | meaning |
|---|---|
| `ropeLength` | the length n of the rope |
| `powerModulo` | binary exponentiation under `answerModulus` |
| `answerValue` | the largest product for one rope |
| `remainingExponent` | bits still to process in the exponent |

A short script generated these products by trying every split:

| n | best split | product |
|---|---|---|
| 4 | 2 + 2 | 4 |
| 5 | 2 + 3 | 6 |
| 6 | 3 + 3 | 9 |
| 10 | 3 + 3 + 4 | 36 |

The row for ten matches four times three squared.

## Code

**Input and exponentiation.** The reader loads all numbers and the power helper reduces each product under the modulus.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus: int64 = 1000000007'i64

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

proc powerModulo(baseValue: int64, exponentValue: int64): int64 =
  var resultValue: int64 = 1
  var currentBase = baseValue mod answerModulus
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1'i64) == 1'i64:
      resultValue = (resultValue * currentBase) mod answerModulus
    currentBase = (currentBase * currentBase) mod answerModulus
    remainingExponent = remainingExponent shr 1
  return resultValue
```

Each base stays below the modulus.
The loop examines one exponent bit at a time.
The product of two reduced values fits in a signed 64-bit integer.

**Answer selection.** The driver splits each length by its remainder modulo three.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let ropeLength = int64(nextInt(inputData, scanPos))
  var answerValue: int64
  if ropeLength <= 3:
    answerValue = ropeLength
  elif ropeLength mod 3 == 0:
    answerValue = powerModulo(3'i64, ropeLength div 3)
  elif ropeLength mod 3 == 1:
    answerValue = (4'i64 * powerModulo(3'i64, (ropeLength - 4'i64) div 3)) mod answerModulus
  else:
    answerValue = (2'i64 * powerModulo(3'i64, (ropeLength - 2'i64) div 3)) mod answerModulus
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Lengths up to three are their own best split.
The correction factor is four or two.
Buffered writes keep the output path fast.

## Complexity

The table lists work for one rope length.

| phase | time | space |
|---|---|---|
| input read | one pass over all numbers | one input string |
| power | one square per exponent bit | constant |
| output | one buffered line | block buffer |

The bound counts operations for one test case.

| measure | Big O |
|---|---|
| time per test | O(log n) |
| space | O(1) |

Trying every possible split would take O(n) per test instead.
The takeaway is that one power replaces a full search.
