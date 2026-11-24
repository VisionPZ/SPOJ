## Problem

Read a count t, then t lines. Each line holds one polynomial F(x) written as a sum of monomials. Print every real solution of F(x) = 0 in non-decreasing order. Print repeated solutions once per copy, with two digits after the decimal point.

The bounds that shape the program are these:

| Quantity | Bound |
| --- | --- |
| Test cases t | at most 100 |
| Line length | at most 300 characters |
| Coefficient | -30000 to 30000 |
| Degree | 0 to 6 |
| Root interval | -100.0 to 100.0 |
| Judge limits | 1694 ms, 1536 MB |

Degree six and at most 100 cases keep a per-case numeric search cheap.

## Idea

Split the interval at the roots of the derivative. Between two neighboring derivative roots the polynomial is monotonic, so at most one solution sits there. A sign change at the ends gives that solution by bisection, and synthetic division counts repeated copies.

Cost per case: derivative solves down to degree one, then one bisection per monotonic piece. A fine grid costs 20 001 evaluations per case and still misses even-multiplicity solutions.

## Why It Works

Three facts prove the method.

1. Rolle's theorem puts a derivative root between every pair of neighboring roots of F. With all roots real, the derivative also has all roots real.
2. On an interval with no derivative root inside, F is monotonic. Opposite signs at the two ends then prove exactly one root.
3. A root shared by F and its derivative has multiplicity at least two. Each synthetic division removes one copy.

Synthetic division uses this update, with coefficients stored from the constant term upward:

| term | meaning |
| --- | --- |
| `quotientCoefficients[workDegree - 1]` | leading coefficient of the quotient |
| `quotientCoefficients[powerIndex - 1]` | next coefficient, built from the current one and `rootValue` |
| `residualFactor * referenceScale` | tolerance scaled to the polynomial near the trial root |

The scale is sampled at the trial root and 0.7 away, so a root near zero never collapses the tolerance.

A script builds the example polynomial and traces the search:

```
F(x) = x^3 - 4*x^2 + 5*x - 2
F'(x) = 3*x^2 - 8*x + 5, derivative roots 1 and 1.666667
F(-100) < 0, F(1) = 0, F(1.666667) < 0, F(100) > 0
divide by (x - 1) twice, remainders 0 and 0
bisection on (1.666667, 100) gives 2
output: 1.00 1.00 2.00
```

Both divisions by (x - 1) leave zero remainder, and the last interval yields 2.

## Code

Each block below is copied verbatim from solution.nim.

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

The read loop stops at end of file, so blank lines cannot desynchronize cases. `nextInt` scans digits in the one buffer and allocates nothing. `nextPolynomial` captures exactly one line.

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
```

The loop walks each character once, at most 300 characters. `termStart` advances the cursor on an unknown character, so no token can stall the loop. Unused degrees stay zero.

```nim
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
```

Horner's rule runs from `degree - 1` down to zero. `multiplicityAt` divides while the remainder stays below a scaled tolerance. Two sample points keep a root near zero visible. One trial root costs O(degree squared).

```nim
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

The recursion stops at degree one. The interval loop visits `splitPoints.len - 1` pieces, and each bisection takes 120 fixed steps. Critical roots merge within `mergeTolerance` before copies are counted. The worst case is degree cubed, with degree at most six.

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

The formatter rounds by adding 0.5, which gives two stable decimals. `appendOutput` flushes at `flushBlockBytes`, so no per-number write reaches the stream. The final write emits the tail.

## Complexity

Parsing reads at most 300 characters per case. `findRoots` recurses through at most six degrees, and each level tests a few trial roots. Bisection spends 120 steps per interval, with at most seven intervals.

Total time is O(L + 120 times d squared + d cubed) per case. Here L is at most 300 and d is at most six. Space is O(L plus B plus d), with B the output block.

The naive form steps x from -100 to 100 by 0.01. That costs 20 001 evaluations per case, and a tangency still escapes a sign-change scan.
