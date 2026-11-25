# MEANSTRIC — Tricky Means (SPOJ)

<https://www.spoj.com/problems/MEANSTRIC/>

## Problem

For each case, compute three Pythagorean means of a list of positive real numbers and print each with nine digits after the point. The three means answer three different questions about the same list.

Input starts with the case count. Each case gives n, then n positive real numbers. Output one line per case: arithmetic mean, geometric mean and harmonic mean, separated by spaces and printed to 1e-9 precision.

| item | bound |
|---|---|
| cases in generated tests | up to 2000 |
| numbers per case | 1 to 100 |
| numbers | strictly positive reals up to 1000000000 |
| required precision | 9 digits after the point |
| judge limit | 1000 ms, 1536 MB |

The small per-case size keeps three accumulators cheap.

Sample input:

```
3
5
4 36 45 50 75
6
1.0 2.0 4.0 7.0 14.0 28.0
8
1.0 2.0 3.0 4.0 9.0 12.0 18.0 36.0
```

Sample output:

```
42.000000000 30.000000000 15.000000000
9.333333333 5.291502622 3.000000000
10.625000000 6.000000000 3.388235294
```

## Idea

Treat the three means as three ways to summarise one list, like averaging prices, growth rates and speeds. The three-accumulator algorithm sums values, sums logarithms and sums reciprocals in one pass. The geometric mean comes from exponentiating the average log, which avoids multiplying up to a huge product. The arithmetic mean is rebuilt from decimal digits as an exact integer quotient, so half-even rounding at the ninth digit matches the reference. The takeaway is to choose a representation that keeps each mean exact where it matters.

## Why It Works

1. The arithmetic mean is the sum of values divided by the count.
2. The geometric mean is exp of the average of the natural logs.
3. The harmonic mean is the count divided by the sum of reciprocals.
4. Logs turn a product of up to 100 large values into a small sum, avoiding overflow.
5. Scaling every decimal token by a shared power of ten turns the sum into an exact integer.
6. Doubling the division remainder decides half-even rounding without floating-point drift.
7. Extended precision keeps the log and reciprocal sums stable across many values.

| term | meaning |
|---|---|
| `sumScaled` | exact sum of decimal tokens after scaling |
| `maxDecimals` | largest decimal scale used in the case |
| `formatExactArithmetic` | rounds the exact sum to nine digits |
| `sumLogs` | sum of natural logarithms |
| `sumReciprocals` | sum of reciprocal values |

Exact integers handle the arithmetic mean; extended precision handles the other two.

A script-generated trace for the first sample case:

```
values ['4', '36', '45', '50', '75']
sum 210 log sum 17.00598690831077687706618345803444956124 reciprocal sum 0.3333333333333333333333333333333333333333
A 42.000000000 G 30.000000000 H 15.000000000
```

The sum 210 gives an arithmetic mean of 42; the log sum gives a geometric mean of 30.

## Code

**Extended precision helpers.** C helpers provide long double arithmetic and nine-digit formatting.

```nim
{.passL: "-lm".}

const flushBlockBytes = 1 shl 17
const lineBufferSize = 128
const decimalTarget = 9
const decimalUnit = 1000000000

{.emit: "#include <math.h>\n#include <stdlib.h>\n".}

{.emit: """
static long double meanAdd(long double leftValue, long double rightValue) {
  return leftValue + rightValue;
}
static long double meanDivide(long double leftValue, long double rightValue) {
  return leftValue / rightValue;
}
static long double meanLog(long double value) {
  return logl(value);
}
static long double meanExp(long double value) {
  return expl(value);
}
static long double meanParse(char* text, char** endPtr) {
  return strtold(text, endPtr);
}
static int meanFormatValue(char* buffer, int bufferSize, long double value) {
  return snprintf(buffer, (size_t)bufferSize, "%.9Lf", value);
}
""".}

proc c_parseFloat(text: cstring, endPtr: ptr cstring): clongdouble {.importc: "meanParse", cdecl.}
proc c_add(leftValue: clongdouble, rightValue: clongdouble): clongdouble {.importc: "meanAdd", cdecl.}
proc c_divide(leftValue: clongdouble, rightValue: clongdouble): clongdouble {.importc: "meanDivide", cdecl.}
proc c_log(value: clongdouble): clongdouble {.importc: "meanLog", cdecl.}
proc c_exp(value: clongdouble): clongdouble {.importc: "meanExp", cdecl.}
proc c_formatValue(buffer: cstring, bufferSize: cint, value: clongdouble): cint {.importc: "meanFormatValue", cdecl.}
```

The math library is linked for the logarithm and exponential calls.
Nim arithmetic on extended floats narrows to double, so the helpers keep the full precision.
`snprintf` writes exactly nine digits with the `%.9Lf` conversion.

**Input and token reading.** All input is buffered; counts use integers and values use extended floats.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
inputData.add '\0'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextFloat(data: string, pos: var int): clongdouble =
  let startAddress = cast[cstring](unsafeAddr data[pos])
  var endAddress: cstring = nil
  result = c_parseFloat(startAddress, addr endAddress)
  pos = pos + int(cast[uint](endAddress) - cast[uint](startAddress))
```

The appended NUL gives the C parser a stable stopping point.
`nextInt` handles the case count and each number count.
The float parser advances the shared cursor by the number of characters consumed.

**Exact decimal handling.** Decimal tokens become scaled integers and round half even.

```nim
proc parseScaledToken(data: string, pos: var int, mantissa: var int64, effectiveDecimals: var int) =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  mantissa = 0
  var fractionalDigits = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    mantissa = mantissa * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      mantissa = mantissa * 10 + int64(int(data[pos]) - 48)
      fractionalDigits += 1
      pos += 1
  var exponentValue = 0
  if pos < data.len and (data[pos] == 'e' or data[pos] == 'E'):
    pos += 1
    var exponentNegative = false
    if pos < data.len and data[pos] == '-':
      exponentNegative = true
      pos += 1
    elif pos < data.len and data[pos] == '+':
      pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      exponentValue = exponentValue * 10 + int(data[pos]) - 48
      pos += 1
    if exponentNegative:
      exponentValue = -exponentValue
  effectiveDecimals = fractionalDigits - exponentValue

proc powerOfTen(exponent: int): int64 =
  result = 1
  for step in 0 .. exponent - 1:
    result = result * 10

proc formatExactArithmetic(sumScaled: int64, numberCount: int, decimalPlaces: int): string =
  var numerator: int64 = 0
  var denominator: int64 = 0
  if decimalPlaces <= decimalTarget:
    numerator = sumScaled * powerOfTen(decimalTarget - decimalPlaces)
    denominator = int64(numberCount)
  else:
    numerator = sumScaled
    denominator = int64(numberCount) * powerOfTen(decimalPlaces - decimalTarget)
  var scaledResult = numerator div denominator
  let remainder = numerator mod denominator
  let doubledRemainder = remainder * 2
  if doubledRemainder > denominator or (doubledRemainder == denominator and scaledResult mod 2 == 1):
    scaledResult += 1
  let wholePart = scaledResult div int64(decimalUnit)
  let fractionPart = scaledResult mod int64(decimalUnit)
  var fractionText = $fractionPart
  while fractionText.len < decimalTarget:
    fractionText = "0" & fractionText
  return $wholePart & "." & fractionText

proc formatLongDouble(value: clongdouble): string =
  var valueBuffer: array[lineBufferSize, char]
  discard c_formatValue(cast[cstring](addr valueBuffer[0]), cint(lineBufferSize), value)
  return $cast[cstring](addr valueBuffer[0])
```

A negative exponent lowers the effective decimal scale of its token.
The shared scale is the largest effective scale seen in the case.
Exact division plus a half-even check prevents off-by-one rounding at the ninth digit.

**Case loop.** Each case builds the three means and writes one buffered line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberCount = nextInt(inputData, scanPos)
  let caseStartPos = scanPos
  var tokenMantissas = newSeq[int64](numberCount)
  var tokenDecimals = newSeq[int](numberCount)
  var maxDecimals = 0
  for valueIndex in 0 .. numberCount - 1:
    parseScaledToken(inputData, scanPos, tokenMantissas[valueIndex], tokenDecimals[valueIndex])
    if tokenDecimals[valueIndex] > maxDecimals:
      maxDecimals = tokenDecimals[valueIndex]
  var sumScaled: int64 = 0
  for valueIndex in 0 .. numberCount - 1:
    sumScaled = sumScaled + tokenMantissas[valueIndex] * powerOfTen(maxDecimals - tokenDecimals[valueIndex])
  let arithmeticText = formatExactArithmetic(sumScaled, numberCount, maxDecimals)
  scanPos = caseStartPos
  var sumLogs: clongdouble = 0
  var sumReciprocals: clongdouble = 0
  for valueIndex in 0 .. numberCount - 1:
    let currentValue = nextFloat(inputData, scanPos)
    sumLogs = c_add(sumLogs, c_log(currentValue))
    sumReciprocals = c_add(sumReciprocals, c_divide(clongdouble(1), currentValue))
  let count: clongdouble = clongdouble(numberCount)
  let geometricMean: clongdouble = c_exp(c_divide(sumLogs, count))
  let harmonicMean: clongdouble = c_divide(count, sumReciprocals)
  appendOutput(arithmeticText & " " & formatLongDouble(geometricMean) & " " & formatLongDouble(harmonicMean) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The token cursor returns to the case start for the float pass.
`sumLogs` and `sumReciprocals` accumulate through extended precision helpers.
The arithmetic line comes from exact integers; the other two use nine-digit formatting.

## Complexity

Each case performs a bounded number of passes over its values.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | input string |
| exact decimal sum | one visit per value | two arrays of case size |
| log and reciprocal sums | one visit per value | two extended accumulators |
| output | one line per case | block buffer |

Total cost grows with the number of values across all cases.

| measure | Big O |
|---|---|
| time | O(n) per case |
| space | O(n) per case |

Multiplying every value for the geometric mean would overflow; summing logs keeps each step bounded.
