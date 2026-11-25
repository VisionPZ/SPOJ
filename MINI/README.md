# MINI — MINI IN DANGER!!! (SPOJ)

<https://www.spoj.com/problems/MINI/>

## Problem

Fill an N by N board with values from 0 to N - 1 so every row sum and every column sum is a multiple of N. Count the fillings modulo 1000000009.

Input starts with T, then gives one board order N per case. N ranges up to 2^64 - 1 and never divides the modulus.

Output gives one count per case.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | up to 1000000 |
| board order N | 1 to 2^64 - 1 |
| modulus | 1000000009, prime |
| judge limit | 1000 ms, 1536 MB |

The huge order rules out any direct table of orders.

Sample input:

```
1
1
```

The sample asks for the order 1 board count.

Sample output:

```
1
```

Only the all-zero board works for order 1.

## Idea

Choose the inner cells freely, like filling the middle of a sudoku; the border cells then lock into place. The count collapses to a single power of N.

The method uses the closed form N to the power (N - 1) squared, then fast modular exponentiation. Each digit of N is reduced into two residues, so values near 2^64 stay small. One case costs about 30 modular multiplications.

Enumerating all N to the power N squared fillings is impossible for large N.

## Why It Works

1. Fill the top-left (N - 1) by (N - 1) block with any values: that gives N to the power (N - 1) squared choices.
2. Each of the first N - 1 rows gets one forced last-column value that fixes its row sum.
3. Each of the first N - 1 columns gets one forced last-row value that fixes its column sum.
4. The bottom-right value satisfies both its row sum and its column sum, so no conflict remains.
5. Fermat's rule reduces the exponent modulo 1000000008 because the modulus is prime and N is not a multiple of it.
6. Digit-by-digit reduction computes N modulo the modulus and N modulo 1000000008 without a wide integer type.

The main terms and formulas:

| term | meaning |
|---|---|
| `modulusValue` | the prime modulus 1000000009 |
| `exponentModulus` | the exponent cycle length 1000000008 |
| `nextOrderResidues` | scanner that reduces N into both residues |
| `powerModulo` | binary modular exponentiation |
| `exponentValue` | (N - 1) squared, reduced modulo 1000000008 |

Both residues stay below the modulus, so every product fits in 64 bits.

A script trace over the order 3 board gives:

```
n=3: exponent (n-1)^2 = 4
base 3, exponent 4, power 3^4 = 81
mod 1000000009 = 81
```

The order 3 count is 81, which matches the convolution check.

No rounding applies, since every operation uses integer modular arithmetic.

## Code

**Input and buffer.** One read loads stdin, and answers collect in one string.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = int64(1000000009)
const exponentModulus = int64(1000000008)

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

The scanner reads T as an ordinary integer.
The two constants define the base modulus and exponent cycle.
One buffer serves all output lines.

**Residue parser and power.** Digit reduction avoids a wide integer, and binary exponentiation finishes the count.

```nim
var parsedBaseResidue = int64(0)
var parsedPowerResidue = int64(0)

proc nextOrderResidues(data: string, pos: var int) =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  parsedBaseResidue = 0
  parsedPowerResidue = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    let digitValue = int64(int(data[pos]) - 48)
    parsedBaseResidue = (parsedBaseResidue * 10 + digitValue) mod modulusValue
    parsedPowerResidue = (parsedPowerResidue * 10 + digitValue) mod exponentModulus
    pos += 1

proc powerModulo(baseValue, exponentValue: int64): int64 =
  var resultValue = int64(1)
  var factorValue = baseValue mod modulusValue
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1) == 1:
      resultValue = (resultValue * factorValue) mod modulusValue
    factorValue = (factorValue * factorValue) mod modulusValue
    remainingExponent = remainingExponent div 2
  return resultValue
```

Each scanned digit updates both residues.
Squaring halves the exponent each round.
The bit test multiplies the result only when needed.

**Driver.** The reduced exponent feeds the modular power, and one line is written per case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  nextOrderResidues(inputData, scanPos)
  let reducedOrder = if parsedPowerResidue == 0:
                       exponentModulus - 1
                     else:
                       parsedPowerResidue - 1
  let exponentValue = (reducedOrder * reducedOrder) mod exponentModulus
  appendOutput($powerModulo(parsedBaseResidue, exponentValue))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A zero residue maps to the cycle length minus one.
Squaring the reduced order gives the exponent.
The final write flushes any remaining text.

## Complexity

Work splits into reading, residue reduction, and modular exponentiation.

| phase | time | space |
|---|---|---|
| input read | one pass over the digits | one input string |
| residue reduction | one step per digit | two integers |
| modular power | about 30 squarings per case | constant |
| output | one line per case | block buffer |

The modular power dominates when T is large.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(total digits + T log 1000000009) |
| space | O(1) beyond the input string |

Enumerating every board costs exponential time in N, so the closed form is the only practical route.
