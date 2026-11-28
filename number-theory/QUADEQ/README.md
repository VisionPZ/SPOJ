# QUADEQ — Quadratic Equation (SPOJ)

<https://www.spoj.com/problems/QUADEQ/>

## Problem

Solve a quadratic equation over the real numbers and print how many real roots it has, followed by the roots in ascending order. Answers within 1e-6 of the true values are accepted.

The input holds three integers a, b and c with a nonzero. Each lies between -1000 and 1000. Print the count on its own line, then the roots on one line separated by spaces.

| item | bound |
|---|---|
| coefficients | -1000 to 1000 |
| leading coefficient a | nonzero |
| root tolerance | 1e-6 |
| judge limit | 1000 ms, 1536 MB |

A negative discriminant means there are no real roots.

Sample input:

```
-1 0 2
```

Sample output:

```
2
-1.414213562 1.414213562
```

## Idea

Think of the discriminant as a gate: below zero there is no crossing, at zero there is one, and above zero there are two. Compute that gate with exact integer arithmetic, then evaluate the quadratic formula only when roots exist.

The real algorithm uses int64 for the discriminant and double precision for the square root. Work per case is constant. Guessing roots by scanning values would miss irrational roots and would not meet the tolerance. The takeaway is that exact sign detection precedes any floating point work.

## Why It Works

1. The discriminant equals b squared minus four times a times c.
2. A negative discriminant gives no real roots.
3. A zero discriminant gives the single root minus b over twice a.
4. Two roots are minus b plus or minus the square root of the discriminant, over twice a.
5. Sorting the two values guarantees ascending output even when a is negative.

| term | meaning |
|---|---|
| `coefficientA` | leading coefficient, never zero |
| `coefficientB` | linear coefficient |
| `coefficientC` | constant coefficient |
| `discriminant` | exact integer value b squared minus four ac |
| `rootPrecision` | nine digits printed after the decimal point |
| `normalizeRoot` | replaces negative zero with positive zero |

For the sample, the discriminant is eight. Its square root is about 2.828427124. The two roots are -1.414213562 and 1.414213562.

Nine printed digits stay well within the required tolerance.

## Code

**Input and scanner.** The reader captures all numbers, including negative signs.

```nim
import math
import strutils

const flushBlockBytes = 1 shl 17
const rootPrecision = 9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc normalizeRoot(rootValue: float): float =
  if rootValue == 0.0:
    return 0.0
  return rootValue
```

The minus branch reads negative coefficients.
The buffer collects the count and root lines.
Negative zero is removed before formatting.

**Discriminant gate.** An int64 discriminant decides which branch runs.

```nim
let coefficientA = int64(nextInt(inputData, scanPos))
let coefficientB = int64(nextInt(inputData, scanPos))
let coefficientC = int64(nextInt(inputData, scanPos))
let discriminant = coefficientB * coefficientB - 4 * coefficientA * coefficientC
if discriminant < 0:
  appendOutput("0")
  outputBuffer.add '\n'
elif discriminant == 0:
  let rootValue = normalizeRoot(-float64(coefficientB) / (2.0 * float64(coefficientA)))
  appendOutput("1")
  outputBuffer.add '\n'
  appendOutput(formatFloat(rootValue, ffDecimal, rootPrecision))
  outputBuffer.add '\n'
```

Integer arithmetic keeps the sign exact.
The repeated root needs no square root call.
Nine decimals satisfy the tolerance.

**Two roots.** The formula produces both values, which are then sorted.

```nim
else:
  let rootSqrt = sqrt(float64(discriminant))
  var firstRoot = (-float64(coefficientB) - rootSqrt) / (2.0 * float64(coefficientA))
  var secondRoot = (-float64(coefficientB) + rootSqrt) / (2.0 * float64(coefficientA))
  firstRoot = normalizeRoot(firstRoot)
  secondRoot = normalizeRoot(secondRoot)
  if firstRoot > secondRoot:
    swap(firstRoot, secondRoot)
  appendOutput("2")
  outputBuffer.add '\n'
  appendOutput(formatFloat(firstRoot, ffDecimal, rootPrecision))
  outputBuffer.add ' '
  appendOutput(formatFloat(secondRoot, ffDecimal, rootPrecision))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Dividing by a negative coefficient reverses the raw order.
Sorting fixes that reversal in one comparison.
The final flush writes all lines at once.

## Complexity

All work is a fixed number of arithmetic operations.

| phase | time | space |
|---|---|---|
| input read | one pass over three numbers | one input string |
| discriminant | constant integer arithmetic | constant extra space |
| roots and output | constant floating point work | block buffer |

| measure | Big O |
|---|---|
| time | O(1) |
| space | O(1) beyond input and output |

Searching for roots by stepping through candidate values would depend on the coefficient range and could miss irrational answers.
The closed formula gives both roots in constant time.
