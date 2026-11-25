# SUMSUMS — Summing Sums (SPOJ)

<https://www.spoj.com/problems/SUMSUMS/>

## Problem

Each cow holds a number. One round replaces every number by the sum of all other numbers, taken modulo 98,765,431. Report all numbers after T rounds.

Input holds one test. Line 1 gives N and T. The next N lines give the starting numbers. Output holds N lines, one final number per cow.

| item | bound |
|---|---|
| cows N | 1 to 50,000 |
| rounds T | 1 to 1,414,213,562 |
| starting number | 0 to 89,999,999 |
| judge limit | 1000 ms, 1536 MB |

The large round count rules out step-by-step simulation.

Sample input and output:

```
3 4
1
0
4
```

```
26
25
29
```

Four rounds turn (1, 0, 4) into (26, 25, 29).

## Idea

A round is a reflection around the herd total, like swapping seats across a table while the table itself rotates. Binary exponentiation evaluates the rotation after T rounds, and one modular inverse removes the leftover division.

The closed form is c_i(T) = A times S0 plus the sign times c_i(0), where S0 is the starting sum. The coefficient A needs one fast power and one inverse. Each cow then costs a single multiply and add. Naive simulation needs T rounds over N cows, which never finishes for large T.

One shared coefficient serves every cow in the herd.

## Why It Works

1. Let S(t) be the herd total after t rounds. Round t+1 gives cow i the value S(t) - c_i(t).
2. Summing that rule over all cows gives S(t+1) = (N-1) times S(t) modulo M.
3. Write c_i(t) as a_t times S0 plus b_t times c_i(0). The starting values are a_0 = 0 and b_0 = 1.
4. The recurrence gives b_{t+1} = -b_t, so b_t is the sign (-1)^t.
5. Solving the a recurrence gives a_t = ((N-1)^t - (-1)^t) divided by N.
6. N is smaller than the prime M, so its modular inverse exists.

| term | meaning |
|---|---|
| `modulusValue` | M = 98,765,431, the arithmetic modulus |
| `repeatCount` | T, the number of rounds to apply |
| `neighborPower` | (N-1)^T modulo M, computed by fast power |
| `signValue` | (-1)^T as 1 or M-1 |
| `coefficient` | a_T, the shared multiplier of the starting sum |
| `initialTotal` | S0, the sum of all starting numbers |

The table names every value in the closed form.

A scripted trace of the sample uses N = 3, T = 4 and S0 = 5.

```
neighborPower = 2^4 = 16
signValue = 1
coefficient = (16 - 1) / 3 = 5
cow 1 = 5*5 + 1*1 = 26
cow 2 = 5*5 + 1*0 = 25
cow 3 = 5*5 + 1*4 = 29
```

The trace reproduces all three lines of the sample output.

## Code

**Input and digit scanning.** The reader loads the whole input and parses integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = int64(98765431)

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

The scanner skips every separator, including line breaks.
Values stay positive, so no minus branch is needed.
One pass fills `inputData` once.

**Modular helpers.** Fast power handles T and Euclid handles the division by N.

```nim
proc powerMod(baseValue, exponentValue: int64): int64 =
  var resultValue = int64(1)
  var currentBase = baseValue mod modulusValue
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1) == 1:
      resultValue = resultValue * currentBase mod modulusValue
    currentBase = currentBase * currentBase mod modulusValue
    remainingExponent = remainingExponent shr 1
  return resultValue

proc modularInverse(value: int64): int64 =
  var oldRemainder = value mod modulusValue
  var newRemainder = modulusValue
  var oldCoeff = int64(1)
  var newCoeff = int64(0)
  while newRemainder != 0:
    let quotient = oldRemainder div newRemainder
    let nextRemainder = oldRemainder - quotient * newRemainder
    oldRemainder = newRemainder
    newRemainder = nextRemainder
    let nextCoeff = oldCoeff - quotient * newCoeff
    oldCoeff = newCoeff
    newCoeff = nextCoeff
  return (oldCoeff mod modulusValue + modulusValue) mod modulusValue
```

Exponentiation runs in O(log T) steps.
The inverse uses the extended Euclid identity.
Both helpers work entirely in int64.

**Shared coefficient and output.** One coefficient turns each starting value into its answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let cowCount = nextInt(inputData, scanPos)
let repeatCount = int64(nextInt(inputData, scanPos))
var cowValues = newSeq[int64](cowCount)
var initialTotal = int64(0)
for cowIndex in 0 .. cowCount - 1:
  cowValues[cowIndex] = int64(nextInt(inputData, scanPos)) mod modulusValue
  initialTotal = (initialTotal + cowValues[cowIndex]) mod modulusValue
let neighborBase = int64(cowCount - 1) mod modulusValue
let neighborPower = powerMod(neighborBase, repeatCount)
var signValue = int64(1)
if (repeatCount and 1) == 1:
  signValue = modulusValue - 1
let coefficient = ((neighborPower - signValue + modulusValue) mod modulusValue) *
    modularInverse(int64(cowCount)) mod modulusValue
for cowIndex in 0 .. cowCount - 1:
  let answerValue = (coefficient * initialTotal + signValue * cowValues[cowIndex]) mod modulusValue
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The addition of M before subtraction keeps the coefficient non-negative.
Products stay below 1e16, which fits in int64.
The output buffer flushes in blocks of 128 KiB.

## Complexity

The work splits into one power, one inverse and one pass over the cows.

| phase | time | space |
|---|---|---|
| input read | one pass over N numbers | one input string |
| power and inverse | O(log T) steps | constant |
| coefficient and output | O(N) | N stored numbers |

The herd pass dominates once T is large.

| measure | Big O |
|---|---|
| time | O(N + log T) |
| space | O(N) |

Naive simulation costs O(NT) and cannot finish for T near 1.4e9.

The closed form makes one power the whole cost of all rounds.
