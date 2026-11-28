# OPNDYSTF — Choosing staff to work on open days (SPOJ)

<https://www.spoj.com/problems/OPNDYSTF/>

## Problem

Count the ways to choose a group of ambassadors from a larger pool. The answer is the number of unordered selections of the required size.

Input is a single line with two integers `N` and `R`, with `R < N < 200`.

Output is a single integer: the binomial coefficient `N choose R`.

| item | bound |
|---|---|
| pool size N | less than 200 |
| group size R | less than N |
| answer size | up to about 59 digits |
| judge limit | 1000 ms, 1536 MB |

The answer exceeds 64 bits, so the calculation needs multiple machine words.

Sample input:

```
10 3
```

Sample output:

```
120
```

## Idea

Build the answer one factor at a time, like climbing a staircase while paying each step immediately. Multiply by the next numerator term, then divide by the step number so the value is always a whole binomial coefficient.

Store the number in base one billion limbs, which gives nine decimal digits per limb. Each multiply and divide touches only a few limbs, since N stays below 200. The exact division works because the running value is the binomial coefficient of the current prefix.

Multiply, divide exactly, and repeat for the smaller of R and N-R steps.

## Why It Works

1. The number of unordered groups is the binomial coefficient `N! / (R! * (N-R)!)`.
2. The coefficient grows by `(N-k+1)/k` when the chosen count grows from `k-1` to `k`.
3. Each intermediate value is itself a binomial coefficient, so the division has no remainder.
4. Using `min(R, N-R)` steps shortens the loop without changing the answer.
5. Base one billion limbs keep every limb product below 2^63.

| term | meaning |
|---|---|
| `totalStaff` | the pool size N |
| `neededStaff` | the group size R |
| `chooseCount` | the smaller of R and N-R |
| `combinationValue` | the running big integer |
| `bigBase` | ten to the ninth power, the limb base |

For `N = 10` and `R = 3`, the steps are `10/1`, `9/2`, and `8/3`. They give `10`, `45`, and `120`, matching the sample.

Print the highest limb first, then pad every lower limb to nine digits.

## Code

**Input and big-integer helpers.** The reader loads both sizes and defines limb arithmetic.

```nim
const flushBlockBytes = 1 shl 17
const bigBase: int64 = 1000000000

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

proc trimBig(value: var seq[int64]) =
  while value.len > 1 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc multiplySmall(value: var seq[int64], factor: int64) =
  var carry: int64 = 0
  for limbIndex in 0 .. value.len - 1:
    let current = value[limbIndex] * factor + carry
    value[limbIndex] = current mod bigBase
    carry = current div bigBase
  while carry > 0:
    value.add carry mod bigBase
    carry = carry div bigBase

proc divideSmall(value: var seq[int64], divisor: int64) =
  var carry: int64 = 0
  var limbIndex = value.len - 1
  while limbIndex >= 0:
    let current = value[limbIndex] + carry * bigBase
    value[limbIndex] = current div divisor
    carry = current mod divisor
    limbIndex -= 1
  trimBig(value)

proc paddedLimb(limb: int64): string =
  result = $limb
  while result.len < 9:
    result = "0" & result

proc bigToString(value: seq[int64]): string =
  result = $value[value.len - 1]
  var limbIndex = value.len - 2
  while limbIndex >= 0:
    result = result & paddedLimb(value[limbIndex])
    limbIndex -= 1
```

A limb holds nine decimal digits.
Carries move from low limb to high limb on multiplication.
Division moves the carry the other way and trims empty top limbs.

**Binomial loop.** Each step multiplies by one numerator term and divides by the step index.

```nim
let totalStaff = nextInt(inputData, scanPos)
let neededStaff = nextInt(inputData, scanPos)
var chooseCount = neededStaff
if totalStaff - neededStaff < chooseCount:
  chooseCount = totalStaff - neededStaff
var combinationValue = newSeq[int64](1)
combinationValue[0] = 1
var factorCursor = 1
while factorCursor <= chooseCount:
  multiplySmall(combinationValue, int64(totalStaff - chooseCount + factorCursor))
  divideSmall(combinationValue, int64(factorCursor))
  factorCursor += 1
appendOutput(bigToString(combinationValue) & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The smaller side of the coefficient sets the loop count.
Every division is exact because the value stays a binomial coefficient.
The final digits pass through the block buffer.

## Complexity

Each step touches every limb of the running number, and the limb count grows slowly.

| phase | time | space |
|---|---|---|
| input read | two integers | one input string |
| binomial loop | min(R,N-R) limb updates | a few limbs |
| output | one line | block buffer |

The limb count stays below seven for the given bound.

| measure | Big O |
|---|---|
| time | O(min(R,N-R) * D) with D the limb count |
| space | O(D) |

A factorial-first approach would build huge intermediate values that never divide evenly until the end.

Multiply and divide in step, and store the result in base one billion limbs.
