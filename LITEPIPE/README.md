# LITEPIPE — GX Light Pipeline Inc (SPOJ)
<https://www.spoj.com/problems/LITEPIPE/>

## Problem

A light source shines into a bent pipe, and the design team needs the furthest point the light can reach. The pipe walls block every ray that leaves the corridor.

The input holds many cases. Each starts with a bend count, then one pair of real coordinates per bend. A zero count ends the input. Print the furthest reachable x with two decimal places.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Bend points `n` | at most 200 |
| Coordinate order | x values strictly increasing |
| Output | two decimals, or final x |
| Judge time | 1000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

The small bend count allows pairwise tests.

Sample input and output:

Input:

```
4
0.000000 1.000000
2.000000 2.000000
4.000000 1.000000
6.000000 4.000000
0
```

Output:

```
4.67
```

## Idea

Find the furthest x where one straight ray still fits. Think of aiming a laser down a bent corridor and sliding the target outward.

The program binary searches (halves a range) the reachable x. For a trial x, it intersects slope intervals from every pair of bend points. Each feasibility test costs O(n^2), and sixty halvings pin the answer. Sampling rays one by one could never certify the last reachable point.

Takeaway: interval intersection decides a whole corridor at once.

## Why It Works

A ray exists exactly when its slope lies in every pairwise interval.

1. The pipe has height one, so the ray height at each bend lies between the upper point and that point minus one.
2. Subtracting two bend constraints bounds their slope difference by one.
3. Pair `i, j` then allows slopes between `(yj - yi - 1) / dx` and `(yj - yi + 1) / dx`.
4. `feasibleAt` intersects all such intervals and adds a cut point at the trial x.
5. `furthestReach` halves the range until the last feasible x is found.

The terms are:

| Term | Meaning |
| --- | --- |
| `upperX`, `upperY` | Bend coordinates of the upper wall |
| `span` | x gap across the cut point |
| `slopeLow` | Lowest slope still allowed |
| `slopeHigh` | Highest slope still allowed |

An empty intersection means no ray fits.

A script traced the sample pipe:

| Trial x | Cut height | Slope interval | Feasible |
| --- | --- | --- | --- |
| 2.00 | no cut | [0.0000, 1.0000] | yes |
| 4.00 | no cut | [0.0000, 0.0000] | yes |
| 4.666667 | 2.0000 | [0.0000, 0.0000] | yes |
| 4.67 | 2.0050 | [0.0011, 0.0000] | no |

The search prints `4.67`, and the printer rounds half up.

## Code

**Constants.**

```nim
const
  readChunkBytes = 1 shl 16
  flushBlockBytes = 1 shl 18
  firstDigitValue = 48
  maxBentPoints = 200
  searchIterations = 60
```

`maxBentPoints` fixes the table size. Sixty iterations give far more precision than two decimals need.

**Chunked input.**

```nim
var inputData = newString(readChunkBytes)
var bytesRead = 0
while true:
  if bytesRead + readChunkBytes > inputData.len:
    inputData.setLen(inputData.len * 2)
  let chunkSize = stdin.readBuffer(addr inputData[bytesRead], readChunkBytes)
  if chunkSize == 0:
    break
  bytesRead += chunkSize
inputData.setLen(bytesRead)
```

The input buffer doubles until the stream ends. One pass reads every case. No line parser is needed.

**Integer and real scanners.**

```nim
proc skipWhite(data: string, i: var int) =
  while i < data.len and (data[i] == ' ' or data[i] == '\n' or
      data[i] == '\r' or data[i] == '\t'):
    i += 1

proc nextInt(data: string, i: var int): int =
  skipWhite(data, i)
  var negative = false
  if i < data.len and data[i] == '-':
    negative = true
    i += 1
  elif i < data.len and data[i] == '+':
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + (ord(data[i]) - firstDigitValue)
    i += 1
  if negative:
    value = -value
  result = value

proc nextReal(data: string, i: var int): float =
  skipWhite(data, i)
  var sign = 1.0
  if i < data.len and data[i] == '-':
    sign = -1.0
    i += 1
  elif i < data.len and data[i] == '+':
    i += 1
  var whole = 0.0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    whole = whole * 10.0 + float(ord(data[i]) - firstDigitValue)
    i += 1
  var fraction = 0.0
  var scale = 1.0
  if i < data.len and data[i] == '.':
    i += 1
    while i < data.len and data[i] >= '0' and data[i] <= '9':
      scale = scale * 10.0
      fraction += float(ord(data[i]) - firstDigitValue) / scale
      i += 1
  var exponent = 0
  if i < data.len and (data[i] == 'e' or data[i] == 'E'):
    i += 1
    var exponentSign = 1
    if i < data.len and data[i] == '-':
      exponentSign = -1
      i += 1
    elif i < data.len and data[i] == '+':
      i += 1
    var exponentValue = 0
    while i < data.len and data[i] >= '0' and data[i] <= '9':
      exponentValue = exponentValue * 10 + (ord(data[i]) - firstDigitValue)
      i += 1
    exponent = exponentSign * exponentValue
  var magnitude = whole + fraction
  if exponent > 0:
    var step = 0
    while step < exponent:
      magnitude *= 10.0
      step += 1
  elif exponent < 0:
    var step = 0
    while step > exponent:
      magnitude /= 10.0
      step -= 1
  result = sign * magnitude
```

`nextInt` and `nextReal` read signs, digits, fractions, and exponents in place. Each call allocates no string.

**Feasibility and binary search.**

```nim
var upperX = newSeq[float](maxBentPoints + 2)
var upperY = newSeq[float](maxBentPoints + 2)
var pointX = newSeq[float](maxBentPoints + 2)
var pointY = newSeq[float](maxBentPoints + 2)

proc feasibleAt(limitX: float, count: int): bool =
  var pointCount = 0
  for k in 0 .. count - 1:
    if upperX[k] > limitX:
      break
    pointX[pointCount] = upperX[k]
    pointY[pointCount] = upperY[k]
    pointCount += 1
  if pointCount < count and pointCount > 0:
    let i = pointCount - 1
    let j = pointCount
    let span = upperX[j] - upperX[i]
    let weight = (limitX - upperX[i]) / span
    pointX[pointCount] = limitX
    pointY[pointCount] = upperY[i] +
        weight * (upperY[j] - upperY[i])
    pointCount += 1
  var slopeLow = -1e100
  var slopeHigh = 1e100
  for i in 0 .. pointCount - 2:
    for j in i + 1 .. pointCount - 1:
      let dx = pointX[j] - pointX[i]
      if dx <= 0.0:
        continue
      let center = (pointY[j] - pointY[i]) / dx
      let halfWidth = 1.0 / dx
      let candidateLow = center - halfWidth
      let candidateHigh = center + halfWidth
      if candidateLow > slopeLow:
        slopeLow = candidateLow
      if candidateHigh < slopeHigh:
        slopeHigh = candidateHigh
      if slopeLow > slopeHigh:
        return false
  result = true

proc furthestReach(count: int): float =
  var low = upperX[0]
  var high = upperX[count - 1]
  var iteration = 0
  while iteration < searchIterations:
    let middle = (low + high) * 0.5
    if feasibleAt(middle, count):
      low = middle
    else:
      high = middle
    iteration += 1
  result = low
```

A trial cut adds one interpolated bend. Every pair narrows the slope interval. The binary search returns the last feasible x.

**Fixed-two printer.**

```nim
var outputBuffer = ""

proc appendFixedTwo(buf: var string, value: float) =
  var adjusted = value
  if adjusted < 0.0 and adjusted > -0.005:
    adjusted = 0.0
  var scaled = adjusted * 100.0
  var rounded: int64
  if scaled >= 0.0:
    rounded = int64(scaled + 0.5)
  else:
    rounded = -int64(-scaled + 0.5)
  if rounded == 0:
    buf.add "0.00\n"
    return
  var negative = false
  if rounded < 0:
    negative = true
    rounded = -rounded
  var digitStore: array[24, char]
  var digitCount = 0
  var quotient = rounded
  while quotient > 0:
    digitStore[digitCount] = char(firstDigitValue + int(quotient mod 10))
    digitCount += 1
    quotient = quotient div 10
  while digitCount < 2:
    digitStore[digitCount] = '0'
    digitCount += 1
  if negative:
    buf.add '-'
  if digitCount == 2:
    buf.add '0'
  var i = digitCount - 1
  while i >= 2:
    buf.add digitStore[i]
    i -= 1
  buf.add '.'
  buf.add digitStore[1]
  buf.add digitStore[0]
  buf.add '\n'
```

Values near zero clamp to zero. Scaling by one hundred and adding one half gives standard rounding.

**Driver and flush.**

```nim
while i < inputData.len:
  let count = nextInt(inputData, i)
  if count == 0:
    break
  for k in 0 .. count - 1:
    upperX[k] = nextReal(inputData, i)
    upperY[k] = nextReal(inputData, i)
  let answer = furthestReach(count)
  appendFixedTwo(outputBuffer, answer)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

A zero bend count ends the run. Each answer appends to one buffer that flushes in blocks.

## Complexity

Pairwise tests dominate each binary step.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total bytes) | O(Input size) |
| Feasibility | O(n^2) | O(n) |
| Binary search | O(60 * n^2) | O(n) |
| Output | O(T) | O(1) |

T is the case count and n is at most 200.

| Measure | Bound |
| --- | --- |
| Time | O(60 * n^2) per case |
| Space | O(n) |

Two hundred bends give about 2.4 million pair tests.

Sampling candidate rays would still miss the exact boundary.
