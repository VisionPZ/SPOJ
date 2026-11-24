## Problem

Read a pipe outline. The upper wall is a list of bent points with increasing x. The lower wall repeats those points one unit lower. Light leaves the segment joining the two first points. Print the greatest x that light reaches, with two digits after the decimal point. Print the last x when light passes through the pipe.

The judge bounds each case but not the case count.

| Item | Bound |
| --- | --- |
| Bent points per case | at most 200 |
| Cases | until a line contains 0 |
| Coordinates | real numbers |
| Time | 1000 ms |
| Memory | 1536 MB |

Every case must finish inside the same one-second limit.

## Idea

Treat the upper wall as a function f(x) and the lower wall as f(x) minus one. A ray of slope m fits when f(x) minus the ray height stays inside [0, 1]. That is equivalent to the spread of f(x) minus m times x staying at most one. The program searches x and tests each trial with slope intervals. One check costs O(k²) for k points, while trying every ray direction costs much more.

## Why It Works

Write the ray as y = ys + m(x - x1), where ys starts on the source segment. The ray stays inside exactly when 0 ≤ f(x) - y(x) ≤ 1 at every point up to the target.

Set c = f(x1) - ys, so c lies in [0, 1]. Set w(x) = f(x) - m x - (f(x1) - m x1). Then f(x) - y(x) equals c + w(x). A suitable c exists exactly when max w minus min w is at most one. The constant cancels, so that spread equals the spread of f(x) - m x.

On a straight wall piece the spread ends at an endpoint. Only bent points and the trial x can bind the result.

For points a and b with x_a > x_b, let dx = x_a - x_b and s = (y_a - y_b) / dx. Their values differ by at most one exactly when m lies in [s - 1/dx, s + 1/dx]. The program intersects these intervals over all pairs. Feasibility only shrinks as x grows, so binary search finds the boundary.

For the sample wall at x = 14/3, the six pairs give these slope intervals.

| pair | dx | s | allowed m |
| --- | --- | --- | --- |
| (0,1)-(2,2) | 2.00 | 0.500 | [0.000, 1.000] |
| (0,1)-(4,1) | 4.00 | 0.000 | [-0.250, 0.250] |
| (0,1)-(4.67,2) | 4.67 | 0.214 | [0.000, 0.429] |
| (2,2)-(4,1) | 2.00 | -0.500 | [-1.000, 0.000] |
| (2,2)-(4.67,2) | 2.67 | 0.000 | [-0.375, 0.375] |
| (4,1)-(4.67,2) | 0.67 | 1.500 | [0.000, 3.000] |

Their intersection is the single slope m = 0, and that horizontal ray reaches 4.67.

## Code

```
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

The loop runs until a read returns zero bytes. Doubling keeps the number of read calls small. The cost is one pass over the input bytes.

```
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
```

The pair loops run from 0 to pointCount - 2 and from i + 1 to pointCount - 1. The interpolated point lets a trial end inside a segment, not only at a bent point. Each check costs O(k²) interval intersections.

```
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

The loop runs exactly searchIterations times, so 60 halvings. It keeps the largest feasible x in low. The cost is 60 calls to feasibleAt per case.

```
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

The digit loop runs while the scaled value stays positive. It writes two fractional digits even for small values. The cost is O(digits) per case, a constant here.

```
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

The outer loop ends at the zero count, the inner loop after count point pairs. The buffer flushes only after flushBlockBytes bytes. Output cost is one write per block, not one per case.

## Complexity

Input scanning walks the buffer once, O(input bytes). Each case runs 60 feasibility checks. A check builds at most 202 points and intersects one interval per pair, O(n²). Each case therefore costs O(60 n²), and n ≤ 200 keeps that constant small. Output writes each answer into a block buffer, O(output bytes). Total time is O(input bytes + cases times n² + output bytes).

Space holds four arrays of at most 202 floats plus the input and output buffers, O(input bytes + n). A brute-force search over source points and ray slopes would test many more rays per case. That method loses the same bound and cannot meet the time limit.
