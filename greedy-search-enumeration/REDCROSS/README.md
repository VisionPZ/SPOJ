# REDCROSS — Red Cross Hospital (SPOJ)

<https://www.spoj.com/problems/REDCROSS/>

## Problem

Find one point whose farthest distance to a given set of communities is as small as possible. Print that point for each test case until a case size of zero ends the input.

Each test case starts with integer `N`, followed by `N` lines holding decimal coordinates `X` and `Y`. Print `X, Y` on one line with four digits after the decimal point and a space after the comma.

The statement gives these bounds:

| item | bound |
|---|---|
| communities N | 0 to 100000, with N = 0 ending input |
| coordinates X, Y | -100000 to 100000 |
| repeated coordinates | absent within one test case |
| judge limit | 1000 ms, 1536 MB |

The size bound favors an expected linear algorithm over checking every point triple.

Sample input:

```
2
-1 0
1 0
4
0.5 0.5
0.5 -0.5
0.0 0.5
0.0 -0.5
0
```

Sample output:

```
0.0000, 0.0000
0.2500, 0.0000
```

## Idea

Picture stretching a rubber band around pins: it settles around two pins or three pins, never more.

The smallest enclosing circle is fixed by at most three boundary points. Randomized incremental construction adds points one at a time and rebuilds only when the new point escapes the current circle. Each rebuild walks a nested loop whose expected total work stays linear.

Checking all triples costs cubic time. The incremental rebuild touches a triple only when it can improve the circle. The takeaway is to let boundary points decide the circle, then test membership with squared distances.

## Why It Works

1. A circle containing all points must contain the boundary points that define it.
2. Adding a point that lies inside the circle leaves the circle unchanged.
3. A point outside the circle must lie on the boundary of the new circle.
4. A boundary circle for one point has radius zero; for two points it uses their midpoint.
5. Three boundary points determine a unique circle unless they are collinear.
6. Squared distance comparisons avoid a square root in the membership test.

The main terms are listed here:

| term | meaning |
|---|---|
| `centerX` | x coordinate of the current circle center |
| `radius` | radius of the current circle |
| `pointX` | shuffled community coordinate |
| `radiusSlack` | tiny tolerance added to the squared radius |

Shuffling makes the expected number of rebuilds small.

A script trace for the second sample case lists candidate circles:

| boundary points | candidate center | radius |
|---|---|---|
| (0.5, 0.5), (0.5, -0.5) | (0.5, 0) | 0.5 |
| (0, 0.5), (0, -0.5) | (0, 0) | 0.5 |
| (0.5, 0.5), (0, 0.5), (0, -0.5) | (0.25, 0) | 0.5590 |

Only the third circle contains all four points, so the printed center is `0.2500, 0.0000`.

Guard: values near zero print as `0.0000`, so no negative zero reaches the output.

## Code

**Input and decimal reader.** The scanner reads signed decimal coordinates into floating point values.

```nim
import math, strutils

const flushBlockBytes = 1 shl 17
const radiusSlack = 1e-9

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

proc nextDecimal(data: string, pos: var int): float64 =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1.0
  if pos < data.len and data[pos] == '-':
    signValue = -1.0
    pos += 1
  var wholePart = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  var fractionPart = 0.0
  var scaleValue = 1.0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionPart = fractionPart * 10.0 + float64(int(data[pos]) - 48)
      scaleValue = scaleValue * 10.0
      pos += 1
  return signValue * (wholePart + fractionPart / scaleValue)

proc squaredDistance(pointX: float64, pointY: float64, centerX: float64, centerY: float64): float64 =
  let diffX = pointX - centerX
  let diffY = pointY - centerY
  return diffX * diffX + diffY * diffY
```

Integer sizes use the hand scanner, while coordinates use the decimal reader.
Fraction digits are accumulated with a power-of-ten scale.
Squared distance keeps the hot membership test free of square roots.

**Circle constructors.** Two points give a diameter; three points give a circumcircle.

```nim
proc setFromPair(pointX: float64, pointY: float64, otherX: float64, otherY: float64, centerX: var float64, centerY: var float64, radius: var float64) =
  centerX = (pointX + otherX) / 2.0
  centerY = (pointY + otherY) / 2.0
  radius = sqrt(squaredDistance(pointX, pointY, centerX, centerY))

proc setFromTriple(firstX: float64, firstY: float64, secondX: float64, secondY: float64, thirdX: float64, thirdY: float64, centerX: var float64, centerY: var float64, radius: var float64) =
  let divisor = 2.0 * (firstX * (secondY - thirdY) + secondX * (thirdY - firstY) + thirdX * (firstY - secondY))
  if divisor > -1e-12 and divisor < 1e-12:
    let firstSecond = squaredDistance(firstX, firstY, secondX, secondY)
    let firstThird = squaredDistance(firstX, firstY, thirdX, thirdY)
    let secondThird = squaredDistance(secondX, secondY, thirdX, thirdY)
    if firstSecond >= firstThird and firstSecond >= secondThird:
      setFromPair(firstX, firstY, secondX, secondY, centerX, centerY, radius)
    elif firstThird >= secondThird:
      setFromPair(firstX, firstY, thirdX, thirdY, centerX, centerY, radius)
    else:
      setFromPair(secondX, secondY, thirdX, thirdY, centerX, centerY, radius)
    return
  let firstNorm = firstX * firstX + firstY * firstY
  let secondNorm = secondX * secondX + secondY * secondY
  let thirdNorm = thirdX * thirdX + thirdY * thirdY
  centerX = (firstNorm * (secondY - thirdY) + secondNorm * (thirdY - firstY) + thirdNorm * (firstY - secondY)) / divisor
  centerY = (firstNorm * (thirdX - secondX) + secondNorm * (firstX - thirdX) + thirdNorm * (secondX - firstX)) / divisor
  radius = sqrt(squaredDistance(firstX, firstY, centerX, centerY))
```

The collinear branch falls back to the farthest pair as a diameter.
The circumcircle uses the standard solved linear system.
Each constructor writes through the three output parameters.

**Formatting and shuffling.** Fixed formatting handles the four-decimal contract and a small generator mixes the points.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fixedText(value: float64): string =
  if value > -0.00005 and value < 0.00005:
    return formatFloat(0.0, ffDecimal, 4)
  return formatFloat(value, ffDecimal, 4)

var randomState = 2463534242'u32

proc nextRandom(): uint32 =
  randomState = randomState xor (randomState shl 13'u32)
  randomState = randomState xor (randomState shr 17'u32)
  randomState = randomState xor (randomState shl 5'u32)
  return randomState
```

Values below half the last printed digit become zero.
The xorshift generator avoids a dependency on a random library.
The buffered writer emits one line per test case.

**Incremental construction.** Each escaping point rebuilds the circle with nested boundary loops.

```nim
while true:
  let communityCount = nextInt(inputData, scanPos)
  if communityCount == 0:
    break
  var pointX = newSeq[float64](communityCount)
  var pointY = newSeq[float64](communityCount)
  for pointIndex in 0 .. communityCount - 1:
    pointX[pointIndex] = nextDecimal(inputData, scanPos)
    pointY[pointIndex] = nextDecimal(inputData, scanPos)
  var shuffleIndex = communityCount - 1
  while shuffleIndex >= 1:
    let swapIndex = int(nextRandom() mod uint32(shuffleIndex + 1))
    let keptX = pointX[shuffleIndex]
    let keptY = pointY[shuffleIndex]
    pointX[shuffleIndex] = pointX[swapIndex]
    pointY[shuffleIndex] = pointY[swapIndex]
    pointX[swapIndex] = keptX
    pointY[swapIndex] = keptY
    shuffleIndex -= 1

  var centerX = 0.0
  var centerY = 0.0
  var radius = -1.0
  for pointIndex in 0 .. communityCount - 1:
    let currentX = pointX[pointIndex]
    let currentY = pointY[pointIndex]
    if radius >= 0.0 and squaredDistance(currentX, currentY, centerX, centerY) <= radius * radius + radiusSlack:
      continue
    setFromPair(currentX, currentY, currentX, currentY, centerX, centerY, radius)
    for firstIndex in 0 .. pointIndex - 1:
      let firstX = pointX[firstIndex]
      let firstY = pointY[firstIndex]
      if squaredDistance(firstX, firstY, centerX, centerY) <= radius * radius + radiusSlack:
        continue
      setFromPair(currentX, currentY, firstX, firstY, centerX, centerY, radius)
      for secondIndex in 0 .. firstIndex - 1:
        let secondX = pointX[secondIndex]
        let secondY = pointY[secondIndex]
        if squaredDistance(secondX, secondY, centerX, centerY) <= radius * radius + radiusSlack:
          continue
        setFromTriple(currentX, currentY, firstX, firstY, secondX, secondY, centerX, centerY, radius)
  appendOutput(fixedText(centerX) & ", " & fixedText(centerY))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A negative radius marks the empty circle before the first point.
Each nested loop pins another boundary point when a check fails.
The terminated case writes the accumulated lines once.

## Complexity

Shuffling and incremental rebuilds set the expected cost.

| phase | time | space |
|---|---|---|
| input read | one pass over N coordinate pairs | two point arrays |
| shuffle | one pass over N points | constant |
| incremental circle | expected linear in N | constant beyond points |
| output | one line per case | block buffer |

The nested rebuild loops have cubic worst case but tiny expected cost.

| measure | Big O |
|---|---|
| time | O(N) expected per case |
| space | O(N) per case |

Testing every point triple would cost O(N^3). Random order keeps rebuild work small on average, which is the takeaway.
