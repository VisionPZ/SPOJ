# SEQAGAIN — Easy Sequence! (SPOJ)
<https://www.spoj.com/problems/SEQAGAIN/>

## Problem

Each term after the first two is the product of the previous two terms, raised to K. Report term n modulo 1000000007.

Input starts with the case count T. Each case gives four integers: F(0), F(1), n, and K. Print one answer per case on its own line.

| Constraint | Value |
| --- | --- |
| Cases T | up to 5000 |
| Term index n | 0 to 1000000000000000000 |
| Exponent K | 0 to 1000000000 |
| Starting values | 0 to 1000000 |
| Modulus | 1000000007 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The sample input and its expected output follow byte for byte.

```
1
1 1 2 1
```

```
1
```

## Idea

Track how many copies of each starting value appear, like counting ingredients instead of weighing the whole cake.

Every term equals F(0) raised to a count times F(1) raised to another count. Both counts follow a Fibonacci-like rule with K as a multiplier. The program raises a small transition matrix to the power n-1. Exponents are reduced modulo 1000000006 because the modulus is prime. Direct iteration would need n steps. Matrix powers need only about 60 steps. Count ingredients once, then rebuild the answer from two modular powers.

## Why It Works

1. Write F(t) as F(0) to the a(t) times F(1) to the b(t), with a(0)=1, b(0)=0, a(1)=0, b(1)=1.
2. Raising a product to K multiplies both exponents by K, so a(t)=K times (a(t-1)+a(t-2)) and the same holds for b(t).
3. The matrix [[K,K],[1,0]] maps (a(t-1),a(t-2)) to (a(t),a(t-1)) in one step.
4. Fermat's theorem allows exponents modulo 1000000006 when a base is not divisible by the modulus.
5. A zero base with a positive exponent gives zero, so those cases return zero before any power is taken.

| Term | Meaning |
| --- | --- |
| `exponentModulus` | modulus 1000000006 for exponent counts |
| `stepMatrix` | transition matrix for the two counts |
| `firstExponent` | count of F(0) in term n |
| `secondExponent` | count of F(1) in term n |

A script-generated check uses F(0)=2, F(1)=3, K=2. At n=2 the counts are 2 and 2, so the term is 2 to the 2 times 3 to the 2, which is 36. At n=3 the counts are 4 and 6, so the term is 16 times 729, which is 11664. The matrix power produces both pairs of counts directly.

## Code

**Input and scanner.** One buffer holds the whole stream, and the scanner reads four integers per case.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const exponentModulus = 1000000006

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

All inputs are nonnegative.
The scanner skips whitespace between tokens.
Index n fits in a signed 64-bit integer.

**Output writer and helpers.** Matrix multiplication and modular powers use 64-bit intermediates.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc multiplyMatrices(leftMatrix: array[4, int64], rightMatrix: array[4, int64]): array[4, int64] =
  result[0] = (leftMatrix[0] * rightMatrix[0] + leftMatrix[1] * rightMatrix[2]) mod exponentModulus
  result[1] = (leftMatrix[0] * rightMatrix[1] + leftMatrix[1] * rightMatrix[3]) mod exponentModulus
  result[2] = (leftMatrix[2] * rightMatrix[0] + leftMatrix[3] * rightMatrix[2]) mod exponentModulus
  result[3] = (leftMatrix[2] * rightMatrix[1] + leftMatrix[3] * rightMatrix[3]) mod exponentModulus

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var baseLeft = baseValue mod modulusValue
  var exponentLeft = exponentValue
  result = 1
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      result = (result * baseLeft) mod modulusValue
    baseLeft = (baseLeft * baseLeft) mod modulusValue
    exponentLeft = exponentLeft shr 1
```

Each matrix entry stays below 1000000006.
Each product stays below 10 to the 18.
The output buffer flushes in large blocks.

**Case solver.** Base cases return directly. Other cases raise the transition matrix and rebuild the term.

```nim
let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let firstSeed = int64(nextInt(inputData, scanPos))
  let secondSeed = int64(nextInt(inputData, scanPos))
  let termIndex = int64(nextInt(inputData, scanPos))
  let exponentFactor = int64(nextInt(inputData, scanPos))
  var answer: int64 = 0
  if termIndex == 0:
    answer = firstSeed mod modulusValue
  elif termIndex == 1:
    answer = secondSeed mod modulusValue
  elif exponentFactor == 0:
    answer = 1
  else:
    var stepMatrix = [exponentFactor mod exponentModulus, exponentFactor mod exponentModulus, int64(1), int64(0)]
    var productMatrix = [int64(1), int64(0), int64(0), int64(1)]
    var remainingSteps = termIndex - 1
    while remainingSteps > 0:
      if (remainingSteps and 1) == 1:
        productMatrix = multiplyMatrices(productMatrix, stepMatrix)
      stepMatrix = multiplyMatrices(stepMatrix, stepMatrix)
      remainingSteps = remainingSteps shr 1
    let firstExponent = productMatrix[1]
    let secondExponent = productMatrix[0]
    let firstBase = firstSeed mod modulusValue
    let secondBase = secondSeed mod modulusValue
    if firstBase == 0 or secondBase == 0:
      answer = 0
    else:
      answer = (powerMod(firstBase, firstExponent) * powerMod(secondBase, secondExponent)) mod modulusValue
  appendOutput($answer)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Zero exponents cover n of 0 or 1 and K of zero.
A zero starting value forces a zero answer for n of two or more.
The last flush writes all remaining lines.

## Complexity

Each case uses about 60 matrix squarings and two modular powers.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over 4 T integers | one input string |
| Matrix power | O(log n) matrix products | four matrix entries |
| Modular powers | O(log n) multiplies per base | constant |
| Output | one line per case | one output buffer |

| Measure | Big O |
| --- | --- |
| Time per case | O(log n) |
| Space | O(1) |

Iterating the recurrence n times would need up to 10 to the 18 steps.

Two counts replace the huge term, and a matrix power jumps to term n.
