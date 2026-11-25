# ROLLBALL — The Rolling Ball (SPOJ)

<https://www.spoj.com/problems/ROLLBALL/>

## Problem

A ball rolls without slipping inside a cone and traces a horizontal circle. Find the radius of the circle of contact points on the ball when the ball's speed grows without bound.

Each input line holds three integers `l`, `R`, and `u`, in that order. `l` is the radius of the circle traced by the ball's centre, `R` is the ball radius, and `u` is the cone half-angle in degrees. Print one rounded integer per line, until end of input.

| item | bound |
|---|---|
| centre radius `l` | R < l ≤ 1000000 |
| ball radius `R` | 0 < R ≤ 1000 |
| cone angle `u` | 0 < u < 90 degrees |
| judge limit | 200 ms, 1536 MB |

The condition R < l keeps the ball inside the cone.

Sample input:

```
220000 100 29
```

Sample output:

```
46
```

## Idea

Picture the contact circle as the rim of a spinning top; as the speed rises, the top's axis tilts to a steady angle. That tilt fixes the circle radius, so one closed-form evaluation replaces any search over speeds. Convert degrees to radians, take sine and cosine, and evaluate the derived ratio. A numerical spin simulation would repeat small steps for every candidate speed and still miss the infinite-speed limit; one formula gives the limit directly.

The table gives the cost of each input line.

| item | bound |
|---|---|
| work per line | constant |
| work per input | one pass over lines |

This cost shape makes the problem a pure formula evaluation.

## Why It Works

1. The contact point sits at distance `R` from the ball centre along the cone normal.
2. The cone normal makes angle 90 - u with the downward vertical.
3. Gravity drops out of the angular equation as the orbital speed grows without bound.
4. The rolling constraint fixes the spin components around the centre and vertical axes.
5. The contact circle radius equals `R` times the sine of the angle between the contact normal and the spin axis.
6. Algebra cancels the spin factor and leaves a ratio that depends on l / R and `u`.

The table names the values used in the code.

| term | meaning |
|---|---|
| `radiusRatio` | centre radius divided by ball radius |
| `sineValue` | sine of the cone angle in radians |
| `cosineValue` | cosine of the cone angle in radians |
| `crossTerm` | mixed square term in the denominator |
| `squareTerm` | leading square term in the denominator |
| `contactCircleRadius` | radius of the contact circle on the ball |

Each term maps directly to one line of the formula.

The worked example uses the sample line 220000 100 29. The script prints the intermediate values below.

```
sineValue      = 0.484810
cosineValue    = 0.874620
radiusRatio    = 2200
crossTerm      = 6109.607026
squareTerm     = 17637948.031251
denominator    = 4200.483115
contactCircleRadius = 45.826355
answer         = 46
```

The final step adds one half and truncates, which rounds 45.826355 to 46.

## Code

**Input and output helpers.** The reader loads all lines and exposes a digit scanner and a block writer.

```nim
import math

const flushBlockBytes = 1 shl 17
const degreesToRadians = 0.017453292519943295
const spinFactor = 2.5
const largeSpinFactor = 11.25

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

proc hasAnotherNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips spaces and line breaks between triples. The guard stops at end of input instead of inventing zero values. The writer flushes only after the buffer reaches its block size.

**Formula evaluation.** Each triple is converted to radians and evaluated in constant time.

```nim
while hasAnotherNumber(inputData, scanPos):
  let centerRadius = nextInt(inputData, scanPos)
  let ballRadius = nextInt(inputData, scanPos)
  let coneDegrees = nextInt(inputData, scanPos)
  let angle = float(coneDegrees) * degreesToRadians
  let sineValue = sin(angle)
  let cosineValue = cos(angle)
  let radiusRatio = float(centerRadius) / float(ballRadius)
  let sineSquared = sineValue * sineValue
  let cosineSquared = cosineValue * cosineValue
  let crossTerm = 2.0 * cosineValue * radiusRatio * (1.0 + spinFactor * sineSquared)
  let squareTerm = radiusRatio * radiusRatio * (1.0 + largeSpinFactor * sineSquared)
  let denominator = sqrt(cosineSquared + crossTerm + squareTerm)
  let contactCircleRadius = float(ballRadius) * cosineValue * (radiusRatio + cosineValue) / denominator
  appendOutput($(int(contactCircleRadius + 0.5)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

All intermediate values stay in double precision. The ratio can reach one million, so the square term still fits comfortably. The final flush emits the last buffered line.

## Complexity

The work is one formula evaluation per input line.

| phase | time | space |
|---|---|---|
| input read | one pass over all bytes | one input string |
| formula | constant work per triple | constant |
| output | one write per block | block buffer |

The input string dominates memory use.

| measure | Big O |
|---|---|
| time | O(L) for L input lines |
| space | O(I) for I input bytes |

A numerical spin simulation needs many steps per speed and still approximates the limit; this code needs one arithmetic expression per line.
