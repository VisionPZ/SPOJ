# MMOD29 — Calculate Pow(2004,X) Mod 29 (SPOJ)

<https://www.spoj.com/problems/MMOD29/>

## Problem

For each X, add up every positive divisor of 2004 raised to the power X and report that sum modulo 29. Reading lines stops at X = 0.

Each non-zero input line holds one integer X. Each output line holds one integer from 0 to 28. The final line holds 0, which produces no output.

| item | bound |
|---|---|
| exponent X | 1 to 10000000 |
| terminator | 0 |
| output values | 0 to 28 |
| judge limit | 1000 ms, 1536 MB |

The exponent drives the cost: 2004 equals 2 squared times 3 times 167.

Sample input:

```
1
10000
0
```

Sample output:

```
6
10
```

## Idea

Factor 2004 once, then treat each prime separately, like adding the rungs of three ladders and multiplying the totals. A divisor sum of a prime power is a short geometric series, and fast exponentiation finds its top term. Multiplying three small residues gives the answer in constant work per test.

| step | cost |
|---|---|
| factor 2004 once | constant |
| power modulo 29 | logarithmic in X |
| multiply three residues | constant |

A direct divisor enumeration would build 2004 to the power X, which has tens of millions of factors. Precomputed residues avoid that growth.

## Why It Works

1. Since 2004 equals 2 squared times 3 times 167, its X-th power has prime exponents 2X, X and X.
2. The divisor sum of p to the power k equals 1 plus p plus p squared up to p to the power k.
3. That series equals p to the power k+1 minus 1, divided by p minus 1.
4. Modulo 29 the division becomes multiplication by the modular inverse, because p minus 1 is never a multiple of 29.
5. Divisor sums multiply for coprime prime powers, so the three residues multiply to the answer.

| term | meaning |
|---|---|
| `powerMod` | fast modular exponentiation for one prime |
| `inverseMod` | modular inverse using Fermat's little theorem |
| `divisorSumModulo` | divisor sum of one prime power modulo 29 |
| `solveCase` | product of the three divisor sums |

The table names one helper for each algebraic step.

A script-generated trace for X = 1:

```
prime 2, exponent 2: 1 + 2 + 4 = 7
prime 3, exponent 1: 1 + 3 = 4
prime 167, exponent 1: 1 + 167 = 168
product 7 * 4 * 168 = 4704
4704 mod 29 = 6
```

The trace reconstructs the 12 divisors of 2004 listed in the statement and matches the sample.

## Code

**Hand scanner and buffered output.** One read pass loads the input, and one string buffers all answers.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 29
const exponentOffset = 1
const exponentSkip = 2

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

The scanner skips any spacing between numbers.
The buffer flushes after 131072 bytes, not after each line.
Both helpers match the shared repository pattern.

**Modular arithmetic.** Fast exponentiation and Fermat inversion keep every intermediate small.

```nim
proc powerMod(baseNumber: int, exponentValue: int, modulusNumber: int): int =
  var resultValue = 1
  var currentBase = baseNumber mod modulusNumber
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1) == 1:
      resultValue = (resultValue * currentBase) mod modulusNumber
    currentBase = (currentBase * currentBase) mod modulusNumber
    remainingExponent = remainingExponent shr 1
  return resultValue

proc inverseMod(valueNumber: int, modulusNumber: int): int =
  return powerMod(valueNumber, modulusNumber - exponentSkip, modulusNumber)

proc divisorSumModulo(exponentCount: int, primeBase: int): int =
  let powerValue = powerMod(primeBase, exponentCount + exponentOffset, modulusValue)
  let numeratorValue = (powerValue - 1 + modulusValue) mod modulusValue
  let denominatorValue = (primeBase - 1) mod modulusValue
  let inverseValue = inverseMod(denominatorValue, modulusValue)
  return (numeratorValue * inverseValue) mod modulusValue
```

Squaring halves the exponent count each loop.
Adding the modulus before reduction keeps the numerator non-negative.
The inverse exists because 29 is prime and no denominator is a multiple of 29.

**Answer loop.** Three divisor sums combine for each exponent, then the terminator ends the run.

```nim
proc solveCase(exponentValue: int): int =
  let firstPart = divisorSumModulo(exponentValue * exponentSkip, 2)
  let secondPart = divisorSumModulo(exponentValue, 3)
  let thirdPart = divisorSumModulo(exponentValue, 167)
  return (firstPart * secondPart mod modulusValue) * thirdPart mod modulusValue

while true:
  let exponentValue = nextInt(inputData, scanPos)
  if exponentValue == 0:
    break
  let answerValue = solveCase(exponentValue)
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The exponent of 2 is twice X; the other exponents equal X.
The scanner returns 0 once the input is exhausted.
A final flush writes any partial buffer.

## Complexity

Each exponent costs a fixed number of short modular operations.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| three power modulos | logarithmic in X per line | constant |
| output | one write per block | block buffer |

Three short power loops dominate each line.

| measure | Big O |
|---|---|
| time | O(T log X) for T test lines |
| space | O(input bytes) |

Enumerating divisors of 2004 to the power X would need exponentially many terms in the input size, so the residue formula is the practical choice.
