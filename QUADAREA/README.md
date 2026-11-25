# QUADAREA — Maximal Quadrilateral Area (SPOJ)

<https://www.spoj.com/problems/QUADAREA/>

## Problem

Given four side lengths, report the largest area any quadrilateral with those sides can have. The optimal shape is cyclic, so one formula covers every test.

Each test gives four real numbers `a b c d` on one line. The first input line gives the test count `T`. Print one area per test, rounded to two decimals; an error under 0.01 passes.

| item | bound |
|---|---|
| tests T | 1 to 2000 |
| each side | greater than 0 and less than 1000 |
| validity | any three sides exceed the fourth |
| judge limit | 1000 ms, 1536 MB |

The cyclic guarantee drives the design: no search over shapes is needed.

Sample input:

```
2
1 2 1 2
0.5 0.5 0.5 0.5
```

Sample output:

```
2.00
0.25
```

## Idea

Treat the four walls like a hinged frame: it opens widest when its corners lie on one circle. Brahmagupta's formula gives that widest area from the four sides alone. It costs four additions and one square root per test, while trying many shapes by simulation costs far more. Take the formula as the whole algorithm.

## Why It Works

1. Among all quadrilaterals with fixed sides, the cyclic one has the largest area.
2. Let `s` be half the perimeter, called the semiperimeter.
3. Brahmagupta's formula gives area as the square root of `(s-a)(s-b)(s-c)(s-d)`.
4. The area does not depend on the order of the four sides.
5. Clamping a tiny negative product to zero guards against floating point drift.

| term | meaning |
|---|---|
| `semiperimeter` | half of `a+b+c+d` |
| `areaProduct` | the product `(s-a)(s-b)(s-c)(s-d)` |
| `largestArea` | square root of `areaProduct` |

Every symbol in the formula comes from the four input numbers.

A script trace for `1 2 1 2` gives `s = 3`, factors `2, 1, 2, 1`, product `4`, and area `2.00`. For `0.5 0.5 0.5 0.5` it gives `s = 1`, four factors of `0.5`, product `0.0625`, and area `0.25`.

These two traces match the sample output exactly.

## Code

**Input and scanning.** A hand reader loads the whole input, then parses integers and reals token by token.

```nim
import math
import strutils

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

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.':
    pos += 1
  var whole = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    whole = whole * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var fraction = 0.0
    var scale = 10.0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fraction = fraction + float64(int(data[pos]) - 48) / scale
      scale = scale * 10.0
      pos += 1
    whole = whole + fraction
  return whole
```

The scanner skips spaces and line breaks between numbers.
It accepts both `2` and `0.500` with the same code path.
Parsing runs once over the input string.

**Output buffer.** Text accumulates in one string and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer keeps writes rare even with two thousand answers.
A final write empties any remaining text.

**Formula loop.** Each test evaluates the formula once and writes a rounded answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sideFirst = nextReal(inputData, scanPos)
  let sideSecond = nextReal(inputData, scanPos)
  let sideThird = nextReal(inputData, scanPos)
  let sideFourth = nextReal(inputData, scanPos)
  let semiperimeter = (sideFirst + sideSecond + sideThird + sideFourth) / 2.0
  var areaProduct = (semiperimeter - sideFirst) * (semiperimeter - sideSecond) * (semiperimeter - sideThird) * (semiperimeter - sideFourth)
  if areaProduct < 0.0:
    areaProduct = 0.0
  let largestArea = sqrt(areaProduct)
  appendOutput(formatFloat(largestArea, ffDecimal, 2))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly `caseCount` times.
The guard keeps `sqrt` away from negative inputs caused by rounding.
`formatFloat` prints two digits after the decimal point.

## Complexity

Each test does a fixed amount of arithmetic, so total cost grows linearly with `T`.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| formula loop | four adds and one root per test | constant |
| output | one write per buffer block | block buffer |

The input string and the answer buffer dominate memory use.

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(T) for input and output text |

Trying many shapes would cost far more than one formula per test. The formula makes every additional test cheap.
