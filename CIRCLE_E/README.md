# CIRCLE_E — Three Circle Problem (EASY) (SPOJ)

<https://www.spoj.com/problems/CIRCLE_E/>

## Problem

Three circles touch each other pairwise. Compute the radius of the fourth circle that fits in the gap and touches all three. Print each answer with six digits after the decimal point.

| item | bound |
|---|---|
| test cases T | 1 to 1000 |
| radii R1, R2, R3 | 1 to 999999999 |
| accepted error | absolute error below 1e-6 |
| judge limit | 1000 ms, 1536 MB |

Curvature is the reciprocal of radius. Descartes' circle theorem writes the inner curvature as a sum plus a square root.

Sample input:

```
3
1 1 1
10 10 10
23 46 69
```

Sample output:

```
0.154701
1.547005
6.000000
```

## Idea

Curvature turns a tangent-circle sum into a familiar budget: three contributions plus a shared square-root term. Descartes' theorem gives the inner curvature in one formula, so each test case costs a constant number of operations. A geometric construction with triangle areas would require solving equations for every case and adding avoidable work. Use the curvature formula and format the fixed-point result directly.

## Why It Works

1. Define curvature as k = 1/R for each circle.
2. Descartes' theorem gives the inner curvature k4 = k1 + k2 + k3 + 2*sqrt(k1*k2 + k2*k3 + k3*k1).
3. The inner radius is the reciprocal of k4.
4. The outer tangent circle would use a minus sign; the gap circle uses a plus sign.
5. Scaling all three radii by s scales the answer by s, which matches the sample's second line.

| term | meaning |
|---|---|
| `curvatureSum` | k1 + k2 + k3 |
| `crossSum` | sum of the three pairwise curvature products |
| `innerRadius` | reciprocal of the full inner curvature |
| `fixedSix` | helper that rounds into six decimal places |

For three equal radii of one, curvatureSum is 3 and crossSum is 3. The inner curvature is 3 + 2*sqrt(3) = 6.464101, so the radius is 0.154701.

| radii | curvatureSum | crossSum | printed radius |
|---|---|---|---|
| 1 1 1 | 3 | 3 | 0.154701 |
| 10 10 10 | 0.3 | 0.03 | 1.547005 |
| 23 46 69 | 0.079710 | 0.001449 | 6.000000 |

The scaled integer keeps rounding stable for large and small radii alike.

## Code

**Input and scanner.** The reader loads the whole input and extracts integers by hand.

```nim
import math

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

Whitespace and line breaks do not affect token parsing.
The scanner stops after the final numeric character.

**Output helper.** Float results become a fixed six-place string through one integer scale.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fixedSix(value: float): string =
  var scaled: int64 = int64(value * 1000000.0 + 0.5)
  var whole = scaled div 1000000
  var fraction = scaled mod 1000000
  result = $whole
  result.add '.'
  var divisor: int64 = 100000
  while divisor > 0:
    result.add char(48 + int(fraction div divisor))
    fraction = fraction mod divisor
    divisor = divisor div 10
```

The 0.5 term implements rounding to the nearest unit.
Leading zeros in the fraction are written explicitly.

**Main loop.** Each case applies Descartes' theorem and appends one line.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let radiusOne = float(nextInt(inputData, scanPos))
  let radiusTwo = float(nextInt(inputData, scanPos))
  let radiusThree = float(nextInt(inputData, scanPos))
  let curvatureSum = 1.0 / radiusOne + 1.0 / radiusTwo + 1.0 / radiusThree
  let crossSum = 1.0 / (radiusOne * radiusTwo) + 1.0 / (radiusTwo * radiusThree) + 1.0 / (radiusThree * radiusOne)
  let innerRadius = 1.0 / (curvatureSum + 2.0 * sqrt(crossSum))
  appendOutput(fixedSix(innerRadius))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

All reciprocals use floating point, as required by the judge comments.
One final flush writes the buffered lines.

## Complexity

The formula runs in constant time for each test case.

| phase | time | space |
|---|---|---|
| input read | one pass over the token stream | one input string |
| formula | constant work per case | constant working storage |
| output | six-place line per case | one block buffer |

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(1) beyond input and output buffers |

A triangle-area construction would solve several equations per case and lose this constant-time path.

The curvature formula keeps every case short and exact within the required tolerance.
