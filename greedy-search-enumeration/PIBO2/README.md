# PIBO2 — Fibonacci vs Polynomial (HARD) (SPOJ)

<https://www.spoj.com/problems/PIBO2/>

## Problem

Compute a Fibonacci-like sequence whose extra term at step n is the value of a given polynomial at n, reduced modulo 1111111111.

Input has one case. The first line holds n and the degree d. The second line holds the d+1 coefficients in ascending powers. Output one integer.

| item | bound |
|---|---|
| step index n | 0 to 1000000000 |
| degree d | 0 to 10000 |
| coefficients | 0 to 1111111110 |
| judge limit | 100 ms, 1536 MB |

The large step index rules out stepping through the recurrence one term at a time.

Sample input:

```
10 0
0
```

Sample output:

```
89
```

With a zero polynomial, the sequence is the Fibonacci sequence shifted by one.

## Idea

Treating the polynomial as a short memory is like summarizing a long song by its repeating chorus. A polynomial of degree d is annihilated by the difference operator to the power d+1, so the sequence obeys a linear recurrence of order d+3. Exponentiating the polynomial x modulo that recurrence gives the nth term. Computing each term up to n would take linear time in n. Reduce the recurrence to a polynomial modulus and reuse squaring.

## Why It Works

1. The homogeneous part contributes the factor x squared minus x minus one.
2. A degree d polynomial is killed by applying the difference operator d+1 times.
3. The combined characteristic polynomial has degree d+3.
4. Its coefficients come from multiplying by one minus x, then by one minus x minus x squared.
5. Reducing x to the n-th power in that quotient gives the nth sequence value as a linear combination of the first d+3 terms.

| term | meaning |
|---|---|
| `recurrenceOrder` | d+3, the order of the recurrence |
| `reduction` | coefficients of the characteristic polynomial |
| `initialValues` | the first recurrence-order sequence values |
| `powerPoly` | x raised to the current exponent, reduced |

The table follows the sequence from its recurrence to its nth term.

A script trace for the first sample:

```
P(n) = 0: terms 1 1 2 3 5 8 13 21 34 55 89
index 10 holds 89, which is the sample output
P(n) = 1: terms 1 1 3 5 9 15 25 41 67 109 177
index 10 holds 177, the second example answer
```

The trace shows how the forcing polynomial changes the same recurrence.

## Code

**Input and scanner.** The reader loads the index, degree, and coefficients.

```nim
const modulus = 1111111111
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

Coefficients are read in ascending degree.
The index fits in a signed 64-bit integer.
No sign handling is needed.

**Modular helpers.** Norming keeps every coefficient in range after subtraction.

```nim
proc normMod(value: int64): int64 =
  let remainder = value mod modulus
  if remainder < 0:
    return remainder + modulus
  return remainder

proc evaluatePolynomial(coefficients: seq[int64], argument: int): int64 =
  var value: int64 = 0
  for indexValue in countDown(coefficients.len - 1, 0):
    value = (value * int64(argument) + coefficients[indexValue]) mod modulus
  return value
```

Horner's rule evaluates the forcing polynomial.
Every product stays inside 64 bits.
Norming handles negative intermediate coefficients.

**Reduced multiplication.** Products are folded back below the recurrence degree.

```nim
proc multiplyPoly(firstPoly, secondPoly, reduction: seq[int64], order: int): seq[int64] =
  var productTerms = newSeq[int64](2 * order - 1)
  for firstIndex in 0 .. order - 1:
    if firstPoly[firstIndex] == 0:
      continue
    for secondIndex in 0 .. order - 1:
      let position = firstIndex + secondIndex
      productTerms[position] = normMod(productTerms[position] +
          firstPoly[firstIndex] * secondPoly[secondIndex])
  for degree in countDown(2 * order - 2, order):
    let highValue = productTerms[degree]
    if highValue == 0:
      continue
    for shift in 1 .. order:
      let position = degree - shift
      productTerms[position] = normMod(productTerms[position] - highValue * reduction[shift])
  return productTerms[0 .. order - 1]
```

The inner loops cost quadratic work per multiplication.
High degrees are eliminated from the top down.
Only the low-order terms are kept.

**Recurrence construction.** Two polynomial products give the reduction rule.

```nim
var polynomialPart = newSeq[int64](1)
polynomialPart[0] = 1
for stepIndex in 0 .. degreeValue:
  var expanded = newSeq[int64](polynomialPart.len + 1)
  for indexValue in 0 .. polynomialPart.len - 1:
    let termValue = polynomialPart[indexValue]
    expanded[indexValue] = normMod(expanded[indexValue] + termValue)
    expanded[indexValue + 1] = normMod(expanded[indexValue + 1] - termValue)
  polynomialPart = expanded

var reduction = newSeq[int64](recurrenceOrder + 1)
for indexValue in 0 .. polynomialPart.len - 1:
  let termValue = polynomialPart[indexValue]
  reduction[indexValue] = normMod(reduction[indexValue] + termValue)
  reduction[indexValue + 1] = normMod(reduction[indexValue + 1] - termValue)
  reduction[indexValue + 2] = normMod(reduction[indexValue + 2] - termValue)
```

The first loop builds one minus x to the degree plus one.
The second loop adds the Fibonacci factor.
The result has degree d+3.

**Exponentiation and output.** Squaring x reaches the requested step.

```nim
var powerPoly = newSeq[int64](recurrenceOrder)
powerPoly[0] = 1
var basePoly = newSeq[int64](recurrenceOrder)
basePoly[1] = 1
var remainingSteps = int64(targetIndex)
while remainingSteps > 0:
  if (remainingSteps and 1) == 1:
    powerPoly = multiplyPoly(powerPoly, basePoly, reduction, recurrenceOrder)
  remainingSteps = remainingSteps div 2
  if remainingSteps > 0:
    basePoly = multiplyPoly(basePoly, basePoly, reduction, recurrenceOrder)

var answerValue: int64 = 0
for indexValue in 0 .. recurrenceOrder - 1:
  answerValue = normMod(answerValue + powerPoly[indexValue] * initialValues[indexValue])
appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Binary exponentiation uses about log n squarings.
The final dot product gives the answer.
One line is written.

## Complexity

Work splits into recurrence setup and exponentiation.

| phase | time | space |
|---|---|---|
| forcing evaluation | O(d) per initial term | coefficient array |
| recurrence setup | O(d) | reduction array |
| exponentiation | O(d^2 log n) | three polynomials |
| output | one line | block buffer |

The phase table shows that squaring dominates for large d.

| measure | Big O |
|---|---|
| time | O(d^2 log n) |
| space | O(d) |

Stepping through n terms would cost O(n d) instead.
The polynomial modulus makes billion-step indices reachable.
