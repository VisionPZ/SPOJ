# REBOUND — The return of the Cake (SPOJ)

<https://www.spoj.com/problems/REBOUND/>

## Problem

A cake starts at height `z` above the ground and must bounce once before reaching a target at height `y`. Find the whole-number bounce point, or report that no such point exists.

Each test case gives three integers `x`, `y`, `z`. The thrower stands at `(0, z)` and the target stands at `(x, y)`. The bounce point is `(t, 0)` with `0 <= t <= x`. The angle after the bounce is twice the angle before it, both measured from the ground. Print the only integer `t` that works, or `Not this time.`.

| item | bound |
|---|---|
| test cases T | 1 to 99999 |
| horizontal distance x | 1 to 999999999 |
| target height y | 1 to 999999999 |
| throw height z | 1 to 999999999 |
| judge limit | 1000 ms, 1536 MB |

All three coordinates are positive, so the reflection point always lies between the two people.

Sample input:

```
3
5 4 1
6 5 2
7 3 1
```

Sample output:

```
2
Not this time.
3
```

## Idea

Treat the bounce like a mirror with a doubled angle, then turn the angle rule into one quadratic equation, the way a surveyor turns two sight lines into one triangle.

The incoming angle has tangent `z/t`. The outgoing angle has tangent `y/(x-t)`. Doubling an angle turns the first tangent into `2zt/(t*t - z*z)`. Equating the two tangents gives `(y + 2z)t*t - 2zxt - yz*z = 0`.

Only one root is positive. That root is `t = z(x + sqrt(x*x + y*y + 2yz))/(y + 2z)`. An integer answer needs a perfect-square discriminant and an exact division. A binary search finds the square root in 31 steps, so each case costs constant time. A loop over every possible `t` would cost `x` steps instead. Check the integer test first, then trust the closed form.

## Why It Works

1. The slope from the thrower to the ground point is `z/t`.
2. The slope from the ground point to the target is `y/(x-t)`.
3. Doubling the incoming angle changes its tangent to `2u/(1-u*u)` with `u = z/t`.
4. Cross-multiplying the two slopes gives the quadratic equation above.
5. The other quadratic root is negative, because the square root exceeds `x`.
6. An integer `t` exists only when the discriminant is a perfect square and the division has no remainder.

| term | meaning |
|---|---|
| `horizontalDistance` | value x, the horizontal gap between the people |
| `targetHeight` | value y, the height of the target |
| `throwHeight` | value z, the height of the thrower |
| `discriminant` | `x*x + y*y + 2*y*z`, the value under the square root |
| `reflectionRoot` | integer square root of `discriminant` |
| `landingPoint` | candidate value t, checked before printing |

The table names every value used by the final formula.

A script-traced example for the first sample case:

| step | value |
|---|---|
| coordinates | `x = 5`, `y = 4`, `z = 1` |
| discriminant | `25 + 16 + 8 = 49` |
| square root | `7`, because `7 * 7 = 49` |
| numerator | `1 * (5 + 7) = 12` |
| denominator | `4 + 2 = 6` |
| landing point | `12 / 6 = 2`, which lies in `[0, 5]` |

The trace reproduces the sample answer `2`.

Rounding never enters the solution because all tests use exact integers. The binary search returns the largest square not exceeding the discriminant, so equality proves a perfect square. The remainder test proves that the landing point is a whole number.

## Code

**Shared input and output helpers.** The reader loads stdin once, and the writer flushes in large blocks.

```nim
const flushBlockBytes = 1 shl 17
const rootSearchLimit = 2000000000

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips all separators between numbers.
Both signed inputs are absent here, so no minus branch is needed.
A single buffer keeps writes rare even for 100000 cases.

**Integer square root.** A binary search avoids floating point error.

```nim
proc integerSquareRoot(value: int64): int64 =
  var lowValue: int64 = 0
  var highValue: int64 = rootSearchLimit
  while lowValue < highValue:
    let middleValue = (lowValue + highValue + 1) div 2
    if middleValue * middleValue <= value:
      lowValue = middleValue
    else:
      highValue = middleValue - 1
  return lowValue
```

The search covers every possible discriminant.
Each squaring stays inside 64 bits.
The result is the largest square root not exceeding the input.

**Case loop.** Each case tests the perfect square, then the exact division, then the range.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let horizontalDistance = int64(nextInt(inputData, scanPos))
  let targetHeight = int64(nextInt(inputData, scanPos))
  let throwHeight = int64(nextInt(inputData, scanPos))
  let discriminant = horizontalDistance * horizontalDistance +
                     targetHeight * targetHeight + 2 * targetHeight * throwHeight
  let reflectionRoot = integerSquareRoot(discriminant)
  if reflectionRoot * reflectionRoot != discriminant:
    appendOutput("Not this time.\n")
  else:
    let numeratorValue = throwHeight * (horizontalDistance + reflectionRoot)
    let denominatorValue = targetHeight + 2 * throwHeight
    if numeratorValue mod denominatorValue != 0:
      appendOutput("Not this time.\n")
    else:
      let landingPoint = numeratorValue div denominatorValue
      if landingPoint < 0 or landingPoint > horizontalDistance:
        appendOutput("Not this time.\n")
      else:
        appendOutput($landingPoint)
        outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Products and sums use 64-bit values.
The three guards reject all non-integer and out-of-range shots.
The loop writes one line per case and flushes once at the end.

## Complexity

Each case performs one fixed-size square-root search and one division.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| square-root search | 31 steps per case | constant |
| output | one buffered write per block | one output string |

The phase table shows that no work grows with the coordinates.

| measure | Big O |
|---|---|
| time | O(T log C), where C is the largest coordinate |
| space | O(input size) |

A scan over every candidate `t` would cost O(x) per case; the closed form costs a few dozen steps.
