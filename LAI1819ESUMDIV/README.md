# LAI1819ESUMDIV — Somma e dividi (SPOJ)

<https://www.spoj.com/problems/LAI1819ESUMDIV/>

## Problem

Read five integers and split their sum: an even sum is divided by 2, an odd sum by 5. The same five-number grouping repeats for the whole input, so the program handles every group it finds.

Input is a stream of integers, one per line, with each group of five forming one case. Output one decimal number per group, printed with a single digit after the point.

| item | bound |
|---|---|
| integers per group | 5 |
| input value range | 0 to 1000000000 in generated cases |
| output form | one fractional digit |
| judge limit | 1000 ms, 1536 MB |

The fixed group size keeps the arithmetic constant time.

Sample input:

```
2
2
2
2
2
```

Sample output:

```
5.0
```

## Idea

Add the five numbers, then pick the divisor from parity, like splitting a bill between two friends when the total is even and five friends when it is odd. The grouping-and-division algorithm reads five tokens, sums them, and writes the quotient with one decimal digit. A floating-point division could print extra digits or a different rounding; exact integer scaling keeps the one-digit form. The takeaway is to decide the divisor first, then format the integer quotient by hand.

## Why It Works

1. Five consecutive tokens form one group and give one output line.
2. An even total divided by 2 always has a remainder of 0 or 1, so its fractional digit is 0 or 5.
3. An odd total divided by 5 has a remainder from 0 to 4, so its fractional digit is 0, 2, 4, 6 or 8.
4. Multiplying the remainder by 10 divided by the divisor produces exactly that digit.
5. A negative total uses absolute values for the split and keeps the minus sign in front.

| term | meaning |
|---|---|
| `groupTotal` | sum of the current group of five integers |
| `divisor` | 2 for an even sum, 5 for an odd sum |
| `wholePart` | integer part of the quotient |
| `fractionalDigit` | single digit after the decimal point |

The decimal text follows from integer division alone, so no rounding step is needed.

A script-generated example:

```
numbers [1, 2, 4, 6, 8]
sum 21 odd? True
divisor 5 result 4.2
```

The sum 21 is odd, so division by 5 gives 4 whole units and the remainder 1 becomes digit 2.

## Code

**Input and scanning.** The hand reader loads one integer at a time and accepts a minus sign.

```nim
const flushBlockBytes = 1 shl 17
const numbersPerGroup = 5
const evenDivisor = 2
const oddDivisor = 5
const decimalBase = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int, value: var int64): bool =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return false
  var negative = false
  if data[pos] == '-':
    negative = true
    pos += 1
  var magnitude: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    magnitude = magnitude * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    value = -magnitude
  else:
    value = magnitude
  return true
```

The scanner skips line breaks, so the five input lines arrive as five tokens.
A missing token ends the scan before an incomplete group is written.
Magnitude accumulation uses `int64` to keep large values exact.

**Grouping and output.** Each group chooses a divisor and writes one decimal line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  var groupTotal: int64 = 0
  var numbersRead = 0
  for numberIndex in 0 .. numbersPerGroup - 1:
    var currentValue: int64 = 0
    if not nextInt(inputData, scanPos, currentValue):
      break
    groupTotal = groupTotal + currentValue
    numbersRead += 1
  if numbersRead == 0:
    break
  var divisor = oddDivisor
  if groupTotal mod evenDivisor == 0:
    divisor = evenDivisor
  var magnitude = groupTotal
  var sign = ""
  if magnitude < 0:
    sign = "-"
    magnitude = -magnitude
  let wholePart = magnitude div int64(divisor)
  let remainder = magnitude mod int64(divisor)
  let fractionalDigit = remainder * int64(decimalBase div divisor)
  appendOutput(sign & $wholePart & "." & $fractionalDigit & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop reads at most `numbersPerGroup` tokens before choosing the divisor.
The remainder scaled by `decimalBase div divisor` gives the printed digit.
One buffered write per group keeps output ordering intact.

## Complexity

Each group costs a fixed number of reads, sums and writes.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | input string |
| group arithmetic | five additions and one division per group | a few scalars |
| output | one line per group | block buffer |

The work grows directly with the number of input integers.

| measure | Big O |
|---|---|
| time | O(n) over all input integers |
| space | O(1) beyond the input string |

A float-based version would need formatting fixes; integer scaling keeps this linear pass exact.
