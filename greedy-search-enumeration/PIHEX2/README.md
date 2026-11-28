# PIHEX2 — Hexadecimal value of Pi (SPOJ)

<https://www.spoj.com/problems/PIHEX2/>

## Problem

Report one hexadecimal digit of pi for each requested position. Position zero is the leading 3; position one is the first digit after the point. Positions reach one million.

| item | bound |
|---|---|
| test cases t | 1 to 20 |
| position ai | 0 to 1000000 |
| judge limit | 5000 ms, 1536 MB |

Use capital letters A through F for digits ten through fifteen. The four positions in the sample include the millionth digit.

Sample input:

```
16
0 1 2 3 4 5 6 7 8 9 10 100 1000 10000 100000 1000000
```

Sample output:

```
3243F6A8885C3652
```

## Idea

Extract one digit from pi without computing all earlier digits, like reading a single page number from a book by formula instead of turning every page. The BBP series expresses pi as a sum of powers of 1/16 with small rational coefficients. Multiplying by 16 to the requested power shifts the wanted digit to the ones place. Modular exponentiation removes the large integer part of each term.

Sum the four rational pieces in floating point, take the fractional part, and read its first hex digit.

## Why It Works

1. BBP writes pi as the sum over k of 16 to the power negative k times a rational combination.
2. The combination is 4/(8k+1) − 2/(8k+4) − 1/(8k+5) − 1/(8k+6).
3. For position a, use exponent a − 1 and multiply the whole series by 16 to that exponent.
4. For k up to the exponent, 16 to a nonnegative power modulo the denominator gives the fraction part of that term.
5. Terms beyond the exponent are tiny; forty tail terms bound the error well below one hex digit.
6. Four times the fraction part gives the wanted hex digit after removing the integer part.

| term | meaning |
|---|---|
| exponentValue | position minus one, the shift applied to pi |
| coefficientDenominators | the values 1, 4, 5, 6 in BBP |
| coefficientValues | the multipliers 4, −2, −1, −1 |
| tailFactor | current power of 1/16 for the ignored tail |

For position 1, the k = 0 terms give −0.5 − 0.2 − 0.1667 and the tail adds about 0.0082. The fraction part is about 0.1415, and 16 times that is 2.26. The digit is 2.

## Code

**Input and scanning.** The reader takes t and then all positions.

```nim
const flushBlockBytes = 1 shl 17
const coefficientDenominators = [1, 4, 5, 6]
const coefficientValues = [4.0, -2.0, -1.0, -1.0]
const tailTerms = 30

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

The scanner skips the line break between the two input lines.
Each position is read as a plain integer.

**Modular powers.** Binary exponentiation keeps every product below a 64-bit word.

```nim
proc powerMod(baseValue: int64, exponentValue: int, modulusValue: int64): int64 =
  if modulusValue == 1:
    return 0
  var result: int64 = 1
  var factor = baseValue mod modulusValue
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      result = result * factor mod modulusValue
    factor = factor * factor mod modulusValue
    remaining = remaining shr 1
  return result
```

Denominators stay below eight million, so squaring fits in int64.
A zero modulus result returns zero because the fraction part is zero.

**Digit extraction.** Four rational sums combine into one hex digit.

```nim
proc piHexDigit(position: int): char =
  if position == 0:
    return '3'
  let exponentValue = position - 1
  var coefficientSums: array[4, float64]
  for step in 0 .. exponentValue:
    let remainingPower = exponentValue - step
    for slot in 0 .. 3:
      let modulusValue = int64(8 * step + coefficientDenominators[slot])
      let modularValue = powerMod(16, remainingPower, modulusValue)
      coefficientSums[slot] = coefficientSums[slot] + coefficientValues[slot] * float64(modularValue) / float64(modulusValue)
  var tailFactor = 1.0 / 16.0
  for tailStep in exponentValue + 1 .. exponentValue + tailTerms:
    for slot in 0 .. 3:
      let denominatorValue = float64(8 * tailStep + coefficientDenominators[slot])
      coefficientSums[slot] = coefficientSums[slot] + coefficientValues[slot] * tailFactor / denominatorValue
    tailFactor = tailFactor / 16.0
  var fractionalPart = 0.0
  for slot in 0 .. 3:
    fractionalPart = fractionalPart + coefficientSums[slot]
  while fractionalPart < 0.0:
    fractionalPart = fractionalPart + 1.0
  while fractionalPart >= 1.0:
    fractionalPart = fractionalPart - 1.0
  var digitValue = int(fractionalPart * 16.0)
  if digitValue > 15:
    digitValue = 15
  if digitValue < 10:
    return char(ord('0') + digitValue)
  return char(ord('A') + digitValue - 10)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCaseCount = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let requestedPosition = nextInt(inputData, scanPos)
  appendOutput($piHexDigit(requestedPosition))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The main loop visits k only up to the requested exponent.
Thirty tail terms settle the fractional part before digit selection.
All answer digits share one output line and one buffer.

## Complexity

Modular exponentiation dominates each step of the series.

| phase | time | space |
|---|---|---|
| input read | one pass over t positions | one input string |
| series sum | a log exponent modular cost per term | four accumulators |
| digit write | one character per position | block buffer |

| measure | Big O |
|---|---|
| time per position | O(a log a) |
| space | O(1) besides input |

Computing every earlier hex digit would cost O(a²) work per query.

The BBP shift reads the wanted digit directly from modular remainders.
