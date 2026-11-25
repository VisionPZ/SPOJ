# GCJ1C09B — Center of Mass (SPOJ)

<https://www.spoj.com/problems/GCJ1C09B/>

## Problem

Fireflies move at constant velocity from known starting points. Their centre of mass traces a straight line through space. Report its smallest distance from the origin and the earliest time that distance occurs.

Input starts with T cases. Each case gives N, then N lines of x y z vx vy vz with integer values from -5000 to 5000. Output `Case #X: dmin tmin`, with eight decimals and an error below 10^-6.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| fireflies N | 3 to 500 |
| each coordinate or velocity | -5000 to 5000 |
| judge limit | 1000 ms, 1536 MB |

T times N sets the input size; the geometry stays the same for every case.

The sample input:

```
3
3
3 0 -4 0 0 3
-3 -2 -1 3 0 0
-3 -1 2 0 3 0
3
-5 0 0 1 0 0
-7 0 0 1 0 0
-6 3 0 1 0 0
4
1 2 3 1 2 3
3 2 1 3 2 1
1 0 0 0 0 -1
0 10 0 0 -10 -1
```

The sample output:

```
Case #1: 0.00000000 1.00000000
Case #2: 1.00000000 6.00000000
Case #3: 3.36340601 1.00000000
```

## Idea

The average of moving points moves in a straight line, like the average position of a group of walkers on parallel paths. Sum the positions and velocities once, then minimise the squared norm of one linear function of time. That norm is a quadratic, so its vertex gives the best time directly. Walking time forwards in small steps would only approximate the vertex and waste work. One dot product and one division give the exact time for each case.

## Why It Works

1. The centre of mass equals the sum of positions divided by N, and its velocity equals the sum of velocities divided by N.
2. Write S for the position sum and D for the velocity sum, so the centre is (S + Dt) / N.
3. The squared distance is a quadratic in t with leading coefficient |D|^2 and linear coefficient 2 S dot D.
4. Its vertex is at t = -(S dot D) / |D|^2, which is negative when the swarm moves away from the origin.
5. Negative or zero time is clipped to zero, because the statement only allows t at or after zero.

| term | meaning |
|---|---|
| `crossTerm` | dot product of position sum and velocity sum |
| `speedTerm` | squared norm of the velocity sum |
| `bestTime` | vertex time, clipped to zero when needed |
| `closestDistance` | norm of the centre at `bestTime` |

The table names the four values computed per case.

A script trace of the second sample case:

```
position sum S = (-18, 3, 0)
velocity sum D = (3, 0, 0)
S dot D = -18*3 + 3*0 + 0*0 = -54
|D|^2 = 3*3 = 9
best time = 54 / 9 = 6
centre at t=6 = ((-18+18)/3, 3/3, 0) = (0, 1, 0)
distance = 1
```

The trace gives distance 1 at time 6, matching the second sample answer.

Eight decimals exceed the 10^-6 error limit. The time clip handles swarms that only move away from the origin.

## Code

**Input and scanner.** The reader loads all lines and parses signed integers by hand.

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
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

The scanner keeps a sign branch for negative coordinates.
`math` supplies the square root and `strutils` supplies the fixed formatting.
The scan position advances once per integer.

**Output helper.** One buffer collects every formatted answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes in large blocks.
A final flush writes any remainder.
No write happens per firefly.

**Quadratic minimum.** Each case sums coordinates, finds the vertex, and formats the result.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let fireflyCount = nextInt(inputData, scanPos)
  var positionX: int64 = 0
  var positionY: int64 = 0
  var positionZ: int64 = 0
  var velocityX: int64 = 0
  var velocityY: int64 = 0
  var velocityZ: int64 = 0
  for fireflyIndex in 0 .. fireflyCount - 1:
    positionX += int64(nextInt(inputData, scanPos))
    positionY += int64(nextInt(inputData, scanPos))
    positionZ += int64(nextInt(inputData, scanPos))
    velocityX += int64(nextInt(inputData, scanPos))
    velocityY += int64(nextInt(inputData, scanPos))
    velocityZ += int64(nextInt(inputData, scanPos))
  let crossTerm = float64(positionX * velocityX + positionY * velocityY +
                          positionZ * velocityZ)
  let speedTerm = float64(velocityX * velocityX + velocityY * velocityY +
                          velocityZ * velocityZ)
  var bestTime = 0.0
  if speedTerm > 0.0 and crossTerm < 0.0:
    bestTime = -crossTerm / speedTerm
  let centerX = (float64(positionX) + float64(velocityX) * bestTime) /
                float64(fireflyCount)
  let centerY = (float64(positionY) + float64(velocityY) * bestTime) /
                float64(fireflyCount)
  let centerZ = (float64(positionZ) + float64(velocityZ) * bestTime) /
                float64(fireflyCount)
  let closestDistance = sqrt(centerX * centerX + centerY * centerY +
                             centerZ * centerZ)
  appendOutput("Case #" & $caseNumber & ": " &
               formatFloat(closestDistance, ffDecimal, 8) & " " &
               formatFloat(bestTime, ffDecimal, 8) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Sums stay in `int64` because each term is small.
The vertex uses floats because the answer is continuous.
Eight printed decimals satisfy the error limit.

## Complexity

Each case reads its fireflies once and then does constant geometry work.

| phase | time | space |
|---|---|---|
| input read | six integers per firefly | one input string |
| sums | six additions per firefly | six running totals |
| vertex and output | one quadratic evaluation per case | one buffer |

Reading dominates the arithmetic for large N.

| measure | Big O |
|---|---|
| time | O(N) per case |
| space | O(1) beyond input |

Stepping time forward to locate the minimum would cost many evaluations per case. The quadratic vertex replaces that search with one division.
