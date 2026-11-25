# POLYEQ — Polynomial Equations (SPOJ)
<https://www.spoj.com/problems/POLYEQ/>

## Problem

A polynomial is given as a sum of monomials, such as `x^4-6*x^3+11*x^2-6*x`. Find every real root, including repeated roots, in non-decreasing order.

All roots lie between −100 and 100. Print each with two digits after the decimal point; an error of 0.01 is allowed.

Input: the first integer is t, the number of cases. Each following line holds one polynomial. Output: one line per case with all roots separated by spaces.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | at most 100 |
| Degree | 0 to 6 |
| Coefficient | −30000 to 30000 |
| Polynomial text length | at most 300 characters |
| Root interval | [−100.0, 100.0] |
| Allowed error | 0.01 |
| Time limit | 1694 ms |
| Memory limit | 1536 MB |

The sample has a quartic with four roots and a squared linear factor:

```
2
x^4-6*x^3+11*x^2-6*x
-x^2+2*x-1
```

```
0.00 1.00 2.00 3.00
1.00 1.00
```

The second polynomial is −(x − 1)², so root 1 appears twice.

## Idea

Find the peaks and valleys first, then search each stretch between them. Picture a hilly road: before counting sea-level crossings, mark every hilltop and valley, because between them the road only climbs or only descends.

The program parses the polynomial into seven coefficients. It then calls `findRoots` recursively on the derivative. Those critical points split [−100, 100] into monotone pieces.

On each piece, a sign change at the ends means one root, found by bisection. At a critical point, synthetic division measures multiplicity, and the program records the root that many times.

Degree is at most six, and each bisection runs 120 steps, so each case is tiny. A fixed grid over the interval would miss repeated roots entirely.

Takeaway: derivative roots turn root finding into monotone bisection plus a multiplicity count.

## Why It Works

Five facts support the method.

1. Between consecutive roots of the derivative, f is monotone. A monotone segment crosses zero at most once, and it crosses exactly once when the endpoint signs differ.
2. Critical points come from calling the same routine on the derivative, whose degree is one lower. The base cases, degree 0 and degree 1, are direct.
3. `multiplicityAt` divides out (x − r) repeatedly while the residual stays small compared with the local magnitude. Each division raises the recorded multiplicity by one.
4. Repeated roots sit at critical points and produce no sign change, so they are recorded from multiplicity instead of bisection. Both interval ends are also checked with the same test.
5. `formatRoot` multiplies by 100, rounds half away from zero with integers, then splits the result into whole and fractional digits. Values below 0.005 snap to zero.

These are the controls in the root search:

| Term | Meaning |
| --- | --- |
| `coefficients` | array of seven values, index is the monomial degree |
| `evaluate` | Horner evaluation, nested multiply and add |
| `magnitude` | sum of absolute terms, used as a local scale |
| `referenceScale` | largest magnitude near the candidate root |
| `mergeTolerance` | 1e−4, merges nearly equal critical points |
| `residualFactor` | 1e−9, relative threshold for a repeated root |
| `bisectRoot` | 120 midpoint steps on a sign-changing segment |

A script lists the critical points and resulting roots for both sample cases:

```
f  = x^4-6*x^3+11*x^2-6*x
f' = 4*x^3-18*x^2+22*x-6
critical points: 0.381966, 1.500000, 2.618034
split points: -100, 0.381966, 1.5, 2.618034, 100
sign changes -> roots: 0.00 1.00 2.00 3.00

g  = -x^2+2*x-1 = -(x-1)^2
g' = -2*x+2
critical point 1.000000 has multiplicity 2 -> roots 1.00 1.00
```

Each segment of f contributes one root. The repeated root of g appears through multiplicity, which a sign test alone cannot see.

## Code

**Input.** The whole stream goes into one buffer, and polynomials are read as lines.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const rootLow = -100.0
const rootHigh = 100.0
const mergeTolerance = 1e-4
const residualFactor = 1e-9
const residualFloor = 1e-300

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPosition = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextPolynomial(data: string, position: var int): string =
  while position < data.len and (data[position] == '\n' or data[position] == '\r' or data[position] == ' '):
    position += 1
  result = ""
  while position < data.len and data[position] != '\n' and data[position] != '\r':
    result.add data[position]
    position += 1
```

`nextPolynomial` stops at the line break, so blank separators cannot desync cases. The scanner handles the small case count. Cost is one pass over the input bytes.

**Parsing.** A character walk fills coefficients; two helpers evaluate and scale.

```nim
proc parsePolynomial(text: string): array[7, float64] =
  var coefficients: array[7, float64]
  var termSign = 1.0
  var position = 0
  while position < text.len:
    let currentChar = text[position]
    if currentChar == '+':
      termSign = 1.0
      position += 1
      continue
    if currentChar == '-':
      termSign = -1.0
      position += 1
      continue
    if currentChar == ' ':
      position += 1
      continue
    let termStart = position
    var coefficientValue = 1.0
    var monomialDegree = 0
    let numberStart = position
    while position < text.len and text[position] >= '0' and text[position] <= '9':
      position += 1
    if position > numberStart:
      coefficientValue = 0.0
      for i in numberStart ..< position:
        coefficientValue = coefficientValue * 10.0 + float64(int(text[i]) - firstDigitValue)
    if position < text.len and text[position] == '*':
      position += 1
    if position < text.len and text[position] == 'x':
      position += 1
      monomialDegree = 1
      if position < text.len and text[position] == '^':
        position += 1
        monomialDegree = 0
        while position < text.len and text[position] >= '0' and text[position] <= '9':
          monomialDegree = monomialDegree * 10 + int(text[position]) - firstDigitValue
          position += 1
    coefficients[monomialDegree] += termSign * coefficientValue
    if position == termStart:
      position += 1
  return coefficients

proc evaluate(coefficients: array[7, float64], degree: int, value: float64): float64 =
  result = coefficients[degree]
  var powerIndex = degree - 1
  while powerIndex >= 0:
    result = result * value + coefficients[powerIndex]
    powerIndex -= 1

proc magnitude(coefficients: array[7, float64], degree: int, value: float64): float64 =
  result = 0.0
  var power = 1.0
  let absoluteValue = abs(value)
  for powerIndex in 0 .. degree:
    result += abs(coefficients[powerIndex]) * power
    power *= absoluteValue
```

A missing coefficient defaults to 1, which covers `x` and `x^3`. Horner evaluation uses degree multiply-adds. `magnitude` supplies a scale so the residual test does not depend on absolute size.

**Multiplicity.** Synthetic division counts repeated roots; bisection locates simple ones.

```nim
proc multiplicityAt(coefficients: array[7, float64], degree: int, rootValue: float64): int =
  var workCoefficients: array[7, float64]
  for i in 0 .. 6:
    workCoefficients[i] = coefficients[i]
  let referenceScale = max(magnitude(coefficients, degree, rootValue),
                           max(magnitude(coefficients, degree, rootValue + 0.7),
                               magnitude(coefficients, degree, rootValue - 0.7)))
  var workDegree = degree
  while workDegree >= 1:
    let residualValue = evaluate(workCoefficients, workDegree, rootValue)
    if abs(residualValue) > residualFactor * referenceScale + residualFloor:
      break
    var quotientCoefficients: array[7, float64]
    quotientCoefficients[workDegree - 1] = workCoefficients[workDegree]
    var powerIndex = workDegree - 1
    while powerIndex >= 1:
      quotientCoefficients[powerIndex - 1] = workCoefficients[powerIndex] + rootValue * quotientCoefficients[powerIndex]
      powerIndex -= 1
    for i in 0 ..< workDegree:
      workCoefficients[i] = quotientCoefficients[i]
    workCoefficients[workDegree] = 0.0
    workDegree -= 1
    result += 1

proc bisectRoot(coefficients: array[7, float64], degree: int, leftEdge: float64, rightEdge: float64, leftValue: float64): float64 =
  var lowEdge = leftEdge
  var highEdge = rightEdge
  var lowValue = leftValue
  for i in 0 .. 119:
    let midPoint = (lowEdge + highEdge) / 2.0
    let midValue = evaluate(coefficients, degree, midPoint)
    if (midValue < 0.0) == (lowValue < 0.0):
      lowEdge = midPoint
      lowValue = midValue
    else:
      highEdge = midPoint
  result = (lowEdge + highEdge) / 2.0

proc sortAscending(values: var seq[float64]) =
  for i in 1 ..< values.len:
    let currentValue = values[i]
    var position = i - 1
    while position >= 0 and values[position] > currentValue:
      values[position + 1] = values[position]
      position -= 1
    values[position + 1] = currentValue
```

`referenceScale` uses three nearby points, so a root near a flat region still tests fairly. The `while` loop stops dividing once the residual grows. Bisection keeps the side with the original sign; 120 steps exceed the needed 0.01. Insertion sort handles at most six roots.

**Roots.** The recursive search splits on the derivative's roots.

```nim
proc findRoots(coefficients: array[7, float64], degree: int): seq[float64] =
  if degree == 0:
    return @[]
  if degree == 1:
    result.add -coefficients[0] / coefficients[1]
    return
  var derivative: array[7, float64]
  for i in 0 ..< degree:
    derivative[i] = coefficients[i + 1] * float64(i + 1)
  var criticalRoots = findRoots(derivative, degree - 1)
  sortAscending(criticalRoots)
  var distinctCriticals: seq[float64] = @[]
  for rootValue in criticalRoots:
    if distinctCriticals.len == 0 or abs(rootValue - distinctCriticals[distinctCriticals.len - 1]) > mergeTolerance:
      distinctCriticals.add rootValue
  for criticalValue in distinctCriticals:
    let rootMultiplicity = multiplicityAt(coefficients, degree, criticalValue)
    for i in 0 ..< rootMultiplicity:
      result.add criticalValue
  for boundaryValue in [rootLow, rootHigh]:
    var alreadyFound = false
    for criticalValue in distinctCriticals:
      if abs(boundaryValue - criticalValue) <= mergeTolerance:
        alreadyFound = true
    if not alreadyFound:
      let rootMultiplicity = multiplicityAt(coefficients, degree, boundaryValue)
      for i in 0 ..< rootMultiplicity:
        result.add boundaryValue
  var splitPoints: seq[float64] = @[]
  splitPoints.add rootLow
  for criticalValue in distinctCriticals:
    splitPoints.add criticalValue
  splitPoints.add rootHigh
  for i in 0 ..< splitPoints.len - 1:
    let leftEdge = splitPoints[i]
    let rightEdge = splitPoints[i + 1]
    if rightEdge - leftEdge < mergeTolerance:
      continue
    if multiplicityAt(coefficients, degree, leftEdge) > 0:
      continue
    if multiplicityAt(coefficients, degree, rightEdge) > 0:
      continue
    let leftValue = evaluate(coefficients, degree, leftEdge)
    let rightValue = evaluate(coefficients, degree, rightEdge)
    if (leftValue < 0.0 and rightValue > 0.0) or (leftValue > 0.0 and rightValue < 0.0):
      result.add bisectRoot(coefficients, degree, leftEdge, rightEdge, leftValue)
  sortAscending(result)
```

`mergeTolerance` drops critical points that are numerically identical. Both interval ends get the multiplicity test, so a root at ±100 is not missed. Only segments with opposite endpoint signs go to bisection.

**Driver.** Each polynomial is printed with two decimals.

```nim
proc formatRoot(value: float64): string =
  var scaledValue = value * 100.0
  if abs(scaledValue) < 0.5:
    scaledValue = 0.0
  var roundedValue: int64
  if scaledValue >= 0.0:
    roundedValue = int64(scaledValue + 0.5)
  else:
    roundedValue = int64(scaledValue - 0.5)
  let negativeRoot = roundedValue < 0
  let wholePart = abs(roundedValue) div 100
  let fracPart = abs(roundedValue) mod 100
  result = ""
  if negativeRoot:
    result.add '-'
  result.add $wholePart
  result.add '.'
  if fracPart < 10:
    result.add '0'
  result.add $fracPart

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPosition)
for caseIndex in 0 ..< caseCount:
  let polynomialText = nextPolynomial(inputData, scanPosition)
  let coefficients = parsePolynomial(polynomialText)
  var degree = 0
  for i in 0 .. 6:
    if coefficients[i] != 0.0:
      degree = i
  let roots = findRoots(coefficients, degree)
  var firstRoot = true
  for rootValue in roots:
    if not firstRoot:
      appendOutput " "
    appendOutput formatRoot(rootValue)
    firstRoot = false
  appendOutput "\n"

stdout.write outputBuffer
outputBuffer.setLen 0
```

`formatRoot` rounds half away from zero, then pads one fractional digit when needed. The degree scan uses the highest nonzero coefficient. The final write flushes the tail.

## Complexity

Degree bounds every stage.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total characters) | O(input size) |
| Parse polynomial | O(string length) | O(1) |
| Recursive critical points | O(deg²) | O(deg) |
| Bisection on each segment | O(deg × 120) | O(deg) |
| Output | O(roots) | O(block size) |

With degree at most six, all stages stay tiny.

| Measure | Big O |
| --- | --- |
| Time per case | O(deg² + deg × iterations) |
| Total time | O(t × deg²) |
| Working space | O(deg) |

Scanning the interval on a fixed grid would find simple roots but miss repeated ones, which the multiplicity test recovers.
