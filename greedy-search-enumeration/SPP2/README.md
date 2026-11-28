# SPP2 — Recursive Sequence (Version X) (SPOJ)

<https://www.spoj.com/problems/SPP2/>

## Problem

Compute one far term of a linear recurrence that has a few positions where the recurrence coefficients change. Print the answer modulo 1000000007 with a case number.

Input contains cases until end of file. Each case gives n, m, and q, then m initial values, then the order t and its t coefficients, then q exception lines with index, order, and coefficients. Output is one line per case in the form `Case X: Y`.

| item | bound |
|---|---|
| target index n | m < n to 1000000000 |
| initials m | 1 to 100 |
| exceptions q | 0 to 100 |
| recurrence orders | up to 100 |
| judge limit | 5000 ms, 1536 MB |

The large target index requires repeated squaring of the recurrence.

Sample input:

```
7 5 0
1 1 2 3 5
2 1 1
10 5 1
1 1 2 3 5
2 1 1
10 2 1 2
```

Sample output:

```
Case 1: 13
Case 2: 76
```

## Idea

A recurrence acts like a machine that advances one step at a time, but squaring its transition jumps ahead in logarithmic time. Sort the exception positions and advance from one to the next with one polynomial power. At an exception, read the last few true terms from the state vector and apply the special coefficients. Takeaway: jump between exceptions, then apply each override locally.

## Why It Works

1. A linear recurrence of order t makes each term a sum of the previous t terms.
2. The characteristic polynomial satisfies x^t = c1 x^(t-1) + ... + ct.
3. Reducing x^d by that polynomial gives the coefficients that express a far term using a known block of t terms.
4. The state vector at an exception holds the t terms ending immediately before it, so special coefficients use those terms directly.
5. After an exception, the same polynomial jumps to the next exception or to the target.

| term | meaning |
|---|---|
| `mainCoefficients` | coefficients of the common recurrence |
| `baseValues` | the known block of consecutive terms |
| `baseEndIndex` | index of the last known term |
| `stateVectorAt` | terms ending at a chosen index |
| `advanceBase` | move the known block past an exception |

A script trace for the second sample case:

```
terms 1..5 : 1 1 2 3 5
a6 = 5 + 3 = 8
a7 = 8 + 5 = 13
a8 = 21, a9 = 34
exception at 10 : a10 = a9 + 2*a8 = 34 + 42 = 76
```

Coefficients are reduced modulo `modulusValue` when read, so all later products stay in int64.

## Code

**Input and scanner.** Cases are stored as raw integers and parsed on demand.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007'i64
const maxOrder = 100
const maxDegree = 2 * maxOrder + 5

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

The scanner skips non-digit bytes between values.
A separate check detects end of input before each case.
The buffer collects output across all cases.

**Polynomial engine.** Reduction by the characteristic polynomial drives every jump.

```nim
type
  CoefficientArray = array[maxOrder + 1, int64]
  Polynomial = array[maxOrder, int64]

var mainCoefficients: CoefficientArray
var recurrenceOrder = 0
var baseValues: array[maxOrder, int64]
var baseEndIndex: int64 = 0

proc multiplyPolynomials(leftPoly: Polynomial, rightPoly: Polynomial, coeffs: CoefficientArray, orderValue: int): Polynomial =
  var convolution: array[maxDegree, int64]
  for degreeIndex in 0 .. maxDegree - 1:
    convolution[degreeIndex] = 0
  for leftIndex in 0 .. orderValue - 1:
    for rightIndex in 0 .. orderValue - 1:
      convolution[leftIndex + rightIndex] = (convolution[leftIndex + rightIndex] + leftPoly[leftIndex] * rightPoly[rightIndex]) mod modulusValue
  var degreeIndex = 2 * orderValue - 2
  while degreeIndex >= orderValue:
    let highValue = convolution[degreeIndex]
    if highValue != 0:
      var coefficientIndex = 1
      while coefficientIndex <= orderValue:
        convolution[degreeIndex - coefficientIndex] = (convolution[degreeIndex - coefficientIndex] + highValue * coeffs[coefficientIndex]) mod modulusValue
        coefficientIndex += 1
    degreeIndex -= 1
  for polyIndex in 0 .. maxOrder - 1:
    result[polyIndex] = 0
  for polyIndex in 0 .. orderValue - 1:
    result[polyIndex] = convolution[polyIndex]

proc powerPolynomial(exponentValue: int64): Polynomial =
  var powerPoly: Polynomial
  for polyIndex in 0 .. maxOrder - 1:
    powerPoly[polyIndex] = 0
  if recurrenceOrder == 1:
    powerPoly[0] = mainCoefficients[1]
  else:
    powerPoly[1] = 1
  var resultPoly: Polynomial
  for polyIndex in 0 .. maxOrder - 1:
    resultPoly[polyIndex] = 0
  resultPoly[0] = 1
  var exponentLeft = exponentValue
  while exponentLeft > 0:
    if (exponentLeft and 1'i64) != 0:
      resultPoly = multiplyPolynomials(resultPoly, powerPoly, mainCoefficients, recurrenceOrder)
    exponentLeft = exponentLeft div 2
    if exponentLeft > 0:
      powerPoly = multiplyPolynomials(powerPoly, powerPoly, mainCoefficients, recurrenceOrder)
  return resultPoly
```

Reduction walks degrees from high to low.
Binary exponentiation squares the polynomial at each bit.
The order-one case treats x as the single coefficient.

**State movement.** A state vector gives the t terms ending at any index.

```nim
proc multiplyByX(poly: Polynomial, coeffs: CoefficientArray, orderValue: int): Polynomial =
  for polyIndex in 0 .. maxOrder - 1:
    result[polyIndex] = 0
  let highValue = poly[orderValue - 1]
  var polyIndex = orderValue - 1
  while polyIndex >= 1:
    result[polyIndex] = poly[polyIndex - 1]
    polyIndex -= 1
  var coefficientIndex = 1
  while coefficientIndex <= orderValue:
    result[orderValue - coefficientIndex] = (result[orderValue - coefficientIndex] + highValue * coeffs[coefficientIndex]) mod modulusValue
    coefficientIndex += 1
  return result

proc stateVectorAt(targetIndex: int64): array[maxOrder, int64] =
  let offsetValue = targetIndex - baseEndIndex
  var shiftedPoly = powerPolynomial(offsetValue)
  for stateIndex in 0 .. recurrenceOrder - 1:
    var totalValue: int64 = 0
    for polyIndex in 0 .. recurrenceOrder - 1:
      totalValue = (totalValue + shiftedPoly[polyIndex] * baseValues[polyIndex]) mod modulusValue
    result[stateIndex] = totalValue
    shiftedPoly = multiplyByX(shiftedPoly, mainCoefficients, recurrenceOrder)
  return result

proc valueAt(targetIndex: int64): int64 =
  let firstBaseIndex = baseEndIndex - int64(recurrenceOrder) + 1
  if targetIndex >= firstBaseIndex and targetIndex <= baseEndIndex:
    return baseValues[int(targetIndex - firstBaseIndex)]
  let stateValues = stateVectorAt(targetIndex)
  return stateValues[recurrenceOrder - 1]

proc advanceBase(eventIndex: int64, specialOrder: int, specialCoeffs: CoefficientArray, hasOverride: bool): int64 =
  let previousState = stateVectorAt(eventIndex - 1)
  var specialValue: int64 = 0
  if hasOverride:
    var coefficientIndex = 1
    while coefficientIndex <= specialOrder:
      var pastValue: int64 = 0
      if coefficientIndex <= recurrenceOrder:
        pastValue = previousState[recurrenceOrder - coefficientIndex]
      else:
        pastValue = valueAt(eventIndex - int64(coefficientIndex))
      specialValue = (specialValue + specialCoeffs[coefficientIndex] * pastValue) mod modulusValue
      coefficientIndex += 1
  else:
    specialValue = previousState[recurrenceOrder - 1]
  for baseIndex in 0 .. recurrenceOrder - 2:
    baseValues[baseIndex] = previousState[baseIndex + 1]
  baseValues[recurrenceOrder - 1] = specialValue
  baseEndIndex = eventIndex
  return specialValue
```

Multiplication by x is a shift plus one reduction step.
Exceptions inspect the state before their own index.
The known block shifts forward after each exception.

**Driver.** The loop parses a case, sorts exceptions, and writes one answer.

```nim
var specialIndexes = newSeq[int64](0)
var specialOrders = newSeq[int](0)
var specialCoefficients = newSeq[CoefficientArray](0)

var caseIndex = 0
while hasMoreData(inputData, scanPos):
  let targetIndex = int64(nextInt(inputData, scanPos))
  let initialCount = nextInt(inputData, scanPos)
  let specialCount = nextInt(inputData, scanPos)
  var initialValues = newSeq[int64](initialCount + 1)
  for initialIndex in 1 .. initialCount:
    initialValues[initialIndex] = int64(nextInt(inputData, scanPos))
  recurrenceOrder = nextInt(inputData, scanPos)
  for coefficientIndex in 0 .. maxOrder:
    mainCoefficients[coefficientIndex] = 0
  for coefficientIndex in 1 .. recurrenceOrder:
    mainCoefficients[coefficientIndex] = int64(nextInt(inputData, scanPos)) mod modulusValue
  specialIndexes.setLen(specialCount)
  specialOrders.setLen(specialCount)
  specialCoefficients.setLen(specialCount)
  for specialIndex in 0 .. specialCount - 1:
    specialIndexes[specialIndex] = int64(nextInt(inputData, scanPos))
    specialOrders[specialIndex] = nextInt(inputData, scanPos)
    for coefficientIndex in 0 .. maxOrder:
      specialCoefficients[specialIndex][coefficientIndex] = 0
    for coefficientIndex in 1 .. specialOrders[specialIndex]:
      specialCoefficients[specialIndex][coefficientIndex] = int64(nextInt(inputData, scanPos)) mod modulusValue
  var sortIndex = 1
  while sortIndex < specialCount:
    let keyIndex = specialIndexes[sortIndex]
    let keyOrder = specialOrders[sortIndex]
    let keyCoefficients = specialCoefficients[sortIndex]
    var scanBack = sortIndex - 1
    while scanBack >= 0 and specialIndexes[scanBack] > keyIndex:
      specialIndexes[scanBack + 1] = specialIndexes[scanBack]
      specialOrders[scanBack + 1] = specialOrders[scanBack]
      specialCoefficients[scanBack + 1] = specialCoefficients[scanBack]
      scanBack -= 1
    specialIndexes[scanBack + 1] = keyIndex
    specialOrders[scanBack + 1] = keyOrder
    specialCoefficients[scanBack + 1] = keyCoefficients
    sortIndex += 1
  caseIndex += 1
  var answerValue: int64 = 0
  if targetIndex <= int64(initialCount):
    answerValue = initialValues[int(targetIndex)]
  else:
    for baseIndex in 0 .. maxOrder - 1:
      baseValues[baseIndex] = 0
    var firstBaseIndex = initialCount - recurrenceOrder + 1
    if firstBaseIndex < 1:
      firstBaseIndex = 1
    for baseIndex in 0 .. recurrenceOrder - 1:
      baseValues[baseIndex] = initialValues[firstBaseIndex + baseIndex] mod modulusValue
    baseEndIndex = int64(initialCount)
    var eventIndex = 0
    while eventIndex < specialCount and specialIndexes[eventIndex] <= targetIndex:
      discard advanceBase(specialIndexes[eventIndex], specialOrders[eventIndex], specialCoefficients[eventIndex], true)
      eventIndex += 1
    answerValue = valueAt(targetIndex)
  appendOutput("Case " & $caseIndex & ": " & $answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Targets within the initial block return the given value.
Insertion sort orders the exceptions by index.
Each case produces exactly one labeled line.

## Complexity

Polynomial powering dominates each jump between exceptions.

| phase | time | space |
|---|---|---|
| input read | one pass over case integers | one input string |
| polynomial power | O(t^2 log gap) per jump | two polynomials |
| exception apply | O(t^2) per exception | one state vector |
| output | one line per case | block buffer |

The gap shrinks as exceptions are processed in order.

| measure | Big O |
|---|---|
| time | O((q+1) t^2 log n) per case |
| space | O(t) |

Advancing one step at a time would take O(n t) work per case. Takeaway: polynomial jumps keep billion-index targets small.
